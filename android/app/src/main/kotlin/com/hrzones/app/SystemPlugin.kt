package com.hrzones.app

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Android-only helpers on channel "hrzones/system" (Phase 5 step 6; Dart: lib/platform/phone_system.dart):
 * - permission {name: bluetooth | activity}: asks for the runtime permission when it is needed
 *   (docs/ANDROID.md rules 20, 24) and answers whether it is allowed.
 * - battery: whether Android may stop the app in the background, and the phone's brand.
 * - openAppSettings: App info (Battery → Unrestricted, permissions).
 * - openUrl: a web page (battery help per brand).
 * iOS has no such channel; Dart treats the missing plugin as "allowed".
 */
class SystemPlugin(
  private val context: Context,
  messenger: BinaryMessenger,
  private val activity: Activity,
) : MethodChannel.MethodCallHandler {
  private val channel = MethodChannel(messenger, "hrzones/system")
  private var pending: MethodChannel.Result? = null
  private var pendingPermissions: Array<String> = emptyArray()

  init {
    channel.setMethodCallHandler(this)
  }

  fun dispose() {
    channel.setMethodCallHandler(null)
    pending?.success(false)
    pending = null
  }

  private fun permissionsFor(name: String): Array<String> =
    when (name) {
      "bluetooth" ->
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
          arrayOf(Manifest.permission.BLUETOOTH_SCAN, Manifest.permission.BLUETOOTH_CONNECT)
        } else {
          // Android 11 and older find Bluetooth devices only with location allowed.
          arrayOf(Manifest.permission.ACCESS_FINE_LOCATION)
        }
      "activity" ->
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
          arrayOf(Manifest.permission.ACTIVITY_RECOGNITION)
        } else {
          emptyArray()
        }
      else -> emptyArray()
    }

  private fun granted(permissions: Array<String>) =
    permissions.all { context.checkSelfPermission(it) == PackageManager.PERMISSION_GRANTED }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    try {
      when (call.method) {
        "permission" -> {
          val permissions = permissionsFor(call.argument<String>("name") ?: "")
          when {
            granted(permissions) -> result.success(true)
            call.argument<Boolean>("ask") == false -> result.success(false)
            pending != null -> result.success(false)
            else -> {
              pending = result
              pendingPermissions = permissions
              activity.requestPermissions(permissions, REQUEST_CODE)
            }
          }
        }
        "battery" -> {
          val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
          result.success(
            mapOf(
              "unrestricted" to pm.isIgnoringBatteryOptimizations(context.packageName),
              "brand" to Build.MANUFACTURER.lowercase(),
              "sdk" to Build.VERSION.SDK_INT,
            )
          )
        }
        "openAppSettings" -> {
          val intent =
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.fromParts("package", context.packageName, null))
              .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
          activity.startActivity(intent)
          result.success(true)
        }
        "openUrl" -> {
          val url = call.argument<String>("url") ?: return result.success(false)
          if (!url.startsWith("https://")) return result.success(false)
          activity.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
          result.success(true)
        }
        else -> result.notImplemented()
      }
    } catch (e: Exception) {
      result.error("system", e.message, null)
    }
  }

  /** Called from MainActivity.onRequestPermissionsResult. */
  fun onPermissionResult(requestCode: Int): Boolean {
    if (requestCode != REQUEST_CODE) return false
    val result = pending ?: return true
    pending = null
    result.success(granted(pendingPermissions))
    return true
  }

  companion object {
    const val REQUEST_CODE = 7302
  }
}
