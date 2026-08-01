package com.example.moto_dash

import android.app.Notification
import android.app.PendingIntent
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

data class NavigationState(
    val title: String?,
    val text: String?,
    val subText: String?,
    val bigText: String?,
    val actions: MutableMap<String, PendingIntent>
)

class MapsNotificationListener : NotificationListenerService() {

    companion object {

        // Holds the latest Google Maps navigation state
        @Volatile
        var currentState: NavigationState? = null
    }

    private fun publishState(state: NavigationState?) {

        currentState = state

        if (state == null) {
            NavigationEventHandler.send(null)
            return
        }

        NavigationEventHandler.send(
            mapOf(
                "title" to state.title,
                "text" to state.text,
                "subText" to state.subText,
                "bigText" to state.bigText,
                "actions" to state.actions.keys.toList()
            )
        )
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {

        if (sbn.packageName != "com.google.android.apps.maps") return

        Log.d("MotoDash", "Google Maps notification received")

        val notification = sbn.notification
        val extras = notification.extras
        val actions = mutableMapOf<String, PendingIntent>()

        notification.actions?.forEach { action ->
            Log.d("MotoDash", "Action = ${action.title}")
            actions[action.title.toString()] = action.actionIntent
        }

        publishState(NavigationState(
                title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString(),
                text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString(),
                subText = extras.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString(),
                bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString(),
                actions = actions
        ))

        Log.d("MotoDash", "Navigation state updated")
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) {

        if (sbn.packageName != "com.google.android.apps.maps")
            return

        Log.d("MotoDash", "Navigation ended")
        publishState(null)
    }
}