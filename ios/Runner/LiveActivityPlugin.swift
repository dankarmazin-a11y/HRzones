import ActivityKit
import Flutter
import Foundation
import UIKit

/// Starts, updates and ends the workout card on the lock screen and in the
/// Dynamic Island (Live Activity). Dart side: lib/live/live_activity.dart,
/// channel "hrzones/live". Does nothing before iOS 16.2 or when the user
/// turned Live Activities off for the app.
final class LiveActivityPlugin: NSObject, FlutterPlugin {
  private var channel: FlutterMethodChannel?

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "hrzones/live", binaryMessenger: registrar.messenger())
    let instance = LiveActivityPlugin()
    instance.channel = channel
    registrar.addMethodCallDelegate(instance, channel: channel)
    // A button on the lock-screen card was tapped → tell the Dart side.
    NotificationCenter.default.addObserver(
      instance, selector: #selector(onCardAction(_:)), name: liveActionNotification, object: nil)
  }

  @objc private func onCardAction(_ note: Notification) {
    guard let action = note.userInfo?["action"] as? String else { return }
    DispatchQueue.main.async { [weak self] in
      self?.channel?.invokeMethod("action", arguments: action)
    }
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
      countdownStart: date("countdownStart"),
      countdownEnd: date("countdownEnd"),
      countdownLabel: m["countdownLabel"] as? String,
      paused: m["paused"] as? Bool ?? false,
      metrics: (m["metrics"] as? [[String: Any]])?.map {
        WorkoutMetric(label: $0["label"] as? String ?? "", value: $0["value"] as? String ?? "")
      },
      actions: m["actions"] as? [String],
      accent: m["accent"] as? String)
  }
}

@available(iOS 16.2, *)
private enum LiveActivities {
  static var current: Activity<WorkoutAttributes>?

  /// A card iOS refused because the app wasn't on screen (cards can only be
  /// started from the foreground – owner locked the phone during the 3-2-1
  /// before a run). Tried again as soon as the app is opened.
  static var pending: (kind: String, name: String, state: WorkoutAttributes.ContentState)?
  static var observer: NSObjectProtocol?

  static func start(kind: String, name: String, state: WorkoutAttributes.ContentState) async {
    await keepAwake {
      // The same card is already up (the run countdown starts it, the run
      // itself only fills it in): just update it – no end + new request,
      // which fails when the phone is locked by then.
      if let a = Activity<WorkoutAttributes>.activities.first(where: {
        $0.attributes.kind == kind && $0.attributes.name == name && $0.activityState != .ended && $0.activityState != .dismissed
      }) {
        current = a
        pending = nil
        for other in Activity<WorkoutAttributes>.activities where other.id != a.id {
          await other.end(nil, dismissalPolicy: .immediate)
        }
        await a.update(ActivityContent(state: state, staleDate: state.countdownEnd))
        return
      }
      // Only one card at a time (also cleans up after the app was closed).
      await endAll()
      guard ActivityAuthorizationInfo().areActivitiesEnabled else {
        LiveActivityPlugin.lastError = "Live Activities are off for HR Zones (iPhone Settings › HR Zones)."
        return
      }
      do {
        current = try Activity.request(
          attributes: WorkoutAttributes(kind: kind, name: name),
          content: ActivityContent(state: state, staleDate: state.countdownEnd),
          pushType: nil)
        LiveActivityPlugin.lastError = nil
        pending = nil
      } catch {
        let inBackground = await MainActor.run { UIApplication.shared.applicationState != .active }
        LiveActivityPlugin.lastError =
          inBackground ? "The app was not on screen when the card was started (\(error))." : "\(error)"
        NSLog("Live Activity not started: \(error)")
        if inBackground { waitForForeground(kind: kind, name: name, state: state) }
      }
    }
  }

  private static func waitForForeground(kind: String, name: String, state: WorkoutAttributes.ContentState) {
    pending = (kind, name, state)
    guard observer == nil else { return }
    observer = NotificationCenter.default.addObserver(
      forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main
    ) { _ in
      guard let p = LiveActivities.pending else { return }
      LiveActivities.pending = nil
      Task { await LiveActivities.start(kind: p.kind, name: p.name, state: p.state) }
    }
  }

  static func update(_ state: WorkoutAttributes.ContentState) async {
    if let p = pending {
      // Still waiting to be shown: show the newest numbers when it is.
      pending = (p.kind, p.name, state)
      return
    }
    await keepAwake {
      guard let a = current ?? Activity<WorkoutAttributes>.activities.first else { return }
      current = a
      // The countdown's end is the stale date: iOS redraws the card then by itself even when
      // the app is asleep (the countdown makes way for the clock).
      await a.update(ActivityContent(state: state, staleDate: state.countdownEnd))
    }
  }

  static func endAll() async {
    pending = nil
    for a in Activity<WorkoutAttributes>.activities {
      await a.end(nil, dismissalPolicy: .immediate)
    }
    current = nil
  }

  /// Asks iOS for a few seconds more so a card change sent just as the
  /// phone locks (end of a rest) isn't lost when the app is put to sleep.
  private static func keepAwake(_ work: () async -> Void) async {
    let id = await MainActor.run { UIApplication.shared.beginBackgroundTask(withName: "live-card") }
    await work()
    if id != .invalid {
      await MainActor.run { UIApplication.shared.endBackgroundTask(id) }
    }
  }
}
