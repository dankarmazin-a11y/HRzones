import ActivityKit
import SwiftUI
import WidgetKit

/// Lock screen + Dynamic Island while a workout or run is going.
/// Clocks tick by themselves (Text timer styles), so the app only updates
/// the card when something changes – easy on the battery.
struct WorkoutLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: WorkoutAttributes.self) { context in
      LockScreenView(attributes: context.attributes, state: context.state, stale: context.isStale)
        .activityBackgroundTint(Color.black.opacity(0.38))  // glass: the system blurs the wallpaper behind
        .activitySystemActionForegroundColor(.white)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Label(context.attributes.name, systemImage: icon(context.attributes))
            .font(.caption).foregroundStyle(.secondary).lineLimit(1)
        }
        DynamicIslandExpandedRegion(.trailing) {
          Clock(state: context.state).font(.title3.monospacedDigit().bold())
        }
        DynamicIslandExpandedRegion(.bottom) {
          VStack(alignment: .leading, spacing: 2) {
            Text(context.state.title).font(.title3.bold()).lineLimit(1)
            if !context.state.detail.isEmpty {
              Text(context.state.detail).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            if let metrics = context.state.metrics, !metrics.isEmpty {
              HStack(spacing: 0) {
                ForEach(metrics, id: \.label) { m in
                  VStack(alignment: .leading, spacing: 0) {
                    Text(m.value).font(.headline.monospacedDigit())
                      .foregroundStyle(m.label == "Heart rate" ? heartRed : .primary)
                    Text(m.label).font(.caption2).foregroundStyle(.secondary)
                  }
                  .frame(maxWidth: .infinity, alignment: .leading)
                }
              }
            } else if let hr = context.state.heartRate {
              Label("\(hr)", systemImage: "heart.fill").font(.caption.bold()).foregroundStyle(heartRed)
            }
            if let end = context.state.countdownEnd, end > Date() {
              TimerBar(
                label: context.state.countdownLabel, start: context.state.countdownStart, end: end,
                color: accent(context.state))
            }
          }
        }
      } compactLeading: {
        Image(systemName: icon(context.attributes)).foregroundStyle(accent(context.state))
      } compactTrailing: {
        if let end = context.state.countdownEnd, end > Date() {
          Text(end, style: .timer)
            .monospacedDigit().frame(maxWidth: 48).foregroundStyle(accent(context.state))
        } else {
          Clock(state: context.state).monospacedDigit().frame(maxWidth: 52)
        }
      } minimal: {
        // With music playing iOS shows this small form: the countdown while a timer runs
        if let end = context.state.countdownEnd, end > Date() {
          Text(end, style: .timer)
            .monospacedDigit().font(.caption2.bold()).minimumScaleFactor(0.6)
            .frame(maxWidth: 40).foregroundStyle(accent(context.state))
        } else {
          Image(systemName: icon(context.attributes)).foregroundStyle(accent(context.state))
        }
      }
    }
  }
}

/// Every heart-rate heart in the app is this red (docs/DESIGN.md).
private let heartRed = Color(red: 1.0, green: 0.231, blue: 0.290)

/// The app theme's bright colour (Orange by default).
private func accent(_ s: WorkoutAttributes.ContentState) -> Color {
  guard let hex = s.accent, hex.count == 6, let v = UInt32(hex, radix: 16) else {
    return Color(red: 1.0, green: 0.478, blue: 0.176)
  }
  return Color(
    red: Double((v >> 16) & 0xFF) / 255, green: Double((v >> 8) & 0xFF) / 255, blue: Double(v & 0xFF) / 255)
}

private func icon(_ a: WorkoutAttributes) -> String {
  a.kind == "run" ? "figure.run" : "dumbbell.fill"
}

/// Elapsed time: ticking while going, frozen while paused.
private struct Clock: View {
  let state: WorkoutAttributes.ContentState

  var body: some View {
    if let start = state.clockStart, !state.paused {
      Text(start, style: .timer)
    } else {
      Text(format(state.elapsed))
    }
  }

  private func format(_ s: Int) -> String {
    let h = s / 3600, m = (s % 3600) / 60, sec = s % 60
    return h > 0 ? String(format: "%d:%02d:%02d", h, m, sec) : String(format: "%d:%02d", m, sec)
  }
}

/// "Rest ········ 1:12" over a bar that empties by itself.
private struct TimerBar: View {
  let label: String?
  let start: Date?
  let end: Date
  let color: Color

  var body: some View {
    let from = min(start ?? Date(), end.addingTimeInterval(-1))
    VStack(spacing: 4) {
      HStack {
        Text(label ?? "Rest").font(.subheadline.weight(.semibold))
        Spacer(minLength: 8)
        // A plain timer text never freezes at 0:00 (timerInterval: did when the app was
        // asleep at the end – owner 26 Nov); it counts on until iOS redraws the card.
        Text(end, style: .timer)
          .font(.title3.monospacedDigit().bold())
          .multilineTextAlignment(.trailing)
          .frame(maxWidth: 90, alignment: .trailing)
      }
      ProgressView(timerInterval: from...end, countsDown: true) {
        EmptyView()
      } currentValueLabel: {
        EmptyView()
      }
      .progressViewStyle(.linear)
      .tint(color)
    }
    .foregroundStyle(color)
  }
}

/// A thin line under the title that empties by itself during a countdown.
private struct ThinTimerBar: View {
  let start: Date?
  let end: Date
  let color: Color

