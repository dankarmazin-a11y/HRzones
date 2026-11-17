package com.hrzones.app

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.speech.tts.Voice
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Locale
import java.util.concurrent.Executors
import kotlin.math.PI
import kotlin.math.exp
import kotlin.math.floor
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin

/**
 * Android twin of ios/Runner/BeeperPlugin.swift – same channel ("hrzones/beeper") and methods,
 * so the Dart side (lib/beep/beeper.dart) doesn't change.
 *
 * - Sounds are generated (same formulas as iOS) and played with a short AudioTrack. They mix
 *   over the user's music (no audio focus is taken for a beep, like iOS .mixWithOthers).
 * - Spoken updates use TextToSpeech and ask for *transient focus with ducking*: the music is
 *   turned down while talking and comes back when the sentence is over.
 * - start/stop holds: Android keeps the app alive with the screen off through the foreground
 *   service (Phase 5 step 4), not through the audio, so here they only record that sound is
 *   wanted.
 */
class BeeperPlugin(private val context: Context, messenger: BinaryMessenger) : MethodChannel.MethodCallHandler {
  private val channel = MethodChannel(messenger, "hrzones/beeper")
  private val audio = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
  private val main = Handler(Looper.getMainLooper())

  /** Sounds are built and played off the UI thread, one after another. */
  private val worker = Executors.newSingleThreadExecutor()
  private var volume = 0.7f
  private var wanted = false

  /** The sound playing now; a newer sound cuts it off (like iOS). */
  private var current: AudioTrack? = null

  private var tts: TextToSpeech? = null
  private var ttsReady = false
  private val pendingSpeech = mutableListOf<Pair<String, String>>()
  private var focusRequest: AudioFocusRequest? = null
  private var utteranceId = 0

  // Beeps: on the media volume (what is up while music plays), as a short sound effect.
  private val beepAttributes =
    AudioAttributes.Builder()
      .setUsage(AudioAttributes.USAGE_ASSISTANCE_NAVIGATION_GUIDANCE)
      .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
      .build()
  private val speechAttributes =
    AudioAttributes.Builder()
      .setUsage(AudioAttributes.USAGE_ASSISTANCE_NAVIGATION_GUIDANCE)
      .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
      .build()

  init {
    channel.setMethodCallHandler(this)
  }

  fun dispose() {
    channel.setMethodCallHandler(null)
    worker.shutdownNow()
    current?.release()
    tts?.shutdown()
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    try {
      when (call.method) {
        "start" -> {
          wanted = true
          result.success(null)
        }
        "stop" -> {
          wanted = false
          result.success(null)
        }
        "beep" -> {
          val frequency = (call.argument<Number>("frequency") ?: 1000).toDouble()
          val count = (call.argument<Number>("count") ?: 1).toInt()
          playLater { makePattern(frequency, count) }
          result.success(null)
        }
        "ding" -> {
          playLater { makeDing() }
          result.success(null)
        }
        "sound" -> {
          val name = call.argument<String>("name") ?: "ding"
          val count = max(1, (call.argument<Number>("count") ?: 1).toInt())
          playLater { repeated(makeSound(name), count) }
          result.success(null)
        }
        "speak" -> {
          speak(call.argument<String>("text") ?: "", call.argument<String>("voice") ?: "default")
          result.success(null)
        }
        "setVolume" -> {
          volume = (call.argument<Number>("volume") ?: 0.7).toFloat()
          result.success(null)
        }
        else -> result.notImplemented()
      }
    } catch (e: Exception) {
      result.error("audio", e.message, null)
    }
  }

  // ---------------------------------------------------------------- playback

  private fun playLater(make: () -> FloatArray) {
    worker.execute {
      try {
        play(make())
      } catch (_: Exception) {
        // A sound that can't play must never crash a workout.
      }
    }
  }

  private fun play(samples: FloatArray) {
    val pcm = ShortArray(samples.size) { i ->
      (samples[i] * volume).coerceIn(-1f, 1f).times(Short.MAX_VALUE).toInt().toShort()
    }
    val track =
      AudioTrack.Builder()
        .setAudioAttributes(beepAttributes)
        .setAudioFormat(
          AudioFormat.Builder()
            .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
            .setSampleRate(RATE)
            .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
            .build()
        )
        .setTransferMode(AudioTrack.MODE_STATIC)
        .setBufferSizeInBytes(pcm.size * 2)
        .build()
    track.write(pcm, 0, pcm.size)
    current?.let {
      try {
        it.stop()
      } catch (_: IllegalStateException) {}
      it.release()
    }
    current = track
    track.play()
    // Free the track once the sound is over (unless a newer one already replaced it).
    val lengthMs = samples.size * 1000L / RATE + 200
    main.postDelayed(
      {
        worker.execute {
          if (current === track) {
            track.release()
            current = null
          }
        }
      },
      lengthMs,
    )
  }

  // ------------------------------------------------------------------ speech

