// Tests for ReanimatedSensorMath, run on the Mac without a device:
//
//   swiftc ios/Classes/ReanimatedSensorMath.swift ios/Tests/main.swift -o /tmp/sensor_math_test
//   /tmp/sensor_math_test
//
// Poses are built from first principles: a device starts flat, screen up,
// with x to its right edge, y to its top edge and z out of the screen; then
// it is rolled (right edge down) and pitched (top edge up).

import Foundation

var failures = 0
func check(_ ok: Bool, _ message: String) {
    if !ok {
        failures += 1
        print("FAIL: \(message)")
    }
}
func close(_ a: Double, _ b: Double) -> Bool { abs(a - b) < 1e-9 }

/// The world's up direction in device coordinates, for a device rolled by
/// `roll` (right edge down) then pitched by `pitch` (top edge up), radians.
func upInDevice(roll: Double, pitch: Double) -> (Double, Double, Double) {
    // Roll about the device's y axis: the right edge (x) goes down.
    let x = (cos(roll), 0.0, -sin(roll))
    let y0 = (0.0, 1.0, 0.0)
    let z0 = (sin(roll), 0.0, cos(roll))
    // Then pitch about its x axis: the top edge (y) comes up.
    let y = (cos(pitch) * y0.0 + sin(pitch) * z0.0, cos(pitch) * y0.1 + sin(pitch) * z0.1, cos(pitch) * y0.2 + sin(pitch) * z0.2)
    let z = (-sin(pitch) * y0.0 + cos(pitch) * z0.0, -sin(pitch) * y0.1 + cos(pitch) * z0.1, -sin(pitch) * y0.2 + cos(pitch) * z0.2)
    // up = (0, 0, 1) in the world, so its device components are the axes' z.
    return (x.2, y.2, z.2)
}

let poses: [(String, Double, Double)] = [
    ("flat, screen up", 0, 0),
    ("right edge down 30°", .pi / 6, 0),
    ("left edge down 30°", -.pi / 6, 0),
    ("upright (top edge up 90°)", 0, .pi / 2),
    ("tilted back 45°", 0, .pi / 4),
    ("right edge down, tilted back", .pi / 5, .pi / 3),
]

// 1. CoreMotion gravity converts to exactly what Android reports.
for (name, roll, pitch) in poses {
    let up = upInDevice(roll: roll, pitch: pitch)
    // Android's gravity sensor reports the force holding the device up, in m/s².
    let android = (up.0 * 9.81, up.1 * 9.81, up.2 * 9.81)
    // CoreMotion's gravity points down, in g.
    let coreMotion = (-up.0, -up.1, -up.2)
    let converted = ReanimatedSensorMath.toAndroidAxes(coreMotion.0, coreMotion.1, coreMotion.2)
    check(close(converted.0, android.0) && close(converted.1, android.1) && close(converted.2, android.2),
          "\(name): iOS \(converted) != Android \(android)")
}

// 2. The physical meaning of each axis.
do {
    let flat = ReanimatedSensorMath.toAndroidAxes(0, 0, -1)
    check(close(flat.2, 9.81), "flat, screen up reads z = +9.81 (got \(flat.2))")
    let up = upInDevice(roll: .pi / 6, pitch: 0)
    let right = ReanimatedSensorMath.toAndroidAxes(-up.0, -up.1, -up.2)
    check(right.0 < 0, "right edge down reads x < 0 (got \(right.0))")
    let upright = upInDevice(roll: 0, pitch: .pi / 2)
    let u = ReanimatedSensorMath.toAndroidAxes(-upright.0, -upright.1, -upright.2)
    check(close(u.1, 9.81), "upright reads y = +9.81 (got \(u.1))")
}

// 3. Orientation adjustment equals rotating the device's axes into the
// screen's: with the interface turned k × 90° counter-clockwise, a device
// vector appears rotated by k × 90° on screen.
for k in 0..<4 {
    let angle = Double(k) * .pi / 2
    for (x, y) in [(1.0, 0.0), (0.0, 1.0), (0.3, -0.8), (-2.0, 5.0)] {
        let expected = (x * cos(angle) - y * sin(angle), x * sin(angle) + y * cos(angle))
        let got = ReanimatedSensorMath.adjust(x, y, k)
        check(abs(got.0 - expected.0) < 1e-12 && abs(got.1 - expected.1) < 1e-12,
              "adjust(\(x), \(y), \(k)) = \(got), expected \(expected)")
    }
}

// 4. A landscape device tipped toward the screen's right edge reads x < 0 on
// screen, the same as portrait: the box slides right either way.
for k in 0..<4 {
    let angle = Double(k) * .pi / 2
    // "Screen's right edge down by 30°" in screen coordinates…
    let screen = (-sin(Double.pi / 6), 0.0)
    // …is this in the device's own axes (undo the interface rotation).
    let device = (screen.0 * cos(-angle) - screen.1 * sin(-angle), screen.0 * sin(-angle) + screen.1 * cos(-angle))
    let adjusted = ReanimatedSensorMath.adjust(device.0, device.1, k)
    check(adjusted.0 < 0 && abs(adjusted.1) < 1e-12,
          "orientation \(k): screen-right-down should read x < 0 on screen, got \(adjusted)")
}

// 5. Attitude adjustment keeps a unit quaternion and is a no-op at 0°.
do {
    let same = ReanimatedSensorMath.adjustAttitude(qw: 0.9, qx: 0.1, qy: 0.3, qz: 0.2, yaw: 0.5, pitch: 0.2, roll: -0.1, orientation: 0)
    check(close(same.qw, 0.9) && close(same.pitch, 0.2), "orientation 0 leaves attitude unchanged")
    let n = sqrt(0.9 * 0.9 + 0.1 * 0.1 + 0.3 * 0.3 + 0.2 * 0.2)
    for k in 1..<4 {
        let a = ReanimatedSensorMath.adjustAttitude(qw: 0.9 / n, qx: 0.1 / n, qy: 0.3 / n, qz: 0.2 / n, yaw: 0.5, pitch: 0.2, roll: -0.1, orientation: k)
        let len = sqrt(a.qw * a.qw + a.qx * a.qx + a.qy * a.qy + a.qz * a.qz)
        check(abs(len - 1) < 1e-12, "orientation \(k): quaternion stays unit length (\(len))")
        check(a.yaw >= -Double.pi && a.yaw <= Double.pi, "orientation \(k): yaw stays in [-π, π] (\(a.yaw))")
    }
}

if failures == 0 {
    print("All sensor math tests passed.")
} else {
    print("\(failures) failure(s).")
    exit(1)
}
