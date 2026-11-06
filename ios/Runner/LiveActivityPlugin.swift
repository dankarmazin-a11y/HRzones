import ActivityKit
import Flutter
import Foundation
import UIKit

/// Starts, updates and ends the workout card on the lock screen and in the
/// Dynamic Island (Live Activity). Dart side: lib/live/live_activity.dart,
/// channel "hrzones/live". Does nothing before iOS 16.2 or when the user
/// turned Live Activities off for the app.
final class LiveActivityPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "hrzones/live", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(LiveActivityPlugin(), channel: channel)
  }

  /// Why the last card didn't show (for Settings › Lock screen).
  static var lastError: String?

  /// What Settings shows when the card doesn't appear: iOS version, whether
  /// the widget part was installed with the app, whether Live Activities
  /// are allowed, the last error.
  private func status() -> [String: Any] {
    var m: [String: Any] = ["ios": UIDevice.current.systemVersion]
    m["bundleId"] = Bundle.main.bundleIdentifier ?? ""
    let appex = Bundle.main.builtInPlugInsURL?.appendingPathComponent("WorkoutWidget.appex")
    let installed = appex.map { FileManager.default.fileExists(atPath: $0.path) } ?? false
    m["extension"] = installed
    if installed, let u = appex, let b = Bundle(url: u) { m["extensionId"] = b.bundleIdentifier ?? "" }
    if #available(iOS 16.2, *) {
      m["supported"] = true
      m["enabled"] = ActivityAuthorizationInfo().areActivitiesEnabled
      m["running"] = Activity<WorkoutAttributes>.activities.count
    } else {
      m["supported"] = false
      m["enabled"] = false
    }
    if let e = Self.lastError { m["lastError"] = e }
    return m
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "status" {
      result(status())
      return
    }
    guard #available(iOS 16.2, *) else {
      result(false)
      return
    }
    let args = call.arguments as? [String: Any] ?? [:]
    switch call.method {
    case "available":
      result(ActivityAuthorizationInfo().areActivitiesEnabled)
    case "start":
      Task {
        await LiveActivities.start(
          kind: args["kind"] as? String ?? "strength",
          name: args["name"] as? String ?? "Workout",
          state: Self.state(args["state"] as? [String: Any] ?? [:]))
        result(nil)
      }
    case "update":
      Task {
        await LiveActivities.update(Self.state(args["state"] as? [String: Any] ?? [:]))
        result(nil)
      }
    case "end":
      Task {
        await LiveActivities.endAll()
        result(nil)
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  @available(iOS 16.2, *)
  private static func state(_ m: [String: Any]) -> WorkoutAttributes.ContentState {
    func date(_ key: String) -> Date? {
      guard let ms = (m[key] as? NSNumber)?.doubleValue else { return nil }
      return Date(timeIntervalSince1970: ms / 1000)
    }
    return WorkoutAttributes.ContentState(
      title: m["title"] as? String ?? "",
      detail: m["detail"] as? String ?? "",
      heartRate: (m["heartRate"] as? NSNumber)?.intValue,
      clockStart: date("clockStart"),
      elapsed: (m["elapsed"] as? NSNumber)?.intValue ?? 0,
      countdownEnd: date("countdownEnd"),
      countdownLabel: m["countdownLabel"] as? String,
      paused: m["paused"] as? Bool ?? false,
      metrics: (m["metrics"] as? [[String: Any]])?.map {
        WorkoutMetric(label: $0["label"] as? String ?? "", value: $0["value"] as? String ?? "")
      })
  }
}

@available(iOS 16.2, *)
private enum LiveActivities {
  static var current: Activity<WorkoutAttributes>?

  static func start(kind: String, name: String, state: WorkoutAttributes.ContentState) async {
    // Only one card at a time (also cleans up after the app was closed).
    await endAll()
    guard ActivityAuthorizationInfo().areActivitiesEnabled else {
      LiveActivityPlugin.lastError = "Live Activities are off for HR Zones (iPhone Settings › HR Zones)."
      return
    }
    do {
      current = try Activity.request(
        attributes: WorkoutAttributes(kind: kind, name: name),
        content: ActivityContent(state: state, staleDate: nil),
        pushType: nil)
      LiveActivityPlugin.lastError = nil
    } catch {
      LiveActivityPlugin.lastError = "\(error)"
      NSLog("Live Activity not started: \(error)")
    }
  }

  static func update(_ state: WorkoutAttributes.ContentState) async {
    guard let a = current ?? Activity<WorkoutAttributes>.activities.first else { return }
    current = a
    await a.update(ActivityContent(state: state, staleDate: nil))
  }

  static func endAll() async {
    for a in Activity<WorkoutAttributes>.activities {
      await a.end(nil, dismissalPolicy: .immediate)
    }
    current = nil
  }
}
