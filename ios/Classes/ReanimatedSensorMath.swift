// Unit and axis conversions for sensor readings, kept free of UIKit and
// CoreMotion so they can be tested on the Mac (ios/Tests/sensor_math_test.swift).

import Foundation

enum ReanimatedSensorMath {
    static let gravityMs2 = 9.81

    /// CoreMotion's acceleration and gravity are in g and point the way
    /// gravity pulls (flat, screen up: z = -1). Android reports the opposite
    /// force in m/s² (flat, screen up: z = +9.81). Converts to Android's.
    static func toAndroidAxes(_ x: Double, _ y: Double, _ z: Double) -> (Double, Double, Double) {
        (-x * gravityMs2, -y * gravityMs2, -z * gravityMs2)
    }

    /// Rotates a reading's x and y from the device's natural axes to the
    /// screen's, for an interface rotated `orientation` × 90° counter-
    /// clockwise (0..3, as Android's display rotation).
    static func adjust(_ x: Double, _ y: Double, _ orientation: Int) -> (Double, Double) {
        switch orientation {
        case 1: return (-y, x)
        case 2: return (-x, -y)
        case 3: return (y, -x)
        default: return (x, y)
        }
    }

    /// Attitude turned about the screen's normal by the interface rotation,
    /// so pitch and roll follow the screen as the vectors do.
    static func adjustAttitude(
        qw: Double, qx: Double, qy: Double, qz: Double,
        yaw: Double, pitch: Double, roll: Double,
        orientation: Int
    ) -> (qw: Double, qx: Double, qy: Double, qz: Double, yaw: Double, pitch: Double, roll: Double) {
        guard orientation != 0 else { return (qw, qx, qy, qz, yaw, pitch, roll) }
        let angle = Double(orientation) * Double.pi / 2
        // q ⊗ rotation about the device's z axis by -angle.
        let hw = cos(-angle / 2), hz = sin(-angle / 2)
        let w = qw * hw - qz * hz
        let x = qx * hw + qy * hz
        let y = qy * hw - qx * hz
        let z = qz * hw + qw * hz
        // Pitch is rotation about x and roll about y: they turn like a vector.
        let (p, r) = adjust(pitch, roll, orientation)
        var newYaw = yaw - angle
        if newYaw < -Double.pi { newYaw += 2 * Double.pi }
        return (w, x, y, z, newYaw, p, r)
    }
}
