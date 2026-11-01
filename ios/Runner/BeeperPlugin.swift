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

  override init() {
    super.init()
    engine.attach(player)
    engine.connect(player, to: engine.mainMixerNode, format: format)
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
    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.playback, options: [.mixWithOthers])
    try session.setActive(true)
    if !engine.isRunning { try engine.start() }
    if !player.isPlaying { player.play() }
  }

  private func stop() {
    player.stop()
    engine.stop()
    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
  }

  private func beep(frequency: Double, count: Int) throws {
    if !engine.isRunning { try start() }
    player.scheduleBuffer(makePattern(frequency: frequency, count: count), completionHandler: nil)
    if !player.isPlaying { player.play() }
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
