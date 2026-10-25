package com.kluivert.reanimateddartnative

/**
 * Axis conversions for sensor readings, kept free of Android classes so
 * they can be unit tested on the JVM (src/test). Must agree with
 * ios/Classes/ReanimatedSensorMath.swift.
 */
object ReanimatedSensorMath {
    /**
     * Rotates a reading's x and y from the device's natural axes to the
     * screen's, for an interface rotated [orientation] × 90° counter-
     * clockwise (Surface.ROTATION_0..270 as 0..3).
     */
    fun adjust(x: Double, y: Double, orientation: Int): Pair<Double, Double> = when (orientation) {
        1 -> Pair(-y, x)
        2 -> Pair(-x, -y)
        3 -> Pair(y, -x)
        else -> Pair(x, y)
    }

    /** (w, x, y, z) of a 3×3 row-major rotation matrix. */
    fun quaternionFromMatrix(m: FloatArray): DoubleArray {
        val m00 = m[0].toDouble(); val m01 = m[1].toDouble(); val m02 = m[2].toDouble()
        val m10 = m[3].toDouble(); val m11 = m[4].toDouble(); val m12 = m[5].toDouble()
        val m20 = m[6].toDouble(); val m21 = m[7].toDouble(); val m22 = m[8].toDouble()
        val trace = m00 + m11 + m22
        return if (trace > 0) {
            val s = Math.sqrt(trace + 1.0) * 2
            doubleArrayOf(0.25 * s, (m21 - m12) / s, (m02 - m20) / s, (m10 - m01) / s)
        } else if (m00 > m11 && m00 > m22) {
            val s = Math.sqrt(1.0 + m00 - m11 - m22) * 2
            doubleArrayOf((m21 - m12) / s, 0.25 * s, (m01 + m10) / s, (m02 + m20) / s)
        } else if (m11 > m22) {
            val s = Math.sqrt(1.0 + m11 - m00 - m22) * 2
            doubleArrayOf((m02 - m20) / s, (m01 + m10) / s, 0.25 * s, (m12 + m21) / s)
        } else {
            val s = Math.sqrt(1.0 + m22 - m00 - m11) * 2
            doubleArrayOf((m10 - m01) / s, (m02 + m20) / s, (m12 + m21) / s, 0.25 * s)
        }
    }
}
