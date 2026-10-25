// Native side of reanimated_dartnative for iOS.
//
// Streams CoreMotion readings (accelerometer, gyroscope, gravity, rotation
// attitude, magnetic field) and the Reduce Motion accessibility setting to
// Dart over FFI, through the DartNative async dispatcher slot.
//
// One CMMotionManager serves every subscriber (Apple recommends a single
// instance per app): each hardware stream runs at the fastest interval any
// subscriber asked for, and each subscriber gets readings at its own
// interval. Updates arrive on the main queue, so readings reach Dart on the
// thread its UI runs on.
//
// Payloads are comma-separated numbers: `x,y,z,orientation` for three-axis
// sensors, `qw,qx,qy,qz,yaw,pitch,roll,orientation` for rotation. Axes and
// units follow Android's, so both platforms read the same: acceleration and
// gravity in m/s² with +9.81 on z when the device lies flat, screen up.

import CoreMotion
import Foundation
import UIKit

private func dnLog(_ msg: String) { print("[ReanimatedDartNative] \(msg)") }

private let resultOk: Int32 = 0
private let resultUnknownChannel: Int32 = -1
private let resultUnavailable: Int32 = -2

// MARK: - Dispatcher slot (hot-restart safe)

private let _dispatcherSlot: UnsafeMutablePointer<Int64> = {
    let p = UnsafeMutablePointer<Int64>.allocate(capacity: 1)
    p.pointee = 0
    return p
}()
private var _slotRegistered = false

private typealias Dispatch = @convention(c) (Int64, Int32, UnsafePointer<CChar>) -> Void

/// Delivers to Dart. Call on the main thread.
private func deliver(_ token: Int64, _ payload: String) {
    let addr = _dispatcherSlot.pointee
    guard addr != 0 else { return }
    payload.withCString { cStr in
        unsafeBitCast(addr, to: Dispatch.self)(token, 0, cStr)
    }
}

@_cdecl("ReanimatedSetDispatcher")
public func ReanimatedSetDispatcher(_ callbackPtr: Int64) {
    if _slotRegistered {
        // Dart restarted: nothing listens to the old tokens any more.
        ReanimatedMotion.shared.stopAll()
        ReanimatedReducedMotion.shared.stopAll()
    }
    _dispatcherSlot.pointee = callbackPtr
    if !_slotRegistered {
        _slotRegistered = true
        typealias RegFn = @convention(c) (UnsafeMutablePointer<Int64>) -> Void
        if let sym = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "DNRegisterAsyncDispatcherSlot") {
            unsafeBitCast(sym, to: RegFn.self)(_dispatcherSlot)
        } else {
            dnLog("DNRegisterAsyncDispatcherSlot not found; hot restart safety off")
        }
    }
}

// MARK: - Interface orientation

/// 0..3 for 0°, 90°, 180°, 270°, as Android's display rotation.
private func currentInterfaceOrientation() -> Int {
    let scene = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .first { $0.activationState == .foregroundActive }
        ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
    switch scene?.interfaceOrientation {
    case .landscapeLeft: return 3   // home button on the left: screen turned 270°
    case .landscapeRight: return 1  // home button on the right: screen turned 90°
    case .portraitUpsideDown: return 2
    default: return 0
    }
}

// MARK: - Motion

private enum MotionKind {
    case accelerometer, gyroscope, magnetometer, deviceMotion
}

private final class Subscriber {
    let token: Int64
    let channel: String
    let interval: TimeInterval
    let adjustToInterfaceOrientation: Bool
    let referenceFrame: String
    var lastDelivery: TimeInterval = 0

    init(token: Int64, channel: String, interval: TimeInterval, adjust: Bool, frame: String) {
        self.token = token
        self.channel = channel
        self.interval = interval
        self.adjustToInterfaceOrientation = adjust
        self.referenceFrame = frame
    }

    /// Whether a reading at [timestamp] is due for this subscriber.
    func isDue(_ timestamp: TimeInterval) -> Bool {
        if lastDelivery != 0 && timestamp - lastDelivery < interval * 0.9 { return false }
        lastDelivery = timestamp
        return true
    }
}

final class ReanimatedMotion {
    static let shared = ReanimatedMotion()
    private let motion = CMMotionManager()
    private var subscribers: [Int64: Subscriber] = [:]
    private var deviceMotionFrame: CMAttitudeReferenceFrame?

    private func kind(of channel: String) -> MotionKind? {
        switch channel {
        case "accelerometer": return .accelerometer
        case "gyroscope": return .gyroscope
        case "magneticField": return .magnetometer
        case "gravity", "rotation": return .deviceMotion
        default: return nil
        }
    }