  private fun speak(text: String, voice: String) {
    if (text.isEmpty()) return
    val engine = tts
    if (engine == null) {
      pendingSpeech.add(text to voice)
      tts = TextToSpeech(context) { status ->
        main.post {
          ttsReady = status == TextToSpeech.SUCCESS
          val waiting = pendingSpeech.toList()
          pendingSpeech.clear()
          if (ttsReady) {
            tts?.setAudioAttributes(speechAttributes)
            tts?.setOnUtteranceProgressListener(progress)
            waiting.forEach { (t, v) -> say(t, v) }
          }
        }
      }
      return
    }
    if (!ttsReady) {
      pendingSpeech.add(text to voice)
      return
    }
    say(text, voice)
  }

  private fun say(text: String, kind: String) {
    val engine = tts ?: return
    engine.language = Locale.US
    englishVoice(engine, kind)?.let { engine.voice = it }
    duck()
    utteranceId += 1
    // One volume for all the app's sounds (Settings › Sounds), like iOS; never fully silent.
    val params = Bundle().apply { putFloat(TextToSpeech.Engine.KEY_PARAM_VOLUME, volume.coerceIn(0.1f, 1f)) }
    engine.speak(text, TextToSpeech.QUEUE_ADD, params, "hrz$utteranceId")
  }

  private val progress =
    object : UtteranceProgressListener() {
      override fun onStart(id: String?) {}

      override fun onDone(id: String?) {
        main.post { if (tts?.isSpeaking != true) unduck() }
      }

      @Deprecated("Deprecated in Java")
      override fun onError(id: String?) {
        main.post { if (tts?.isSpeaking != true) unduck() }
      }
    }

