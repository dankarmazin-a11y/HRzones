package com.hrzones.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
  private var beeper: BeeperPlugin? = null

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    // Native twins of the iOS modules, on the same channel names (docs/ANDROID.md rule 1).
    beeper = BeeperPlugin(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
  }

  override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
    beeper?.dispose()
    beeper = null
    super.cleanUpFlutterEngine(flutterEngine)
  }
}