    private func isAvailable(_ kind: MotionKind) -> Bool {
        switch kind {
        case .accelerometer: return motion.isAccelerometerAvailable
        case .gyroscope: return motion.isGyroAvailable
        case .magnetometer: return motion.isMagnetometerAvailable
        case .deviceMotion: return motion.isDeviceMotionAvailable
        }
    }

    private func subscribers(of kind: MotionKind) -> [Subscriber] {
        subscribers.values.filter { self.kind(of: $0.channel) == kind }
    }

    func start(token: Int64, channel: String, args: [String: String]) -> Int32 {
        guard let kind = kind(of: channel) else { return resultUnknownChannel }
        guard isAvailable(kind) else { return resultUnavailable }
        let requested = Int(args["interval"] ?? "") ?? -1
        let interval: TimeInterval
        if requested < 0 {
            let fps = UIScreen.main.maximumFramesPerSecond
            interval = 1.0 / Double(fps > 0 ? fps : 60)
        } else {
            interval = Double(max(requested, 10)) / 1000.0
        }
        subscribers[token] = Subscriber(
            token: token,
            channel: channel,
            interval: interval,
            adjust: args["adjust"] != "0",
            frame: args["frame"] ?? "auto"
        )
        restart(kind)
        return resultOk
    }

    func stop(token: Int64) {
        guard let sub = subscribers.removeValue(forKey: token), let kind = kind(of: sub.channel) else { return }
        restart(kind)
    }

    func stopAll() {
        subscribers.removeAll()
        motion.stopAccelerometerUpdates()
        motion.stopGyroUpdates()
        motion.stopMagnetometerUpdates()
        motion.stopDeviceMotionUpdates()
        deviceMotionFrame = nil
    }

    private func referenceFrame(_ name: String) -> CMAttitudeReferenceFrame {
        let available = CMMotionManager.availableAttitudeReferenceFrames()
        let wanted: CMAttitudeReferenceFrame
        switch name {
        case "xArbitraryZVertical": wanted = .xArbitraryZVertical
        case "xArbitraryCorrectedZVertical": wanted = .xArbitraryCorrectedZVertical
        case "xMagneticNorthZVertical": wanted = .xMagneticNorthZVertical
        case "xTrueNorthZVertical": wanted = .xTrueNorthZVertical
        default:
            wanted = motion.isMagnetometerAvailable ? .xArbitraryCorrectedZVertical : .xArbitraryZVertical
        }
        return available.contains(wanted) ? wanted : .xArbitraryZVertical
    }

    /// Starts, retunes or stops one hardware stream to suit its subscribers.
    private func restart(_ kind: MotionKind) {
        let subs = subscribers(of: kind)
        guard let fastest = subs.map({ $0.interval }).min() else {
            switch kind {
            case .accelerometer: motion.stopAccelerometerUpdates()
            case .gyroscope: motion.stopGyroUpdates()
            case .magnetometer: motion.stopMagnetometerUpdates()
            case .deviceMotion:
                motion.stopDeviceMotionUpdates()
                deviceMotionFrame = nil
            }
            return
        }
        switch kind {
        case .accelerometer:
            motion.accelerometerUpdateInterval = fastest
            if !motion.isAccelerometerActive {
                motion.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
                    guard let self, let a = data?.acceleration, let t = data?.timestamp else { return }
                    self.fanOut(.accelerometer, t) { _ in
                        ReanimatedSensorMath.toAndroidAxes(a.x, a.y, a.z)
                    }
                }
            }
        case .gyroscope:
            motion.gyroUpdateInterval = fastest
            if !motion.isGyroActive {
                motion.startGyroUpdates(to: .main) { [weak self] data, _ in
                    guard let self, let r = data?.rotationRate, let t = data?.timestamp else { return }
                    self.fanOut(.gyroscope, t) { _ in (r.x, r.y, r.z) }
                }
            }
        case .magnetometer:
            motion.magnetometerUpdateInterval = fastest
            if !motion.isMagnetometerActive {
                motion.startMagnetometerUpdates(to: .main) { [weak self] data, _ in
                    guard let self, let f = data?.magneticField, let t = data?.timestamp else { return }
                    self.fanOut(.magnetometer, t) { _ in (f.x, f.y, f.z) }
                }
            }
        case .deviceMotion:
            motion.deviceMotionUpdateInterval = fastest
            // The newest rotation subscriber picks the reference frame.
            let frameName = subs.last(where: { $0.channel == "rotation" })?.referenceFrame ?? "auto"
            let frame = referenceFrame(frameName)
            if motion.isDeviceMotionActive && deviceMotionFrame == frame { return }
            motion.stopDeviceMotionUpdates()
            deviceMotionFrame = frame
            motion.startDeviceMotionUpdates(using: frame, to: .main) { [weak self] data, _ in
                guard let self, let data else { return }
                self.deliverDeviceMotion(data)
            }
        }
    }

    private func fanOut(_ kind: MotionKind, _ timestamp: TimeInterval,
                        _ reading: (Subscriber) -> (Double, Double, Double)) {
        let orientation = currentInterfaceOrientation()
        for sub in subscribers(of: kind) where sub.isDue(timestamp) {
            let r = reading(sub)
            var (x, y) = (r.0, r.1)
            let z = r.2
            if sub.adjustToInterfaceOrientation { (x, y) = ReanimatedSensorMath.adjust(x, y, orientation) }
            deliver(sub.token, "\(x),\(y),\(z),\(orientation)")
        }
    }

    private func deliverDeviceMotion(_ data: CMDeviceMotion) {
        let orientation = currentInterfaceOrientation()
        for sub in subscribers(of: .deviceMotion) where sub.isDue(data.timestamp) {
            if sub.channel == "gravity" {
                let g = ReanimatedSensorMath.toAndroidAxes(data.gravity.x, data.gravity.y, data.gravity.z)
                var (x, y) = (g.0, g.1)
                let z = g.2
                if sub.adjustToInterfaceOrientation { (x, y) = ReanimatedSensorMath.adjust(x, y, orientation) }
                deliver(sub.token, "\(x),\(y),\(z),\(orientation)")
            } else {
                deliver(sub.token, rotationPayload(data.attitude, orientation,
                                                   adjustToInterface: sub.adjustToInterfaceOrientation))
            }
        }
    }

    /// Quaternion and Euler angles, turned about the screen's normal by the
    /// interface rotation when asked, so pitch and roll follow the screen.
    private func rotationPayload(_ attitude: CMAttitude, _ orientation: Int, adjustToInterface: Bool) -> String {
        let q = attitude.quaternion
        let a = ReanimatedSensorMath.adjustAttitude(
            qw: q.w, qx: q.x, qy: q.y, qz: q.z,
            yaw: attitude.yaw, pitch: attitude.pitch, roll: attitude.roll,
            orientation: adjustToInterface ? orientation : 0
        )
        return "\(a.qw),\(a.qx),\(a.qy),\(a.qz),\(a.yaw),\(a.pitch),\(a.roll),\(orientation)"
    }
}

