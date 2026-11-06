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
  /// Bumped by every start, so a delayed stop knows it is outdated. (A
  /// single sound doesn't bump it: the delay is long enough for any sound,
  /// and the engine must not stay on forever.)
  private var generation = 0
  /// Voice updates during runs ("1 kilometre, 5 minutes 30…").
  private let speech = AVSpeechSynthesizer()
  /// Between speak() and the end of the last sentence: the session must keep
  /// ducking the music and must not be switched off (that cuts the voice).
  private var talking = false

  override init() {
    super.init()
    // Before anything touches audio: "play along with other apps". With the
    // default category, the first sound session stopped the user's music
    // (Spotify) on the first launch. The session is only *activated* when a
    // sound actually needs to play (start()).
    try? AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
    engine.attach(player)
    engine.connect(player, to: engine.mainMixerNode, format: format)
    speech.delegate = self
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
        let afterMs = (args?["afterMs"] as? NSNumber)?.intValue ?? 0
        if afterMs > 0 {
          // Let the last sound finish; cancelled if anything starts again.
          let g = generation
          DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(afterMs)) { [weak self] in
            guard let self, self.generation == g else { return }
            self.stop()
          }
        } else {
          stop()
        }
        result(nil)
      case "beep":
        let frequency = (args?["frequency"] as? NSNumber)?.doubleValue ?? 1000
        let count = (args?["count"] as? NSNumber)?.intValue ?? 1
        try beep(frequency: frequency, count: count)
        result(nil)
      case "ding":
        try play(makeDing())
        result(nil)
      case "sound":
        let name = args?["name"] as? String ?? "ding"
        let count = max(1, (args?["count"] as? NSNumber)?.intValue ?? 1)
        try play(repeated(makeSound(name), count: count))
        result(nil)
      case "speak":
        try speak(args?["text"] as? String ?? "", voice: args?["voice"] as? String ?? "default")
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
    generation += 1
    wanted = true
    try applyCategory()
    try AVAudioSession.sharedInstance().setActive(true)
    if !engine.isRunning { try engine.start() }
    if !player.isPlaying { player.play() }
  }

  private func stop() {
    wanted = false
    player.stop()
    engine.stop()
    // Still talking ("Run complete…"): unduck() switches the session off
    // when the sentence is over.
    if talking { return }
    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
  }

  /// Music plays on underneath; while a sentence is spoken it is turned
  /// down. (A beeper restart in the middle of a sentence – AirPods, a call –
  /// must not undo the ducking.)
  private func applyCategory() throws {
    let session = AVAudioSession.sharedInstance()
    if talking {
      try session.setCategory(.playback, mode: .voicePrompt, options: [.mixWithOthers, .duckOthers])
    } else {
      try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
    }
  }

  /// Speaks [text] over the user's music, which is turned down (ducked)
  /// while talking and back up afterwards. Works with the screen locked.
  /// An English voice: "female" / "male" picks one of that gender (best
  /// quality installed), "default" the system's en-US voice.
  private func englishVoice(_ kind: String) -> AVSpeechSynthesisVoice? {
    let fallback = AVSpeechSynthesisVoice(language: "en-US")
    guard kind == "female" || kind == "male" else { return fallback }
    let wanted: AVSpeechSynthesisVoiceGender = kind == "female" ? .female : .male
    let voices = AVSpeechSynthesisVoice.speechVoices()
      .filter { $0.language.hasPrefix("en") && $0.gender == wanted }
      .sorted { a, b in
        // US English first, then the better quality.
        let au = a.language == "en-US" ? 1 : 0, bu = b.language == "en-US" ? 1 : 0
        if au != bu { return au > bu }
        return a.quality.rawValue > b.quality.rawValue
      }
    return voices.first ?? fallback
  }

  private func speak(_ text: String, voice: String) throws {
    guard !text.isEmpty else { return }
    talking = true
    do {
      try applyCategory()
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {
      talking = false
      throw error
    }
    let utterance = AVSpeechUtterance(string: text)
    utterance.voice = englishVoice(voice)
    utterance.volume = 1.0
    speech.speak(utterance)
  }

  /// After speaking: other apps' music only comes back to full volume when
  /// our session is deactivated; then the beeper is started again if needed.
  private func unduck() {
    guard !speech.isSpeaking else { return }
    talking = false
    player.stop()
    engine.stop()
    let session = AVAudioSession.sharedInstance()
    try? session.setActive(false, options: .notifyOthersOnDeactivation)
    try? applyCategory()
    if wanted { try? start() }
  }

  private func beep(frequency: Double, count: Int) throws {
    try play(makePattern(frequency: frequency, count: count))
  }

  /// Plays [buffer] right away. A sound that is still playing is cut off, so
  /// only the newest one is heard (pressing "Test beep" five times must not
  /// queue five patterns).
  private func play(_ buffer: AVAudioPCMBuffer) throws {
    if !engine.isRunning {
      // Started only for this sound (e.g. "Test beep", a planned-run step):
      // don't keep it alive.
      let keep = wanted
      try start()
      wanted = keep
    }
    player.stop()  // drops anything still scheduled
    player.scheduleBuffer(buffer, completionHandler: nil)
    player.play()
    if !wanted {
      // Nobody holds the audio: switch it off once the sound is over (an
      // idle running engine costs battery). A newer sound or start() wins.
      generation += 1
      let g = generation
      DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(4)) { [weak self] in
        guard let self, self.generation == g, !self.wanted else { return }
        self.stop()
      }
    }
  }

  /// The sounds the user can pick in Settings › Sounds (all generated).
  private func makeSound(_ name: String) -> AVAudioPCMBuffer {
    switch name {
    case "chime":
      // Two bell notes going up (E6 → A6).
      return concat([makeBell(base: 1318.5, length: 0.35), makeBell(base: 1760, length: 0.6)], gap: 0)
    case "click":
      // Short wooden knock: high sine with a very fast decay.
      return synth(length: 0.08) { (t: Double) -> Double in
        let a: Double = sin(2 * Double.pi * 1900 * t) * exp(-60 * t)
        let b: Double = sin(2 * Double.pi * 950 * t) * 0.4 * exp(-45 * t)
        return a + b
      }
    case "buzz":
      // Low, harsh buzzer (square wave).
      return synth(length: 0.35) { (t: Double) -> Double in
        let square: Double = sin(2 * Double.pi * 220 * t) >= 0 ? 0.45 : -0.45
        let fade: Double = min(1.0, (0.35 - t) * 40)
        return square * fade
      }
    case "whistle":
      // Rising whistle, like a coach's whistle.
      return synth(length: 0.35) { (t: Double) -> Double in
        let f: Double = 1700 + 1100 * (t / 0.35)
        let attack: Double = min(1.0, t * 80)
        let release: Double = min(1.0, (0.35 - t) * 30)
        return sin(2 * Double.pi * f * t) * 0.6 * attack * release
      }
    case "marimba":
      // Wooden bar: fundamental + a soft 4th harmonic, quick decay.
      return synth(length: 0.45) { (t: Double) -> Double in
        let a: Double = sin(2 * Double.pi * 784 * t) * exp(-9 * t)
        let b: Double = sin(2 * Double.pi * 3136 * t) * 0.25 * exp(-25 * t)
        return (a + b) * 0.8 * min(1.0, t / 0.002)
      }
    case "sonar":
      // Submarine ping: pure tone with a long soft tail.
      return synth(length: 0.9) { (t: Double) -> Double in
        sin(2 * Double.pi * 1320 * t) * 0.7 * exp(-4.5 * t) * min(1.0, t / 0.003)
      }
    case "rising":
      // Sweep up an octave.
      return synth(length: 0.3) { (t: Double) -> Double in
        let phase: Double = 2 * Double.pi * (600 * t + 1000 * t * t / 0.6)
        return sin(phase) * 0.6 * min(1.0, t * 100) * min(1.0, (0.3 - t) * 40)
      }
    case "falling":
      // Sweep down an octave.
      return synth(length: 0.3) { (t: Double) -> Double in
        let phase: Double = 2 * Double.pi * (1600 * t - 1000 * t * t / 0.6)
        return sin(phase) * 0.6 * min(1.0, t * 100) * min(1.0, (0.3 - t) * 40)
      }
    case "digital":
      // Sports-watch double chirp.
      let chirp = synth(length: 0.06) { (t: Double) -> Double in
        (sin(2 * Double.pi * 4000 * t) >= 0 ? 0.35 : -0.35) * min(1.0, (0.06 - t) * 200)
      }
      return concat([chirp, chirp], gap: 0.05)
    case "gong":
      // Deep metallic gong with a long fade.
      return synth(length: 1.6) { (t: Double) -> Double in
        let partials: [(Double, Double, Double)] = [(1.0, 0.5, 1.8), (1.48, 0.3, 2.4), (2.11, 0.2, 3.0), (2.9, 0.12, 4.0)]
        var v = 0.0
        for p in partials {
          v += sin(2 * Double.pi * 180 * p.0 * t) * p.1 * exp(-p.2 * t)
        }
        return v * min(1.0, t / 0.01)
      }
    case "fanfare":
      // Three notes going up (C6 E6 G6), the last one longer.
      func note(_ f: Double, _ len: Double) -> AVAudioPCMBuffer {
        synth(length: len) { (t: Double) -> Double in
          let w: Double = sin(2 * Double.pi * f * t) + 0.3 * sin(2 * Double.pi * 2 * f * t)
          return w * 0.45 * min(1.0, t * 150) * min(1.0, (len - t) * 25)
        }
      }
      return concat([note(1046.5, 0.12), note(1318.5, 0.12), note(1568, 0.35)], gap: 0.02)
    case "drop":
      // Water drop: a fast upward blip.
      return synth(length: 0.18) { (t: Double) -> Double in
        let phase: Double = 2 * Double.pi * (500 * t + 4000 * t * t)
        return sin(phase) * 0.7 * exp(-18 * t) * min(1.0, t / 0.002)
      }
    case "triangle":
      // Orchestra triangle: high, shimmering, long ring.
      return synth(length: 1.2) { (t: Double) -> Double in
        let a: Double = sin(2 * Double.pi * 3520 * t) * 0.35
        let b: Double = sin(2 * Double.pi * 5280 * t) * 0.2
        let c: Double = sin(2 * Double.pi * 7040 * t) * 0.1
        return (a + b + c) * exp(-3 * t) * min(1.0, t / 0.002)
      }
    case "horn":
      // Short car-horn honk: two detuned saw-like tones.
      return synth(length: 0.4) { (t: Double) -> Double in
        func saw(_ f: Double) -> Double { 2 * (f * t - floor(f * t + 0.5)) }
        let v: Double = (saw(415) + saw(440)) * 0.22
        return v * min(1.0, t * 60) * min(1.0, (0.4 - t) * 30)
      }
    default:
      return makeDing()
    }
  }

  /// A buffer of [length] seconds filled by [f] (time in seconds → sample).
  private func synth(length: Double, _ f: (Double) -> Double) -> AVAudioPCMBuffer {
    let sr = format.sampleRate
    let total = max(1, Int(length * sr))
    let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(total))!
    buffer.frameLength = AVAudioFrameCount(total)
    let data = buffer.floatChannelData![0]
    for i in 0..<total {
      data[i] = Float(f(Double(i) / sr)) * volume
    }
    return buffer
  }

  private func makeBell(base: Double, length: Double) -> AVAudioPCMBuffer {
    synth(length: length) { (t: Double) -> Double in
      let partials: [(Double, Double, Double)] = [(1.0, 0.6, 4.0), (2.76, 0.25, 7.0), (5.4, 0.1, 10.0)]
      var v = 0.0
      for p in partials {
        let wave: Double = sin(2 * Double.pi * base * p.0 * t)
        v += wave * p.1 * exp(-p.2 * t)
      }
      return v * min(1.0, t / 0.004)
    }
  }

  /// [buffers] one after another with [gap] seconds of silence between.
  private func concat(_ buffers: [AVAudioPCMBuffer], gap: Double) -> AVAudioPCMBuffer {
    let gapFrames = Int(gap * format.sampleRate)
    let total = buffers.reduce(0) { $0 + Int($1.frameLength) } + gapFrames * max(0, buffers.count - 1)
    let out = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(max(1, total)))!
    out.frameLength = AVAudioFrameCount(max(1, total))
    let dst = out.floatChannelData![0]
    var pos = 0
    for (i, b) in buffers.enumerated() {
      let src = b.floatChannelData![0]
      for j in 0..<Int(b.frameLength) {
        dst[pos + j] = src[j]
      }
      pos += Int(b.frameLength)
      if i < buffers.count - 1 {
        for j in 0..<gapFrames {
          dst[pos + j] = 0
        }
        pos += gapFrames
      }
    }
    return out
  }

  private func repeated(_ buffer: AVAudioPCMBuffer, count: Int) -> AVAudioPCMBuffer {
    count <= 1 ? buffer : concat(Array(repeating: buffer, count: count), gap: 0.12)
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

extension BeeperPlugin: AVSpeechSynthesizerDelegate {
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
    DispatchQueue.main.async { [weak self] in self?.unduck() }
  }

  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
    DispatchQueue.main.async { [weak self] in self?.unduck() }
  }
}
