import ActivityKit
import Foundation

/// The lock-screen / Dynamic Island card of a workout (strength or run).
/// Compiled into both the app (which starts and updates it) and the widget
/// extension (which draws it). Keep the fields in step with
/// lib/live/live_activity.dart.
struct WorkoutMetric: Codable, Hashable {
  var label: String
  var value: String
}

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
    /// A countdown (rest, timed set) ending at this time; the bar runs
    /// from countdownStart.
    var countdownStart: Date?
    var countdownEnd: Date?
    var countdownLabel: String?
    var paused: Bool
    /// Big numbers under the title: pace, avg pace, heart rate / sets done.
    var metrics: [WorkoutMetric]?
    /// Buttons to show (iOS 17+): "completeSet", "startSet", "skipRest".
    var actions: [String]?
    /// The app theme's bright colour, "RRGGBB" (icon, timer bar, buttons).
    var accent: String?
  }

  /// "run" or "strength".
  var kind: String
  var name: String
}