// MARK: - Reduce Motion

final class ReanimatedReducedMotion {
    static let shared = ReanimatedReducedMotion()
    private var observers: [Int64: NSObjectProtocol] = [:]

    private func current() -> String { UIAccessibility.isReduceMotionEnabled ? "1" : "0" }

    func listen(token: Int64) {
        observers[token] = NotificationCenter.default.addObserver(
            forName: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            deliver(token, self.current())
        }
        DispatchQueue.main.async { deliver(token, self.current()) }
    }

    func stop(token: Int64) {
        if let observer = observers.removeValue(forKey: token) {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func stopAll() {
        for observer in observers.values { NotificationCenter.default.removeObserver(observer) }
        observers.removeAll()
    }

    func invokeCurrent(token: Int64) {
        DispatchQueue.main.async { deliver(token, self.current()) }
    }
}

// MARK: - C entry points

private func parseArgs(_ raw: String) -> [String: String] {
    var out: [String: String] = [:]
    for part in raw.split(separator: ";") {
        let kv = part.split(separator: "=", maxSplits: 1)
        if kv.count == 2 { out[String(kv[0])] = String(kv[1]) }
    }
    return out
}

/// Runs [body] on the main thread, synchronously.
private func onMain<T>(_ body: () -> T) -> T {
    if Thread.isMainThread { return body() }
    return DispatchQueue.main.sync(execute: body)
}

@_cdecl("ReanimatedInvoke")
public func ReanimatedInvoke(_ token: Int64,
                             _ method: UnsafePointer<CChar>,
                             _ argsJson: UnsafePointer<CChar>) -> Int32 {
    switch String(cString: method) {
    case "isReducedMotionEnabled":
        ReanimatedReducedMotion.shared.invokeCurrent(token: token)
        return resultOk
    default:
        return resultUnknownChannel
    }
}

@_cdecl("ReanimatedListen")
public func ReanimatedListen(_ token: Int64,
                             _ channel: UnsafePointer<CChar>,
                             _ args: UnsafePointer<CChar>) -> Int32 {
    let channelStr = String(cString: channel)
    let parsed = parseArgs(String(cString: args))
    return onMain {
        if channelStr == "reducedMotion" {
            ReanimatedReducedMotion.shared.listen(token: token)
            return resultOk
        }
        return ReanimatedMotion.shared.start(token: token, channel: channelStr, args: parsed)
    }
}

@_cdecl("ReanimatedCancel")
public func ReanimatedCancel(_ token: Int64) -> Int32 {
    onMain {
        ReanimatedMotion.shared.stop(token: token)
        ReanimatedReducedMotion.shared.stop(token: token)
    }
    return resultOk
}
