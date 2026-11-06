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
        .activityBackgroundTint(Color.black.opacity(0.85))
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
                      .foregroundStyle(m.label == "Heart rate" ? .red : .primary)
                    Text(m.label).font(.caption2).foregroundStyle(.secondary)
                  }
                  .frame(maxWidth: .infinity, alignment: .leading)
                }
              }
            } else if let hr = context.state.heartRate {
              Label("\(hr)", systemImage: "heart.fill").font(.caption.bold()).foregroundStyle(.red)
            }
            if let end = context.state.countdownEnd, end > Date() {
              Countdown(label: context.state.countdownLabel, end: end).font(.caption.bold())
            }
          }
        }
      } compactLeading: {
        Image(systemName: icon(context.attributes)).foregroundStyle(.green)
      } compactTrailing: {
        if let end = context.state.countdownEnd, end > Date() {
          Text(timerInterval: Date()...end, countsDown: true)
            .monospacedDigit().frame(maxWidth: 48).foregroundStyle(.cyan)
        } else {
          Clock(state: context.state).monospacedDigit().frame(maxWidth: 52)
        }
      } minimal: {
        Image(systemName: icon(context.attributes)).foregroundStyle(.green)
      }
    }
  }
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

private struct Countdown: View {
  let label: String?
  let end: Date

  var body: some View {
    HStack(spacing: 4) {
      Text(label ?? "Rest")
      Text(timerInterval: Date()...end, countsDown: true).monospacedDigit()
    }
    .foregroundStyle(.cyan)
  }
}

private struct LockScreenView: View {
  let attributes: WorkoutAttributes
  let state: WorkoutAttributes.ContentState

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      // Name + clock
      HStack(spacing: 8) {
        Image(systemName: icon(attributes))
          .font(.title3.bold())
          .foregroundStyle(state.paused ? .orange : .green)
        Text(state.paused ? "\(attributes.name) · paused" : attributes.name)
          .font(.subheadline.weight(.semibold)).foregroundStyle(.white.opacity(0.75)).lineLimit(1)
        Spacer(minLength: 4)
        Clock(state: state)
          .font(.title2.monospacedDigit().bold()).foregroundStyle(.white)
      }
      // Distance / exercise, big
      Text(state.title)
        .font(.system(size: 34, weight: .heavy, design: .rounded))
        .foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.6)
      if !state.detail.isEmpty {
        Text(state.detail).font(.subheadline).foregroundStyle(.white.opacity(0.85)).lineLimit(1)
      }
      if let end = state.countdownEnd, end > Date() {
        Countdown(label: state.countdownLabel, end: end).font(.title3.bold())
      }
      // Pace · avg pace · heart rate (or sets done · heart rate)
      if let metrics = state.metrics, !metrics.isEmpty {
        HStack(alignment: .bottom, spacing: 0) {
          ForEach(metrics, id: \.label) { m in
            VStack(alignment: .leading, spacing: 0) {
              HStack(spacing: 3) {
                if m.label == "Heart rate" {
                  Image(systemName: "heart.fill").font(.title3).foregroundStyle(.red)
                }
                Text(m.value)
                  .font(.system(size: 26, weight: .bold, design: .rounded).monospacedDigit())
                  .foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.6)
              }
              Text(m.label).font(.caption2).foregroundStyle(.white.opacity(0.65))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
          }
        }
      } else if let hr = state.heartRate {
        Label("\(hr)", systemImage: "heart.fill").font(.title3.bold()).foregroundStyle(.red)
      }
    }
    .padding(.horizontal, 18)
    .padding(.vertical, 14)
  }
}