  /** Turns other apps' music down while talking. */
  private fun duck() {
    if (focusRequest != null) return
    val request =
      AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK)
        .setAudioAttributes(speechAttributes)
        .setOnAudioFocusChangeListener {}
        .build()
    audio.requestAudioFocus(request)
    focusRequest = request
  }

  /** Gives the music its full volume back. */
  private fun unduck() {
    focusRequest?.let { audio.abandonAudioFocusRequest(it) }
    focusRequest = null
  }

  /**
   * An English voice: "female" / "male" picks one of that gender if the engine tells (Google
   * voice codes, Samsung's "SMTf"/"SMTm" names), "default" the engine's US English voice.
   */
  private fun englishVoice(engine: TextToSpeech, kind: String): Voice? {
    if (kind != "female" && kind != "male") return null
    val voices =
      try {
        engine.voices?.toList() ?: return null
      } catch (_: Exception) {
        return null
      }
    val english = voices.filter { it.locale.language == "en" && !it.isNetworkConnectionRequired }
    val matching = english.filter { genderOf(it) == kind }
    return matching.sortedWith(
      compareByDescending<Voice> { it.locale.country == "US" }.thenByDescending { it.quality }
    ).firstOrNull()
  }

  private fun genderOf(v: Voice): String? {
    val name = v.name.lowercase(Locale.ROOT)
    v.features?.forEach { f ->
      val lf = f.lowercase(Locale.ROOT)
      if (lf.contains("female")) return "female"
      if (lf.contains("male")) return "male"
    }
    Regex("smt([fm])").find(name)?.let { return if (it.groupValues[1] == "f") "female" else "male" }
    if (FEMALE_CODES.any { name.contains("-x-$it") }) return "female"
    if (MALE_CODES.any { name.contains("-x-$it") }) return "male"
    return null
  }

  // ---------------------------------------------------------------- sounds
  // Same formulas as BeeperPlugin.swift (makeSound). Values are -1…1; volume is applied in play().

  private fun makeSound(name: String): FloatArray =
    when (name) {
      // Two bell notes going up (E6 → A6).
      "chime" -> concat(listOf(makeBell(1318.5, 0.35), makeBell(1760.0, 0.6)), 0.0)
      // Short wooden knock.
      "click" ->
        synth(0.08) { t -> sin(2 * PI * 1900 * t) * exp(-60 * t) + sin(2 * PI * 950 * t) * 0.4 * exp(-45 * t) }
      // Low, harsh buzzer (square wave).
      "buzz" ->
        synth(0.35) { t -> (if (sin(2 * PI * 220 * t) >= 0) 0.45 else -0.45) * min(1.0, (0.35 - t) * 40) }
      // Rising whistle.
      "whistle" ->
        synth(0.35) { t ->
          val f = 1700 + 1100 * (t / 0.35)
          sin(2 * PI * f * t) * 0.6 * min(1.0, t * 80) * min(1.0, (0.35 - t) * 30)
        }
      "marimba" ->
        synth(0.45) { t ->
          (sin(2 * PI * 784 * t) * exp(-9 * t) + sin(2 * PI * 3136 * t) * 0.25 * exp(-25 * t)) *
            0.8 *
            min(1.0, t / 0.002)
        }
      "sonar" -> synth(0.9) { t -> sin(2 * PI * 1320 * t) * 0.7 * exp(-4.5 * t) * min(1.0, t / 0.003) }
      "rising" ->
        synth(0.3) { t ->
          sin(2 * PI * (600 * t + 1000 * t * t / 0.6)) * 0.6 * min(1.0, t * 100) * min(1.0, (0.3 - t) * 40)
        }
      "falling" ->
        synth(0.3) { t ->
          sin(2 * PI * (1600 * t - 1000 * t * t / 0.6)) * 0.6 * min(1.0, t * 100) * min(1.0, (0.3 - t) * 40)
        }
      "digital" -> {
        val chirp =
          synth(0.06) { t -> (if (sin(2 * PI * 4000 * t) >= 0) 0.35 else -0.35) * min(1.0, (0.06 - t) * 200) }
        concat(listOf(chirp, chirp), 0.05)
      }
      "gong" ->
        synth(1.6) { t ->
          val partials =
            arrayOf(
              doubleArrayOf(1.0, 0.5, 1.8),
              doubleArrayOf(1.48, 0.3, 2.4),
              doubleArrayOf(2.11, 0.2, 3.0),
              doubleArrayOf(2.9, 0.12, 4.0),
            )
          var v = 0.0
          for (p in partials) v += sin(2 * PI * 180 * p[0] * t) * p[1] * exp(-p[2] * t)
          v * min(1.0, t / 0.01)
        }
      "fanfare" -> {
        fun note(f: Double, len: Double) =
          synth(len) { t ->
            (sin(2 * PI * f * t) + 0.3 * sin(2 * PI * 2 * f * t)) * 0.45 * min(1.0, t * 150) * min(1.0, (len - t) * 25)
          }
        concat(listOf(note(1046.5, 0.12), note(1318.5, 0.12), note(1568.0, 0.35)), 0.02)
      }
      "drop" ->
        synth(0.18) { t -> sin(2 * PI * (500 * t + 4000 * t * t)) * 0.7 * exp(-18 * t) * min(1.0, t / 0.002) }
      "triangle" ->
        synth(1.2) { t ->
          (sin(2 * PI * 3520 * t) * 0.35 + sin(2 * PI * 5280 * t) * 0.2 + sin(2 * PI * 7040 * t) * 0.1) *
            exp(-3 * t) *
            min(1.0, t / 0.002)
        }
      "horn" ->
        synth(0.4) { t ->
          fun saw(f: Double) = 2 * (f * t - floor(f * t + 0.5))
          (saw(415.0) + saw(440.0)) * 0.22 * min(1.0, t * 60) * min(1.0, (0.4 - t) * 30)
        }
      else -> makeDing()
    }

  private fun synth(length: Double, f: (Double) -> Double): FloatArray {
    val total = max(1, (length * RATE).toInt())
    return FloatArray(total) { i -> f(i.toDouble() / RATE).toFloat() }
  }

  private fun makeBell(base: Double, length: Double) =
    synth(length) { t ->
      val v =
        sin(2 * PI * base * t) * 0.6 * exp(-4.0 * t) +
          sin(2 * PI * base * 2.76 * t) * 0.25 * exp(-7.0 * t) +
          sin(2 * PI * base * 5.4 * t) * 0.1 * exp(-10.0 * t)
      v * min(1.0, t / 0.004)
    }

  private fun concat(parts: List<FloatArray>, gap: Double): FloatArray {
    val gapFrames = (gap * RATE).toInt()
    val total = max(1, parts.sumOf { it.size } + gapFrames * max(0, parts.size - 1))
    val out = FloatArray(total)
    var pos = 0
    parts.forEachIndexed { i, p ->
      p.copyInto(out, pos)
      pos += p.size
      if (i < parts.size - 1) pos += gapFrames
    }
    return out
  }

  private fun repeated(sound: FloatArray, count: Int) =
    if (count <= 1) sound else concat(List(count) { sound }, 0.12)

  /** Bell-like "ding" (end of rest), ~1.2 s. */
  private fun makeDing(): FloatArray {
    val total = (1.2 * RATE).toInt()
    val attack = 0.004 * RATE
    val base = 1318.5
    return FloatArray(total) { i ->
      val t = i.toDouble() / RATE
      val v =
        sin(2 * PI * base * t) * 0.6 * exp(-3.5 * t) +
          sin(2 * PI * base * 2.76 * t) * 0.25 * exp(-6.0 * t) +
          sin(2 * PI * base * 5.4 * t) * 0.12 * exp(-9.0 * t)
      (v * min(1.0, i / attack)).toFloat()
    }
  }

  /** [count] beeps of 150 ms with 100 ms gaps (zone alerts: 3 high / 2 low). */
  private fun makePattern(frequency: Double, count: Int): FloatArray {
    val beepLen = (0.15 * RATE).toInt()
    val unit = beepLen + (0.10 * RATE).toInt()
    val total = max(1, count) * unit
    val fade = 220.0
    return FloatArray(total) { i ->
      val pos = i % unit
      if (pos < beepLen) {
        val env = min(1.0, min(pos, beepLen - pos) / fade)
        (sin(2 * PI * frequency * i / RATE) * env).toFloat()
      } else {
        0f
      }
    }
  }

  companion object {
    private const val RATE = 44_100
    // Google TTS voice codes (en-us-x-<code>-local / -network).
    private val FEMALE_CODES = listOf("sfg", "tpc", "tpf", "iob", "iog", "gba", "fis")
    private val MALE_CODES = listOf("iol", "iom", "tpd", "gbb", "gbd", "rjs")
  }
}
