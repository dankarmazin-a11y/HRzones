import AVFoundation
import Flutter

/// Native beep module (ported from the Phase 0 proof of concept).
/// Plays short sine-wave beeps through AVAudioEngine with the audio session
/// set to .playback + .mixWithOthers, so beeps play over music and keep
/// working with the screen locked (UIBackgroundModes: audio).
///
/// Dart side: lib/beep/beeper.dart, channel "hrzones/beeper".
final class BeeperPlugin: NSObject, FlutterPlugin {
  private let engine = AVAudioEngine()
  private let player = AVAudioPlayerNode()
  private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
  private var volume: Float = 0.7
  /// True between "start" and "stop": the app wants the audio kept alive.
  private var wanted = false

  override init() {
    super.init()
    engine.attach(player)
    engine.connect(player, to: engine.mainMixerNode, format: format)
    // iOS stops the engine on a phone call / Siri, or when the output changes
    // (AirPods connected or removed). Without restarting it, a locked phone
    // would be suspended and the beeps would go silent.
    let center = NotificationCenter.default
    center.addObserver(
      self, selector: #selector(restartIfWanted),
      name: .AVAudioEngineConfigurationChange, object: engine)
    center.addObserver(
      self, selector: #selector(handleInterruption(_:)),
      name: AVAudioSession.interruptionNotification, object: nil)
    center.addObserver(
      self, selector: #selector(restartIfWanted),
      name: AVAudioSession.mediaServicesWereResetNotification, object: nil)
  }

  @objc private func handleInterruption(_ note: Notification) {
    guard let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
      AVAudioSession.InterruptionType(rawValue: raw) == .ended
    else { return }
    restartIfWanted()
  }

  @objc private func restartIfWanted() {
    guard wanted else { return }
    DispatchQueue.main.async { [weak self] in
      guard let self, self.wanted else { return }
      try? self.start()
    }
  }

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "hrzones/beeper", binaryMessenger: registrar.messenger())
    let instance = BeeperPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any]
    do {
      switch call.method {
      case "start":
        try start()
        result(nil)
      case "stop":
        stop()
        result(nil)
      case "beep":
        let frequency = (args?["frequency"] as? NSNumber)?.doubleValue ?? 1000
        let count = (args?["count"] as? NSNumber)?.intValue ?? 1
        try beep(frequency: frequency, count: count)
        result(nil)
      case "ding":
        try play(makeDing())
        result(nil)
      case "setVolume":
        volume = Float((args?["volume"] as? NSNumber)?.doubleValue ?? 0.7)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    } catch {
      result(FlutterError(code: "audio", message: error.localizedDescription, details: nil))
    }
  }

  private func start() throws {
    wanted = true
    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.playback, options: [.mixWithOthers])
    try session.setActive(true)
    if !engine.isRunning { try engine.start() }
    if !player.isPlaying { player.play() }
  }

  private func stop() {
    wanted = false
    player.stop()
    engine.stop()
    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
  }

  private func beep(frequency: Double, count: Int) throws {
    try play(makePattern(frequency: frequency, count: count))
  }

  /// Plays [buffer] right away. A sound that is still playing is cut off, so
  /// only the newest one is heard (pressing "Test beep" five times must not
  /// queue five patterns).
  private func play(_ buffer: AVAudioPCMBuffer) throws {
    if !engine.isRunning {
      // Started only for this sound (e.g. "Test beep"): don't keep it alive.
      let keep = wanted
      try start()
      wanted = keep
    }
    player.stop()  // drops anything still scheduled
    player.scheduleBuffer(buffer, completionHandler: nil)
    player.play()
  }

  /// Bell-like "ding": a few inharmonic partials with a quick attack and a
  /// long exponential fade (~1.2 s). Clearly different from the alert beeps.
  private func makeDing() -> AVAudioPCMBuffer {
    let sr = format.sampleRate
    let total = Int(1.2 * sr)
    let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(total))!
    buffer.frameLength = AVAudioFrameCount(total)
    let data = buffer.floatChannelData![0]
    let base = 1318.5  // E6
    let partials: [(ratio: Double, gain: Double, decay: Double)] = [
      (1.0, 0.6, 3.5), (2.76, 0.25, 6.0), (5.4, 0.12, 9.0),
    ]
    let attack = 0.004 * sr
    for i in 0..<total {
      let t = Double(i) / sr
      var v = 0.0
      for p in partials {
        v += sin(2 * .pi * base * p.ratio * t) * p.gain * exp(-p.decay * t)
      }
      let env = min(1.0, Double(i) / attack)
      data[i] = Float(v * env) * volume
    }
    return buffer
  }

  private func makePattern(frequency: Double, count: Int) -> AVAudioPCMBuffer {
    let sr = format.sampleRate
    let beepLen = Int(0.15 * sr)
    let gapLen = Int(0.10 * sr)
    let unit = beepLen + gapLen
    let total = max(1, count) * unit
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
