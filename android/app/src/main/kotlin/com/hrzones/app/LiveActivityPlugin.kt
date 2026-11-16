package com.hrzones.app

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Android twin of ios/Runner/LiveActivityPlugin.swift, same channel ("hrzones/live") and
 * methods: start / update / end / status, and "action" back to Dart when a card button is
 * tapped. The card is an ongoing notification held by [WorkoutService].
 */
class LiveActivityPlugin(private val context: Context, messenger: BinaryMessenger) :
  MethodChannel.MethodCallHandler {
  private val channel = MethodChannel(messenger, "hrzones/live")
  private var name = "Workout"

  init {
    channel.setMethodCallHandler(this)
    instance = this
  }

  fun dispose() {
    channel.setMethodCallHandler(null)
    if (instance === this) instance = null
  }

  fun sendAction(action: String) {
    channel.invokeMethod("action", action)
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    try {
      when (call.method) {
        "available" -> result.success(WorkoutService.notificationManager(context).areNotificationsEnabled())
        "start" -> {
          val kind = call.argument<String>("kind") ?: "strength"
          name = call.argument<String>("name") ?: "Workout"
          val state = call.argument<Map<*, *>>("state") ?: emptyMap<String, Any>()
          WorkoutService.start(context, kind, WorkoutService.build(context, name, state))
          result.success(null)
        }
        "update" -> {
          val state = call.argument<Map<*, *>>("state") ?: emptyMap<String, Any>()
          if (WorkoutService.latest != null) {
            WorkoutService.update(context, WorkoutService.build(context, name, state))
          }
          result.success(null)
        }
        "end" -> {
          WorkoutService.end(context)
          result.success(null)
        }
        "status" ->
          result.success(
            mapOf(
              "android" to true,
              "enabled" to WorkoutService.notificationManager(context).areNotificationsEnabled(),
              "keepsRunning" to (WorkoutService.serviceType(context, "run") != 0),
              "running" to (if (WorkoutService.latest != null) 1 else 0),
            )
          )
        else -> result.notImplemented()
      }
    } catch (e: Exception) {
      result.error("live", e.message, null)
    }
  }

  companion object {
    @Volatile var instance: LiveActivityPlugin? = null
  }
}
