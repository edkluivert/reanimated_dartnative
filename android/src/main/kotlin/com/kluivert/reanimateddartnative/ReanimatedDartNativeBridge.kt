package com.kluivert.reanimateddartnative

import android.content.Context
import android.database.ContentObserver
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.hardware.display.DisplayManager
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.view.Display
import android.view.Surface

/**
 * Kotlin side of reanimated_dartnative, called from reanimated_dartnative.cpp.
 *
 * Streams SensorManager readings (accelerometer, gyroscope, gravity, rotation
 * vector, magnetic field) and the "Remove animations" accessibility setting
 * to Dart through one dispatcher pointer. Sensor listeners run on the main
 * looper, so readings reach Dart on the thread its UI runs on.
 *
 * Payloads are comma-separated numbers: `x,y,z,orientation` for three-axis
 * sensors and `qw,qx,qy,qz,yaw,pitch,roll,orientation` for rotation.
 */
object ReanimatedDartNativeBridge {
    private const val TAG = "ReanimatedDartNative"

    private const val TYPE_SUCCESS = 0
    private const val RESULT_OK = 0
    private const val RESULT_UNKNOWN_CHANNEL = -1
    private const val RESULT_UNAVAILABLE = -2

    private var context: Context? = null
    private val main = Handler(Looper.getMainLooper())

    // Dispatcher slot

    @Volatile private var dispatcherPtr: Long = 0L
    @Volatile private var dispatcherGen: Long = 0L
    private var hadSession = false

    /**
     * Called once per Dart session. A second call means Dart restarted:
     * nothing listens to the old tokens, so their streams stop first.
     */
    @JvmStatic
    fun setDispatcher(ptr: Long) {
        if (hadSession) stopAll()
        hadSession = true
        dispatcherPtr = ptr
        dispatcherGen = nativeIsolateGen()
    }

    @JvmStatic external fun nativeIsolateGen(): Long
    @JvmStatic external fun nativeDeliver(ptr: Long, token: Long, type: Int, payload: ByteArray)

    /** Delivers to Dart. Must run on the main thread. */
    private fun deliver(token: Long, payload: String) {
        if (dispatcherGen != nativeIsolateGen()) return // Dart restarted
        val ptr = dispatcherPtr
        if (ptr == 0L) return
        nativeDeliver(ptr, token, TYPE_SUCCESS, payload.toByteArray(Charsets.UTF_8))
    }

    private fun deliverOnMain(token: Long, payload: String) {
        if (Looper.myLooper() == Looper.getMainLooper()) deliver(token, payload)
        else main.post { deliver(token, payload) }
    }

    // Engine lifecycle

    fun attach(applicationContext: Context) {
        context = applicationContext
    }

    fun detach() {
        stopAll()
        context = null
    }

    private fun stopAll() {
        for (sub in sensorSubscriptions.values) sub.stop()
        sensorSubscriptions.clear()
        reducedMotionObservers.values.forEach { observer ->
            context?.contentResolver?.unregisterContentObserver(observer)
        }
        reducedMotionObservers.clear()
    }

    // Calls from Dart

    @JvmStatic
    fun invoke(token: Long, methodBytes: ByteArray, argsBytes: ByteArray): Int {
        val method = String(methodBytes, Charsets.UTF_8)
        return when (method) {
            "isReducedMotionEnabled" -> {
                val enabled = isReducedMotionEnabled()
                main.post { deliver(token, if (enabled) "1" else "0") }
                RESULT_OK
            }
            else -> RESULT_UNKNOWN_CHANNEL
        }
    }

    @JvmStatic
    fun listen(token: Long, channelBytes: ByteArray, argsBytes: ByteArray): Int {
        val channel = String(channelBytes, Charsets.UTF_8)
        val args = parseArgs(String(argsBytes, Charsets.UTF_8))
        return try {
            when (channel) {
                "reducedMotion" -> listenReducedMotion(token)
                "accelerometer", "gyroscope", "gravity", "magneticField", "rotation" ->
                    listenSensor(token, channel, args)
                else -> RESULT_UNKNOWN_CHANNEL
            }
        } catch (e: Exception) {
            Log.e(TAG, "listen($channel) failed: ${e.message}")
            RESULT_UNAVAILABLE
        }
    }

    @JvmStatic
    fun cancel(token: Long): Int {
        sensorSubscriptions.remove(token)?.stop()
        reducedMotionObservers.remove(token)?.let { observer ->
            context?.contentResolver?.unregisterContentObserver(observer)
        }
        return RESULT_OK
    }

    private fun parseArgs(raw: String): Map<String, String> =
        raw.split(';').mapNotNull {
            val i = it.indexOf('=')
            if (i <= 0) null else it.substring(0, i) to it.substring(i + 1)
        }.toMap()

    // Reduced motion

    private val reducedMotionObservers = HashMap<Long, ContentObserver>()

    private fun isReducedMotionEnabled(): Boolean {
        val resolver = context?.contentResolver ?: return false
        return Settings.Global.getFloat(resolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f) == 0f
    }

