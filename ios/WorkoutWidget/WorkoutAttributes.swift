import ActivityKit
import Foundation

/// The lock-screen / Dynamic Island card of a workout (strength or run).
/// Compiled into both the app (which starts and updates it) and the widget
/// extension (which draws it). Keep the fields in step with
/// lib/live/live_activity.dart.
@available(iOS 16.2, *)
struct WorkoutAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    /// Big line: "5.24 km" / "Bench Press · set 3 of 4".
    var title: String
    /// Small line: "5:12 /km · avg 5:20" / "Next: Squat".
    var detail: String
    var heartRate: Int?
    /// The clock counts up from here (nil while paused → [elapsed] is shown).
    var clockStart: Date?
    var elapsed: Int
    /// A countdown (rest, timed set) ending at this time.
    var countdownEnd: Date?
    var countdownLabel: String?
    var paused: Bool
  }

  /// "run" or "strength".
  var kind: String
  var name: String
}
