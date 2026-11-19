package com.hrzones.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
  private var beeper: BeeperPlugin? = null
  private var live: LiveActivityPlugin? = null
  private var motion: MotionPlugin? = null
  private var system: SystemPlugin? = null

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    // Native twins of the iOS modules, on the same channel names (docs/ANDROID.md rule 1).
    val messenger = flutterEngine.dartExecutor.binaryMessenger
    beeper = BeeperPlugin(applicationContext, messenger)
    live = LiveActivityPlugin(applicationContext, messenger)
    motion = MotionPlugin(applicationContext, messenger)
    system = SystemPlugin(applicationContext, messenger, this)
  }

  override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
    super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    system?.onPermissionResult(requestCode)
  }

  override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
    // The Dart side is going away: nothing can update or end the workout card any more.
    WorkoutService.end(applicationContext)
    beeper?.dispose()
    beeper = null
    live?.dispose()
    live = null
    motion?.dispose()
    motion = null
    system?.dispose()
    system = null
    super.cleanUpFlutterEngine(flutterEngine)
  }
}
