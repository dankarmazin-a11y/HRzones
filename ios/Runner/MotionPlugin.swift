import CoreMotion
import Flutter

/// Steps and cadence (steps per minute) from the iPhone's motion chip
/// (CMPedometer) during a run. Works in the pocket or an armband, also on a
/// treadmill. No paid entitlement needed; iOS asks "Motion & Fitness" once.
///
/// Dart side: lib/run/motion_source.dart, channel "hrzones/motion".
final class MotionPlugin: NSObject, FlutterPlugin {
  private let pedometer = CMPedometer()
  /// Barometer: height change since start, much steadier than GPS height
  /// (the climb on the run summary).
  private let altimeter = CMAltimeter()
  private var relativeAltitude: Double?
  private var steps = 0
  /// Steps per second as reported by iOS (nil until it has a value).
  private var cadence: Double?

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "hrzones/motion", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(MotionPlugin(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "start":
      relativeAltitude = nil
      altimeter.stopRelativeAltitudeUpdates()
      let hasBarometer = CMAltimeter.isRelativeAltitudeAvailable()
      if hasBarometer {
        altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] data, error in
          guard let self, let data, error == nil else { return }
          self.relativeAltitude = data.relativeAltitude.doubleValue
        }
      }
      guard CMPedometer.isStepCountingAvailable() else {
        result(hasBarometer)
        return
      }
      steps = 0
      cadence = nil
      pedometer.stopUpdates()
      pedometer.startUpdates(from: Date()) { [weak self] data, error in
        guard let data, error == nil else { return }
        let count = data.numberOfSteps.intValue
        let perSecond = data.currentCadence?.doubleValue
        DispatchQueue.main.async {
          guard let self else { return }
          self.steps = count
          if let perSecond { self.cadence = perSecond }
        }
      }
      result(true)
    case "stop":
      pedometer.stopUpdates()
      altimeter.stopRelativeAltitudeUpdates()
      result(nil)
    case "read":
      var out: [String: Any] = ["steps": steps]
      if let c = cadence { out["cadence"] = c * 60 }
      if let a = relativeAltitude { out["altitude"] = a }
      result(out)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
