package com.hrzones.app

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.graphics.Color
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager

/**
 * Keeps a workout / run / interval timer alive with the screen off (Phase 5 step 4) and shows
 * the workout card as an ongoing notification (the Android twin of the iOS lock-screen card).
 *
 * - Foreground service type: location while location is allowed (outdoor runs record GPS in the
 *   background), health when only activity recognition is allowed (Android 14+). If neither is
 *   allowed yet the card is posted as a plain notification and nothing is kept alive (step 6
 *   asks for the permissions).
 * - A partial wake lock keeps the CPU running so Dart timers, beeps and voice stay on time.
 */
class WorkoutService : Service() {
  private var wakeLock: PowerManager.WakeLock? = null

  override fun onBind(intent: Intent?): IBinder? = null

  override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
    val card = latest
    if (card == null) {
      // Ended before the service got going (a run's 3-2-1 countdown cancelled right away).
      // A service started with startForegroundService must still call startForeground, or
      // Android stops the whole app; show a blank card for a moment and go.
      try {
        ensureChannel(this)
        val blank = Notification.Builder(this, CHANNEL_ID).setSmallIcon(R.drawable.ic_notification).build()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
          startForeground(NOTIFICATION_ID, blank, serviceType(this, kind).takeIf { it != 0 }
            ?: ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION)
        } else {
          startForeground(NOTIFICATION_ID, blank)
        }
      } catch (_: Exception) {}
      stopForeground(STOP_FOREGROUND_REMOVE)
      stopSelf()
      return START_NOT_STICKY
    }
    val notification = card
    try {
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
        val type = serviceType(this, kind)
        if (type == 0) throw IllegalStateException("No foreground-service permission yet")
        startForeground(NOTIFICATION_ID, notification, type)
      } else {
        startForeground(NOTIFICATION_ID, notification)
      }
      running = true
      holdWakeLock()
    } catch (e: Exception) {
      // Not allowed (missing permission, or started from the background): show the card only.
      running = false
      notificationManager(this).notify(NOTIFICATION_ID, notification)
      stopSelf()
    }
    return START_NOT_STICKY
  }

  private fun holdWakeLock() {
    if (wakeLock?.isHeld == true) return
    val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
    wakeLock =
      pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "HRZones:workout").apply {
        setReferenceCounted(false)
        // Safety net: a forgotten workout can't keep the CPU awake for ever.
        acquire(6 * 60 * 60 * 1000L)
      }
  }

  /**
   * The app was swiped away from the recent apps. The Dart side (timers, GPS, beeps) is gone
   * with it, so the card would stay for ever with a clock that keeps ticking, and couldn't be
   * swiped away (owner's Galaxy, 2026-11-19). End it; the workout itself is saved and comes
   * back when the app is opened again (like on iPhone).
   */
  override fun onTaskRemoved(rootIntent: Intent?) {
    end(this)
    super.onTaskRemoved(rootIntent)
  }

  override fun onDestroy() {
    running = false
    wakeLock?.let { if (it.isHeld) it.release() }
    wakeLock = null
    super.onDestroy()
  }

  companion object {
    const val NOTIFICATION_ID = 4711
    const val CHANNEL_ID = "workout"
    const val ACTION_EXTRA = "action"

    /** The card to show; set before starting the service, replaced by [update]. */
    @Volatile var latest: Notification? = null
    @Volatile var kind: String = "strength"
    @Volatile var running = false

    fun notificationManager(context: Context) =
      context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    private fun granted(context: Context, permission: String) =
      context.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED

    /** The foreground-service types this workout may use right now (0 = none allowed). */
    fun serviceType(context: Context, kind: String): Int {
      if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
        // Before Android 14 only the location type is checked (and only declared).
        return ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
      }
      var type = 0
      if (granted(context, Manifest.permission.ACCESS_FINE_LOCATION) ||
          granted(context, Manifest.permission.ACCESS_COARSE_LOCATION)) {
        type = type or ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
      }
      if (granted(context, Manifest.permission.ACTIVITY_RECOGNITION)) {
        type = type or ServiceInfo.FOREGROUND_SERVICE_TYPE_HEALTH
      }
      return type
    }

    fun ensureChannel(context: Context) {
      val nm = notificationManager(context)
      if (nm.getNotificationChannel(CHANNEL_ID) != null) return
      nm.createNotificationChannel(
        NotificationChannel(CHANNEL_ID, "Workout in progress", NotificationManager.IMPORTANCE_LOW).apply {
          description = "The card for a running workout, run or timer"
          setShowBadge(false)
          lockscreenVisibility = Notification.VISIBILITY_PUBLIC
        }
      )
    }

    /** Shows the card and keeps the app alive. */
    fun start(context: Context, kind: String, notification: Notification) {
      ensureChannel(context)
      this.kind = kind
      latest = notification
      // Android 14+ without location / activity permission: no foreground service is allowed.
      // Don't start one (a started service that never goes foreground stops the whole app);
      // just show the card.
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE && serviceType(context, kind) == 0) {
        notificationManager(context).notify(NOTIFICATION_ID, notification)
        return
      }
      val intent = Intent(context, WorkoutService::class.java)
      try {
        context.startForegroundService(intent)
      } catch (e: Exception) {
        // Android 12+ refuses from the background: still show the card.
        notificationManager(context).notify(NOTIFICATION_ID, notification)
      }
    }

    fun update(context: Context, notification: Notification) {
      latest = notification
      notificationManager(context).notify(NOTIFICATION_ID, notification)
    }

    fun end(context: Context) {
      latest = null
      context.stopService(Intent(context, WorkoutService::class.java))
      notificationManager(context).cancel(NOTIFICATION_ID)
    }

    // ------------------------------------------------------------- the card

    private val actionLabels =
      mapOf("completeSet" to "Set done", "startSet" to "Start", "skipRest" to "Skip rest")

    /** Builds the card from the same state map the iOS Live Activity gets (LiveCard.toMap). */
    fun build(context: Context, name: String, state: Map<*, *>): Notification {
      ensureChannel(context)
      val title = state["title"] as? String ?: name
      val detail = state["detail"] as? String ?: ""
      val heartRate = (state["heartRate"] as? Number)?.toInt()
      val paused = state["paused"] as? Boolean ?: false
      val clockStart = (state["clockStart"] as? Number)?.toLong()
      val elapsed = (state["elapsed"] as? Number)?.toLong() ?: 0L
      val countdownEnd = (state["countdownEnd"] as? Number)?.toLong()
      val countdownLabel = state["countdownLabel"] as? String
      val metrics =
        (state["metrics"] as? List<*>)?.mapNotNull { m ->
          val map = m as? Map<*, *> ?: return@mapNotNull null
          "${map["label"]} ${map["value"]}"
        } ?: emptyList()
      val actions = (state["actions"] as? List<*>)?.mapNotNull { it as? String } ?: emptyList()
      val accent =
        (state["accent"] as? String)?.let {
          try {
            Color.parseColor("#$it")
          } catch (_: Exception) {
            null
          }
        }

      val lines = mutableListOf<String>()
      if (detail.isNotEmpty()) lines += detail
      val numbers = metrics.toMutableList()
      if (heartRate != null && metrics.none { it.startsWith("Heart") }) numbers += "♥ $heartRate"
      if (numbers.isNotEmpty()) lines += numbers.joinToString(" · ")
      val text = lines.joinToString("\n")

      val open =
        context.packageManager.getLaunchIntentForPackage(context.packageName)?.let {
          it.flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
          PendingIntent.getActivity(context, 0, it, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        }

      val b =
        Notification.Builder(context, CHANNEL_ID)
          .setSmallIcon(R.drawable.ic_notification)
          .setContentTitle(title)
          .setContentText(lines.firstOrNull() ?: name)
          .setStyle(Notification.BigTextStyle().bigText(text))
          .setOngoing(true)
          .setOnlyAlertOnce(true)
          .setCategory(Notification.CATEGORY_WORKOUT)
          .setVisibility(Notification.VISIBILITY_PUBLIC)
          .setContentIntent(open)
      accent?.let { b.setColor(it) }

      val now = System.currentTimeMillis()
      when {
        countdownEnd != null && countdownEnd > now -> {
          // Rest / timed set: counts down by itself.
          b.setWhen(countdownEnd).setShowWhen(true).setUsesChronometer(true).setChronometerCountDown(true)
          countdownLabel?.let { b.setSubText(it) }
        }
        !paused && clockStart != null -> {
          b.setWhen(clockStart).setShowWhen(true).setUsesChronometer(true)
          b.setSubText(name)
        }
        else -> {
          b.setShowWhen(false)
          b.setSubText(if (paused) "Paused · ${clock(elapsed)}" else name)
        }
      }

      actions.forEachIndexed { i, action ->
        val intent =
          Intent(context, CardActionReceiver::class.java).putExtra(ACTION_EXTRA, action).setPackage(context.packageName)
        val pending =
          PendingIntent.getBroadcast(
            context,
            100 + i,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
          )
        b.addAction(Notification.Action.Builder(null, actionLabels[action] ?: action, pending).build())
      }

      // Android 16: ask to show it as a Live Update (status-bar chip, top of the lock screen).
      // (Notification.EXTRA_REQUEST_PROMOTED_ONGOING; ignored on older Android.)
      b.extras.putBoolean("android.requestPromotedOngoing", true)
      return b.build()
    }

    private fun clock(seconds: Long): String {
      val h = seconds / 3600
      val m = (seconds % 3600) / 60
      val s = seconds % 60
      return if (h > 0) "%d:%02d:%02d".format(h, m, s) else "%d:%02d".format(m, s)
    }
  }
}

/** A button on the card was tapped: tell Dart (WorkoutSession.handleCardAction). */
class CardActionReceiver : BroadcastReceiver() {
  override fun onReceive(context: Context, intent: Intent) {
    val action = intent.getStringExtra(WorkoutService.ACTION_EXTRA) ?: return
    Handler(Looper.getMainLooper()).post { LiveActivityPlugin.instance?.sendAction(action) }
  }
}