    /** Sends the current setting now and again whenever it changes. */
    private fun listenReducedMotion(token: Long): Int {
        val resolver = context?.contentResolver ?: return RESULT_UNAVAILABLE
        val observer = object : ContentObserver(main) {
            override fun onChange(selfChange: Boolean) {
                deliver(token, if (isReducedMotionEnabled()) "1" else "0")
            }
        }
        resolver.registerContentObserver(
            Settings.Global.getUriFor(Settings.Global.ANIMATOR_DURATION_SCALE),
            false,
            observer,
        )
        reducedMotionObservers[token] = observer
        val enabled = isReducedMotionEnabled()
        main.post { deliver(token, if (enabled) "1" else "0") }
        return RESULT_OK
    }

    // Sensors

    private val sensorSubscriptions = HashMap<Long, SensorSubscription>()

    private fun listenSensor(token: Long, channel: String, args: Map<String, String>): Int {
        val ctx = context ?: return RESULT_UNAVAILABLE
        val manager = ctx.getSystemService(Context.SENSOR_SERVICE) as? SensorManager
            ?: return RESULT_UNAVAILABLE
        val sensorType = when (channel) {
            "accelerometer" -> Sensor.TYPE_ACCELEROMETER
            "gyroscope" -> Sensor.TYPE_GYROSCOPE
            "gravity" -> Sensor.TYPE_GRAVITY
            "magneticField" -> Sensor.TYPE_MAGNETIC_FIELD
            else -> Sensor.TYPE_ROTATION_VECTOR
        }
        val sensor = manager.getDefaultSensor(sensorType) ?: return RESULT_UNAVAILABLE
        val displayManager = ctx.getSystemService(Context.DISPLAY_SERVICE) as? DisplayManager
        val display = displayManager?.getDisplay(Display.DEFAULT_DISPLAY)

        val requestedMs = args["interval"]?.toIntOrNull() ?: -1
        val intervalMs = if (requestedMs < 0) {
            val refresh = display?.refreshRate?.takeIf { it > 0f } ?: 60f
            1000.0 / refresh
        } else {
            maxOf(requestedMs, 10).toDouble()
        }
        val subscription = SensorSubscription(
            token = token,
            manager = manager,
            sensor = sensor,
            isRotation = channel == "rotation",
            intervalNs = (intervalMs * 1_000_000).toLong(),
            adjustToInterfaceOrientation = args["adjust"] != "0",
            display = display,
        )
        sensorSubscriptions.remove(token)?.stop()
        if (!subscription.start((intervalMs * 1000).toInt())) return RESULT_UNAVAILABLE
        sensorSubscriptions[token] = subscription
        return RESULT_OK
    }

    private class SensorSubscription(
        val token: Long,
        val manager: SensorManager,
        val sensor: Sensor,
        val isRotation: Boolean,
        val intervalNs: Long,
        val adjustToInterfaceOrientation: Boolean,
        val display: Display?,
    ) : SensorEventListener {
        private var lastTimestamp = 0L
        private val matrix = FloatArray(9)
        private val remapped = FloatArray(9)
        private val orientationAngles = FloatArray(3)

        fun start(samplingPeriodUs: Int): Boolean =
            manager.registerListener(this, sensor, samplingPeriodUs, Handler(Looper.getMainLooper()))

        fun stop() = manager.unregisterListener(this)

        /** 0..3 for 0°, 90°, 180°, 270°. */
        private fun interfaceOrientation(): Int = when (display?.rotation) {
            Surface.ROTATION_90 -> 1
            Surface.ROTATION_180 -> 2
            Surface.ROTATION_270 -> 3
            else -> 0
        }

        override fun onSensorChanged(event: SensorEvent) {
            // SensorManager may report faster than asked; keep to the interval.
            if (lastTimestamp != 0L && event.timestamp - lastTimestamp < intervalNs * 9 / 10) return
            lastTimestamp = event.timestamp
            val orientation = interfaceOrientation()
            val payload = if (isRotation) rotationPayload(event.values, orientation)
            else vectorPayload(event.values, orientation)
            deliver(token, payload)
        }

        private fun vectorPayload(v: FloatArray, orientation: Int): String {
            var x = v[0].toDouble()
            var y = v[1].toDouble()
            val z = v[2].toDouble()
            if (adjustToInterfaceOrientation) {
                val (ax, ay) = ReanimatedSensorMath.adjust(x, y, orientation)
                x = ax
                y = ay
            }
            return "$x,$y,$z,$orientation"
        }

        private fun rotationPayload(v: FloatArray, orientation: Int): String {
            SensorManager.getRotationMatrixFromVector(matrix, v)
            val m = if (adjustToInterfaceOrientation && orientation != 0) {
                val (axisX, axisY) = when (orientation) {
                    1 -> SensorManager.AXIS_Y to SensorManager.AXIS_MINUS_X
                    2 -> SensorManager.AXIS_MINUS_X to SensorManager.AXIS_MINUS_Y
                    else -> SensorManager.AXIS_MINUS_Y to SensorManager.AXIS_X
                }
                SensorManager.remapCoordinateSystem(matrix, axisX, axisY, remapped)
                remapped
            } else matrix
            SensorManager.getOrientation(m, orientationAngles)
            val q = ReanimatedSensorMath.quaternionFromMatrix(m)
            val yaw = orientationAngles[0]
            val pitch = orientationAngles[1]
            val roll = orientationAngles[2]
            return "${q[0]},${q[1]},${q[2]},${q[3]},$yaw,$pitch,$roll,$orientation"
        }

        override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
    }
}
