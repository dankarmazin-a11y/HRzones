package com.hrzones.app

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.SystemClock
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Android twin of ios/Runner/MotionPlugin.swift, same channel ("hrzones/motion") and methods:
 * - start / stop / read: steps since start, cadence (steps per minute) and the height change
 *   since start from the barometer (null on phones without one).
 * - daily: steps per day. Android's step counter only counts since the phone was switched on and
 *   keeps no history, so this returns null for now (the Home card hides itself – never show a
 *   guess; docs/ANDROID.md rule 35). Health Connect comes in a later step.
 *
 * Android 10+ needs the "Physical activity" permission for the step counter; Dart asks for it
 * before a run starts (SystemPlugin "permission" activity). Without it only the barometer runs.
 */
class MotionPlugin(
  private val context: Context,
  messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler, SensorEventListener {
  private val channel = MethodChannel(messenger, "hrzones/motion")
  private val sensors = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
  private val stepSensor: Sensor? = sensors.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
  private val pressureSensor: Sensor? = sensors.getDefaultSensor(Sensor.TYPE_PRESSURE)

  private var listening = false
  /** The phone's step counter (since it was switched on) at the first reading after start. */
  private var stepBase: Float? = null
  private var steps = 0
  /** (time ms, steps) of recent readings, for the cadence. */
  private val recent = ArrayDeque<Pair<Long, Int>>()

  private var heightBase: Double? = null
  private var height: Double? = null

  init {
    channel.setMethodCallHandler(this)
  }

  fun dispose() {
    stopSensors()
    channel.setMethodCallHandler(null)
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "start" -> result.success(start())
      "stop" -> {
        stopSensors()
        result.success(null)
      }
      "read" -> result.success(read())
      "daily" -> result.success(null)
      else -> result.notImplemented()
    }
  }

  private fun canCountSteps(): Boolean {
    if (stepSensor == null) return false
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return true
    return context.checkSelfPermission(Manifest.permission.ACTIVITY_RECOGNITION) ==
      PackageManager.PERMISSION_GRANTED
  }

  private fun start(): Boolean {
    stopSensors()
    steps = 0
    stepBase = null
    recent.clear()
    heightBase = null
    height = null

    val counting = canCountSteps()
    if (counting) {
      // No batching: live steps for the cadence.
      sensors.registerListener(this, stepSensor, SensorManager.SENSOR_DELAY_NORMAL, 0)
    }
    if (pressureSensor != null) {
      sensors.registerListener(this, pressureSensor, SensorManager.SENSOR_DELAY_NORMAL)
    }
    listening = counting || pressureSensor != null
    return listening
  }

  private fun stopSensors() {
    if (listening) sensors.unregisterListener(this)
    listening = false
  }

  private fun read(): Map<String, Any> {
    val out = mutableMapOf<String, Any>("steps" to steps)
    cadence()?.let { out["cadence"] = it }
    height?.let { out["altitude"] = it }
    return out
  }

  /** Steps per minute over the last ~10 s; null until there are enough readings. */
  private fun cadence(): Double? {
    val now = SystemClock.elapsedRealtime()
    while (recent.isNotEmpty() && now - recent.first().first > CADENCE_WINDOW_MS) recent.removeFirst()
    if (recent.size < 2) {
      // Standing still: no new steps for a while → 0.
      return if (stepBase != null && recent.isEmpty()) 0.0 else null
    }
    val first = recent.first()
    val last = recent.last()
    // Up to now, so stopping brings the cadence down even without new readings.
    val ms = (now - first.first).coerceAtLeast(1000L)
    return (last.second - first.second) * 60000.0 / ms
  }

  override fun onSensorChanged(event: SensorEvent) {
    when (event.sensor.type) {
      Sensor.TYPE_STEP_COUNTER -> {
        val total = event.values[0]
        val base = stepBase ?: total.also { stepBase = it }
        steps = (total - base).toInt().coerceAtLeast(0)
        recent.addLast(SystemClock.elapsedRealtime() to steps)
      }
      Sensor.TYPE_PRESSURE -> {
        val metres =
          SensorManager.getAltitude(SensorManager.PRESSURE_STANDARD_ATMOSPHERE, event.values[0]).toDouble()
        val base = heightBase ?: metres.also { heightBase = it }
        val relative = metres - base
        // Smooth the sensor noise (~0.1 hPa ≈ 1 m); about 5 readings a second.
        height = height?.let { it + (relative - it) * SMOOTHING } ?: relative
      }
    }
  }

  override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

  companion object {
    const val CADENCE_WINDOW_MS = 10_000L
    const val SMOOTHING = 0.1
  }
}
