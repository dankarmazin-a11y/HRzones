import AppIntents
import Foundation

/// Buttons on the lock-screen card (iOS 17+). The intent runs inside the app
/// (LiveActivityIntent), which hands it to the Flutter side through
/// LiveActivityPlugin. Compiled into both the app and the widget.
let liveActionNotification = Notification.Name("hrzones.liveAction")

@available(iOS 17.0, *)
struct WorkoutCardIntent: LiveActivityIntent {
  static var title: LocalizedStringResource = "Workout card button"
  static var isDiscoverable: Bool = false

  /// "completeSet", "startSet" or "skipRest".
  @Parameter(title: "Action") var action: String

  init() { action = "" }
  init(action: String) { self.action = action }

  func perform() async throws -> some IntentResult {
    let action = self.action
    await MainActor.run {
      NotificationCenter.default.post(name: liveActionNotification, object: nil, userInfo: ["action": action])
    }
    return .result()
  }
}
