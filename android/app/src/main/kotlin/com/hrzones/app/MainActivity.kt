package com.hrzones.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
  private var beeper: BeeperPlugin? = null
  private var live: LiveActivityPlugin? = null

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    // Native twins of the iOS modules, on the same channel names (docs/ANDROID.md rule 1).
    val messenger = flutterEngine.dartExecutor.binaryMessenger
    beeper = BeeperPlugin(applicationContext, messenger)
    live = LiveActivityPlugin(applicationContext, messenger)
  }

  override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
    beeper?.dispose()
    beeper = null
    live?.dispose()
    live = null
    super.cleanUpFlutterEngine(flutterEngine)
  }
}
