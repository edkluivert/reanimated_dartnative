package com.kluivert.reanimateddartnative

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.sin
import kotlin.math.sqrt

/**
 * Android reports raw SensorManager values (flat, screen up: gravity
 * z = +9.81; right edge down: x < 0), which is the convention both
 * platforms share, so only the interface-orientation remap and the
 * quaternion maths are ours to test. iOS's conversion into this convention
 * is tested in ios/Tests/main.swift.
 */
class ReanimatedSensorMathTest {
    private val eps = 1e-12

    @Test
    fun adjustRotatesDeviceAxesIntoScreenAxes() {
        // With the interface turned k × 90° counter-clockwise, a device
        // vector appears rotated by k × 90° on screen.
        for (k in 0..3) {
            val a = k * PI / 2
            for ((x, y) in listOf(1.0 to 0.0, 0.0 to 1.0, 0.3 to -0.8, -2.0 to 5.0)) {
                val (sx, sy) = ReanimatedSensorMath.adjust(x, y, k)
                assertEquals("x for ($x, $y) at $k", x * cos(a) - y * sin(a), sx, eps)
                assertEquals("y for ($x, $y) at $k", x * sin(a) + y * cos(a), sy, eps)
            }
        }
    }

    @Test
    fun screenRightEdgeDownReadsNegativeXInEveryOrientation() {
        for (k in 0..3) {
            val a = k * PI / 2
            // Screen's right edge down by 30°, expressed in the device's axes.
            val screenX = -sin(PI / 6)
            val deviceX = screenX * cos(-a)
            val deviceY = screenX * sin(-a)
            val (sx, sy) = ReanimatedSensorMath.adjust(deviceX * 9.81, deviceY * 9.81, k)
            assertTrue("orientation $k: x = $sx", sx < 0)
            assertEquals("orientation $k: y", 0.0, sy, 1e-9)
        }
    }

    @Test
    fun quaternionOfIdentityAndQuarterTurn() {
        val identity = ReanimatedSensorMath.quaternionFromMatrix(floatArrayOf(1f, 0f, 0f, 0f, 1f, 0f, 0f, 0f, 1f))
        assertEquals(1.0, identity[0], 1e-6)
        assertEquals(0.0, identity[3], 1e-6)

        // 90° about z: x → y.
        val q = ReanimatedSensorMath.quaternionFromMatrix(floatArrayOf(0f, -1f, 0f, 1f, 0f, 0f, 0f, 0f, 1f))
        assertEquals(sqrt(0.5), q[0], 1e-6)
        assertEquals(0.0, q[1], 1e-6)
        assertEquals(0.0, q[2], 1e-6)
        assertEquals(sqrt(0.5), q[3], 1e-6)
    }

    @Test
    fun quaternionRoundTripsThroughEveryBranch() {
        val axes = listOf(
            doubleArrayOf(1.0, 0.0, 0.0), doubleArrayOf(0.0, 1.0, 0.0), doubleArrayOf(0.0, 0.0, 1.0),
            doubleArrayOf(0.48, -0.6, 0.64),
        )
        for (axis in axes) {
            for (angle in listOf(0.3, 1.7, 3.0, -2.5)) {
                val h = angle / 2
                val w = cos(h); val x = axis[0] * sin(h); val y = axis[1] * sin(h); val z = axis[2] * sin(h)
                val m = floatArrayOf(
                    (1 - 2 * (y * y + z * z)).toFloat(), (2 * (x * y - z * w)).toFloat(), (2 * (x * z + y * w)).toFloat(),
                    (2 * (x * y + z * w)).toFloat(), (1 - 2 * (x * x + z * z)).toFloat(), (2 * (y * z - x * w)).toFloat(),
                    (2 * (x * z - y * w)).toFloat(), (2 * (y * z + x * w)).toFloat(), (1 - 2 * (x * x + y * y)).toFloat(),
                )
                val q = ReanimatedSensorMath.quaternionFromMatrix(m)
                // q and -q are the same rotation.
                val sign = if (q[0] * w + q[1] * x + q[2] * y + q[3] * z < 0) -1.0 else 1.0
                val expected = doubleArrayOf(w, x, y, z)
                for (i in 0..3) {
                    assertTrue("axis ${axis.toList()} angle $angle component $i", abs(sign * q[i] - expected[i]) < 1e-5)
                }
            }
        }
    }
}
