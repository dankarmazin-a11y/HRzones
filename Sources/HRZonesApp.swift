// HR Zones – Phase 0 proof of concept
// Live heart rate from AirPods Pro 3 (via an iPhone HealthKit workout session)
// with audible beeps when you leave your target range.

import SwiftUI
import HealthKit
import AVFoundation

// MARK: - App

@main
struct HRZonesApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
    }
}

// MARK: - Beeper (plays tones over music, keeps running in background)

final class Beeper {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    var volume: Float = 0.7

    init() {
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
    }

    func start() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, options: [.mixWithOthers])
        try session.setActive(true)
        if !engine.isRunning { try engine.start() }
        if !player.isPlaying { player.play() }
    }

    func stop() {
        player.stop()
        engine.stop()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func beep(frequency: Double, count: Int) {
        if !engine.isRunning { try? start() }
        player.scheduleBuffer(makePattern(frequency: frequency, count: count), completionHandler: nil)
        if !player.isPlaying { player.play() }
    }

    private func makePattern(frequency: Double, count: Int) -> AVAudioPCMBuffer {
        let sr = format.sampleRate
        let beepLen = Int(0.15 * sr)
        let gapLen = Int(0.10 * sr)
        let unit = beepLen + gapLen
        let total = count * unit
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(total))!
        buffer.frameLength = AVAudioFrameCount(total)
        let data = buffer.floatChannelData![0]
        let fade = 220.0
        for i in 0..<total {
            let pos = i % unit
            if pos < beepLen {
                let env = min(1.0, Double(min(pos, beepLen - pos)) / fade)
                data[i] = Float(sin(2 * .pi * frequency * Double(i) / sr) * env) * volume
            } else {
                data[i] = 0
            }
        }
        return buffer
    }
}

// MARK: - WorkoutManager

@MainActor
final class WorkoutManager: NSObject, ObservableObject {
    private let store = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private let beeper = Beeper()

    private var outOfRangeSince: Date?
    private var lastAlert = Date.distantPast

    @Published var heartRate: Double?
    @Published var lastSampleAt: Date?
    @Published var running = false
    @Published var startedAt: Date?
    @Published var samples = 0
    @Published var log: [String] = []

    var low: Double = 110
    var high: Double = 150
    var cooldown: TimeInterval = 10
    var graceSeconds: TimeInterval = 5

    private func note(_ text: String) {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        log.insert("\(f.string(from: Date()))  \(text)", at: 0)
        if log.count > 60 { log.removeLast() }
    }

    func start(activity: HKWorkoutActivityType) async {
        guard HKHealthStore.isHealthDataAvailable() else {
            note("HealthKit is not available on this device")
            return
        }
        do {
            let hr = HKQuantityType(.heartRate)
            let share: Set<HKSampleType> = [HKObjectType.workoutType(), hr, HKQuantityType(.activeEnergyBurned)]
            let read: Set<HKObjectType> = [HKObjectType.workoutType(), hr]
            try await store.requestAuthorization(toShare: share, read: read)
            note("Health permission requested OK")

            let config = HKWorkoutConfiguration()
            config.activityType = activity
            config.locationType = .unknown

            let session = try HKWorkoutSession(healthStore: store, configuration: config)
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: store, workoutConfiguration: config)
            session.delegate = self
            builder.delegate = self
            self.session = session
            self.builder = builder

            try beeper.start()
            let now = Date()
            session.startActivity(with: now)
            try await builder.beginCollection(at: now)

            running = true
            startedAt = now
            samples = 0
            outOfRangeSince = nil
            lastAlert = .distantPast
            note("Workout started – waiting for heart rate…")
        } catch {
            note("ERROR starting: \(error.localizedDescription)")
        }
    }

    func stop(save: Bool) async {
        guard let session, let builder else { return }
        session.end()
        do {
            try await builder.endCollection(at: Date())
            if save {
                _ = try await builder.finishWorkout()
                note("Workout saved to Apple Health")
            } else {
                builder.discardWorkout()
                note("Workout discarded")
            }
        } catch {
            note("ERROR stopping: \(error.localizedDescription)")
        }
        beeper.stop()
        running = false
        heartRate = nil
        startedAt = nil
        self.session = nil
        self.builder = nil
    }

    func testBeep(high: Bool) {
        if high { beeper.beep(frequency: 1200, count: 3) } else { beeper.beep(frequency: 500, count: 2) }
    }

    fileprivate func handle(bpm: Double, source: String) {
        if samples == 0 { note("First heart rate received (\(Int(bpm)) bpm, source: \(source))") }
        samples += 1
        heartRate = bpm
        lastSampleAt = Date()

        let now = Date()
        let outside = bpm > high || bpm < low
        guard outside else { outOfRangeSince = nil; return }
        if outOfRangeSince == nil { outOfRangeSince = now }
        guard let since = outOfRangeSince, now.timeIntervalSince(since) >= graceSeconds,
              now.timeIntervalSince(lastAlert) >= cooldown else { return }
        if bpm > high {
            beeper.beep(frequency: 1200, count: 3)
            note("HIGH alert at \(Int(bpm)) bpm")
        } else {
            beeper.beep(frequency: 500, count: 2)
            note("LOW alert at \(Int(bpm)) bpm")
        }
        lastAlert = now
    }

    fileprivate func sessionFailed(_ text: String) {
        note("Session error: \(text)")
    }

    fileprivate func stateChanged(_ text: String) {
        note("Session state: \(text)")
    }
}

