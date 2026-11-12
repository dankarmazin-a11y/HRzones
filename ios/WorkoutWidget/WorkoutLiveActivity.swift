import ActivityKit
import SwiftUI
import WidgetKit

/// Lock screen + Dynamic Island while a workout or run is going.
/// Clocks tick by themselves (Text timer styles), so the app only updates
/// the card when something changes – easy on the battery.
struct WorkoutLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: WorkoutAttributes.self) { context in
      LockScreenView(attributes: context.attributes, state: context.state)
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
          Text(timerInterval: Date()...end, countsDown: true)
            .monospacedDigit().frame(maxWidth: 48).foregroundStyle(accent(context.state))
        } else {
          Clock(state: context.state).monospacedDigit().frame(maxWidth: 52)
        }
      } minimal: {
        Image(systemName: icon(context.attributes)).foregroundStyle(accent(context.state))
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
        Text(timerInterval: from...end, countsDown: true)
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
              Image(systemName: "heart.fill").font(.headline).foregroundStyle(heartRed)
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

  var body: some View {
    let actions = state.actions ?? []
    VStack(alignment: .leading, spacing: 6) {
      // Name ··· clock
      HStack(spacing: 8) {
        Image(systemName: icon(attributes))
          .font(.headline)
          .foregroundStyle(state.paused ? .white.opacity(0.6) : accent(state))
        Text(state.paused ? "\(attributes.name) · paused" : attributes.name)
          .font(.subheadline.weight(.semibold)).foregroundStyle(.white.opacity(0.75)).lineLimit(1)
        Spacer(minLength: 8)
        Clock(state: state)
          .font(.title2.monospacedDigit().bold()).foregroundStyle(.white)
          .multilineTextAlignment(.trailing)
          .frame(maxWidth: 110, alignment: .trailing)
      }
      // Distance / exercise, big, and the set or step under it
      VStack(alignment: .leading, spacing: 1) {
        Text(state.title)
          .font(.system(size: 30, weight: .heavy, design: .rounded))
          .foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.6)
        if !state.detail.isEmpty {
          Text(state.detail).font(.subheadline).foregroundStyle(.white.opacity(0.85)).lineLimit(1)
        }
      }
      if let end = state.countdownEnd, end > Date() {
        TimerBar(label: state.countdownLabel, start: state.countdownStart, end: end, color: accent(state))
      }
      // Numbers on the left half, the button on the right half
      HStack(alignment: .center, spacing: 12) {
        if let metrics = state.metrics, !metrics.isEmpty {
          Metrics(metrics: metrics, size: actions.isEmpty ? 26 : 22)
            .frame(maxWidth: .infinity, alignment: .leading)
        } else if let hr = state.heartRate {
          Label("\(hr)", systemImage: "heart.fill").font(.title3.bold()).foregroundStyle(heartRed)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        if !actions.isEmpty {
          CardButtons(actions: actions, color: accent(state)).frame(maxWidth: .infinity)
        }
      }
    }
    .padding(.horizontal, 18)
    .padding(.vertical, 14)
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
              .font(.headline)
              .frame(maxWidth: .infinity)
          }
          .buttonStyle(.borderedProminent)
          .tint(a == "skipRest" ? .gray : color)
        }
      }
    }
  }

  private func title(_ a: String) -> String {
    switch a {
    case "completeSet": return "Set done"
    case "startSet": return "Start"
    case "skipRest": return "Skip rest"
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