  var body: some View {
    let from = min(start ?? Date(), end.addingTimeInterval(-1))
    ProgressView(timerInterval: from...end, countsDown: true) {
      EmptyView()
    } currentValueLabel: {
      EmptyView()
    }
    .progressViewStyle(.linear)
    .tint(color)
    .frame(height: 4)
  }
}

/// Big numbers: pace · avg pace · heart rate (or sets done · heart rate).
private struct Metrics: View {
  let metrics: [WorkoutMetric]
  let size: CGFloat

  var body: some View {
    HStack(alignment: .bottom, spacing: 8) {
      ForEach(metrics, id: \.label) { m in
        VStack(alignment: .leading, spacing: 0) {
          HStack(spacing: 3) {
            if m.label == "Heart rate" {
              Image(systemName: "heart.fill").font(.subheadline).foregroundStyle(heartRed)
            }
            Text(m.value)
              .font(.system(size: size, weight: .bold, design: .rounded).monospacedDigit())
              .foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.5)
          }
          Text(m.label).font(.caption2).foregroundStyle(.white.opacity(0.65)).lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
  }
}

private struct LockScreenView: View {
  let attributes: WorkoutAttributes
  let state: WorkoutAttributes.ContentState
  /// The countdown ran out (staleDate) while the app was asleep: no more
  /// "Rest 0:00" + "Skip rest" – the rest is over, so offer "Set done".
  var stale = false

  var body: some View {
    let over = stale || (state.countdownEnd.map { $0 <= Date() } ?? false)
    let actions = (state.actions ?? []).map { over && $0 == "skipRest" ? "completeSet" : $0 }
    // A countdown is shown until it is over; once iOS marks the card stale at its end, the
    // workout clock comes back.
    let countdown: Date? = over || state.paused ? nil : state.countdownEnd
    // owner (22 Nov): the lock screen gives a card at most ~160 pt – anything taller is cut off at
    // the top (the name and clock were hidden). One compact block: title + clock, detail, a
    // one-line timer, then numbers and the button.
    VStack(alignment: .leading, spacing: 5) {
      HStack(alignment: .firstTextBaseline, spacing: 8) {
        Image(systemName: icon(attributes))
          .font(.subheadline.bold())
          .foregroundStyle(state.paused ? .white.opacity(0.6) : accent(state))
        Text(state.title)
          .font(.system(size: 21, weight: .heavy, design: .rounded))
          .foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.6)
        Spacer(minLength: 6)
        if let end = countdown {
          // owner (26 Nov): the timer filled too much of the card – the countdown takes the
          // clock's place, with a thin bar under the title instead of a row of its own.
          HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(state.countdownLabel ?? "Rest").font(.caption.bold()).lineLimit(1)
            Text(end, style: .timer)
              .font(.title3.monospacedDigit().bold())
              .multilineTextAlignment(.trailing)
              .frame(maxWidth: 70, alignment: .trailing)
          }
          .foregroundStyle(accent(state))
          .frame(maxWidth: 130, alignment: .trailing)
        } else {
          Clock(state: state)
            .font(.title3.monospacedDigit().bold()).foregroundStyle(.white.opacity(0.9))
            .multilineTextAlignment(.trailing)
            .frame(maxWidth: 92, alignment: .trailing)
        }
      }
      // owner (17 Nov): the set and weight bold white – grey on dark was hard to read
      Text(state.paused ? "Paused · \(state.detail)" : (state.detail.isEmpty ? attributes.name : state.detail))
        .font(.system(size: 16, weight: .bold)).foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.7)
      if let end = countdown {
        ThinTimerBar(start: state.countdownStart, end: end, color: accent(state))
      }
      // Numbers on the left half, the button on the right half
      HStack(alignment: .center, spacing: 10) {
        if let metrics = state.metrics, !metrics.isEmpty {
          Metrics(metrics: metrics, size: actions.isEmpty ? 22 : 19)
            .frame(maxWidth: .infinity, alignment: .leading)
        } else if let hr = state.heartRate {
          Label("\(hr)", systemImage: "heart.fill").font(.headline).foregroundStyle(heartRed)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        if !actions.isEmpty {
          CardButtons(actions: actions, color: accent(state)).frame(maxWidth: .infinity)
        }
      }
    }
    // owner (17 Nov): room around the edges; less top/bottom so it fits (22 Nov)
    .padding(.horizontal, 20)
    .padding(.vertical, 12)
  }
}

/// ✓ Set / ▶ Start / Skip rest on the card (iOS 17+: buttons in a Live
/// Activity run an App Intent inside the app).
private struct CardButtons: View {
  let actions: [String]
  let color: Color

  var body: some View {
    if #available(iOS 17.0, *) {
      HStack(spacing: 10) {
        ForEach(actions, id: \.self) { a in
          Button(intent: WorkoutCardIntent(action: a)) {
            Label(title(a), systemImage: symbol(a))
              .font(.title3.bold())
              .lineLimit(1).minimumScaleFactor(0.7)
              .frame(maxWidth: .infinity, minHeight: 32)
          }
          .buttonStyle(.borderedProminent)
          .controlSize(.regular)
          .tint(color) // owner (17 Nov): every card button in the theme colour
        }
      }
    }
  }

  private func title(_ a: String) -> String {
    switch a {
    case "completeSet": return "Set done"
    case "startSet": return "Start"
    case "skipRest": return "Skip" // "Skip rest" was cut off ("Skip r…")
    default: return a
    }
  }

  private func symbol(_ a: String) -> String {
    switch a {
    case "completeSet": return "checkmark"
    case "startSet": return "play.fill"
    case "skipRest": return "forward.end.fill"
    default: return "circle"
    }
  }
}