extension WorkoutManager: HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession,
                                    didChangeTo toState: HKWorkoutSessionState,
                                    from fromState: HKWorkoutSessionState,
                                    date: Date) {
        let name: String
        switch toState {
        case .running: name = "running"
        case .paused: name = "paused"
        case .ended: name = "ended"
        case .prepared: name = "prepared"
        case .stopped: name = "stopped"
        default: name = "notStarted"
        }
        Task { @MainActor in self.stateChanged(name) }
    }

    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        let text = error.localizedDescription
        Task { @MainActor in self.sessionFailed(text) }
    }

    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    nonisolated func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder,
                                    didCollectDataOf collectedTypes: Set<HKSampleType>) {
        let hrType = HKQuantityType(.heartRate)
        guard collectedTypes.contains(hrType),
              let quantity = workoutBuilder.statistics(for: hrType)?.mostRecentQuantity() else { return }
        let bpm = quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
        let source = workoutBuilder.statistics(for: hrType)?.sources?.first?.name ?? "unknown"
        Task { @MainActor in self.handle(bpm: bpm, source: source) }
    }
}

// MARK: - UI

struct ContentView: View {
    @StateObject private var wm = WorkoutManager()
    @AppStorage("low") private var low = 110.0
    @AppStorage("high") private var high = 150.0
    @AppStorage("cooldown") private var cooldown = 10.0
    @State private var activity: HKWorkoutActivityType = .running

    private var bpmColor: Color {
        guard let hr = wm.heartRate else { return .secondary }
        if hr > high { return .red }
        if hr < low { return .blue }
        return .green
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 4) {
                        Text(wm.heartRate.map { "\(Int($0.rounded()))" } ?? "--")
                            .font(.system(size: 96, weight: .bold, design: .rounded))
                            .foregroundStyle(bpmColor)
                            .contentTransition(.numericText())
                        Text("BPM").foregroundStyle(.secondary)
                        Text("Target: \(Int(low))–\(Int(high))").font(.headline)
                        if wm.running, let start = wm.startedAt {
                            Text(timerInterval: start...Date.distantFuture, countsDown: false)
                                .font(.title3.monospacedDigit())
                        }
                        if let last = wm.lastSampleAt {
                            Text("Last reading \(last, style: .relative) ago · \(wm.samples) readings")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }

                Section("Heart-rate range") {
                    Stepper("Min: \(Int(low))", value: $low, in: 40...(high - 5))
                    Stepper("Max: \(Int(high))", value: $high, in: (low + 5)...220)
                    Stepper("Alert every: \(Int(cooldown)) s", value: $cooldown, in: 3...60)
                }

                Section("Workout type") {
                    Picker("Activity", selection: $activity) {
                        Text("Running").tag(HKWorkoutActivityType.running)
                        Text("Walking").tag(HKWorkoutActivityType.walking)
                        Text("Cycling").tag(HKWorkoutActivityType.cycling)
                        Text("Strength").tag(HKWorkoutActivityType.traditionalStrengthTraining)
                        Text("HIIT").tag(HKWorkoutActivityType.highIntensityIntervalTraining)
                        Text("Other").tag(HKWorkoutActivityType.other)
                    }
                    .disabled(wm.running)
                }

                Section {
                    if wm.running {
                        Button("Finish & save") { Task { await wm.stop(save: true) } }
                        Button("Discard workout", role: .destructive) { Task { await wm.stop(save: false) } }
                    } else {
                        Button("Start workout") {
                            syncLimits()
                            Task { await wm.start(activity: activity) }
                        }
                        .font(.headline)
                    }
                    HStack {
                        Button("Test HIGH beep") { wm.testBeep(high: true) }
                        Spacer()
                        Button("Test LOW beep") { wm.testBeep(high: false) }
                    }
                    .buttonStyle(.borderless)
                }

                Section("Diagnostics log") {
                    if wm.log.isEmpty {
                        Text("Nothing yet").foregroundStyle(.secondary)
                    }
                    ForEach(Array(wm.log.enumerated()), id: \.offset) { _, line in
                        Text(line).font(.caption.monospaced())
                    }
                }
            }
            .navigationTitle("HR Zones")
            .onAppear(perform: syncLimits)
            .onChange(of: low) { syncLimits() }
            .onChange(of: high) { syncLimits() }
            .onChange(of: cooldown) { syncLimits() }
        }
    }

    private func syncLimits() {
        wm.low = low
        wm.high = high
        wm.cooldown = cooldown
    }
}
