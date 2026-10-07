# 📱 Capturing Notifications

> Capture & monitor notifications from any Android app — **even when the app is closed or not running.**

---

## ✨ Features

- 🔄 **Background Capture** — Listen to notifications even when the Flutter app is closed
- 🎯 **Universal Support** — Works with WhatsApp, Telegram, Instagram, Gmail, and any app with notification access
- 💾 **Persistent Storage** — Notifications are saved as JSON files for later retrieval
- ⚡ **Real-time Streaming** — Live notification events pushed to Flutter via EventChannel
- 🔒 **Privacy-Focused** — No data is sent to any server; everything runs locally on your device

---

## 🚀 How It Works

### Architecture

This app uses Android's `NotificationListenerService` — a system-level service that grants your app permission to read notifications posted by other applications.

```
┌─────────────────────────────────────────────────────────────┐
│                    Android System                              │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  Notification Listener Service                           │ │
│  │  ┌─────────────────────────────────────────────────────┐ │ │
│  │  │  NotificationListenerService.kt                      │ │ │
│  │  │  - onNotificationPosted(sbn: StatusBarNotification) │ │ │
│  │  │  - onNotificationRemoved(sbn: StatusBarNotification)│ │ │
│  │  └─────────────────────────────────────────────────────┘ │ │
│  │                                                           │ │
│  │  📂 Saved directory: /data/data/.../files/notifications/ │ │
│  │     └── 20261007_133245_WhatsApp.json                   │ │
│  │     └── 20261007_133247_Telegram.json                   │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                          │
                          │ EventChannel
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                     Flutter App                                │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  lib/main.dart                                           │ │
│  │  - MethodChannel → getSavedNotifications()              │ │
│  │  - EventChannel  → receiveBroadcastStream()             │ │
│  │  - UI: List of CapturedNotification cards                │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

---

## 🧩 Core Components

### `NotificationListenerService.kt`

The heart of the app. This class extends Android's `NotificationListenerService` and overrides:

| Method | Purpose |
|--------|---------|
| `onListenerConnected()` | Called when the user grants notification access permission |
| `onNotificationPosted()` | Triggered whenever a new notification is posted to the status bar |
| `onNotificationRemoved()` | Triggered when a notification is cleared from the status bar |

**Key Logic:**

```kotlin
override fun onNotificationPosted(sbn: StatusBarNotification) {
    // Extract notification data
    val packageName = sbn.packageName
    val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
    val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
    val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString() ?: ""
    val timestamp = sbn.postTime

    // Save to disk as JSON
    saveNotification(data)

    // Push event to Flutter immediately
    eventSink?.success(mapOf("packageName" to packageName, ...))
}
```

### `MainActivity.kt`

Bridges Kotlin and Flutter using two channels:

| Channel | Purpose |
|---------|---------|
| `MethodChannel` | `openNotificationSettings` → opens Android settings<br>`getSavedNotifications` → fetches persisted JSON files |
| `EventChannel` | Listens for real-time notification events from `NotificationListenerService` |

---

## 🛠️ Setup & Usage

### 1. Open Notification Access Settings

> **⚠️ Important:** The app **cannot** read notifications by itself. You must grant permission manually.

1. Launch the Flutter app
2. Tap the **"Enable Notification Listener"** button
3. On Android, go to: **Settings → Apps → Special Access → Notification Access**
4. Find **"background_notif"** and enable it
5. Allow the app to read notifications

### 2. Start Capturing

Once permission is granted:

- All new notifications will appear **instantly** in the UI
- Notifications are **saved to disk** as JSON files in `/data/data/com.example.background_notif/files/notifications/`
- Even if you close the Flutter app, notifications continue to be saved to disk
- Reopen the app → tap the **Refresh** icon → previously saved notifications load

### 3. View Notifications

The UI displays:

- App name (package name)
- Title
- Content text (or big text if available)
- Timestamp

---

## 📁 Data Format

Each saved notification is stored as a JSON file:

```json
{
  "packageName": "com.whatsapp",
  "tag": "5332114068_WhatsApp",
  "title": "Yassine",
  "text": "Hello, how are you?",
  "bigText": "Hello, how are you?\n\nI hope you're doing great! Let's catch up soon. 🌟",
  "timestamp": 1757249567123
}
```

---

## 📂 Project Structure

```
background_notif/
├── android/
│   └── app/
│       └── src/
│           └── main/
│               ├── AndroidManifest.xml
│               └── java/com/example/background_notif/
│                   ├── MainActivity.kt          ← MethodChannel + EventChannel bridge
│                   └── NotificationListenerService.kt ← Core notification capture logic
├── lib/
│   └── main.dart                                ← Flutter UI + data models
└── README.md
```

---

## 🧪 Testing

```bash
cd /home/yassine/Desktop/Coding/Apps/background_notif
flutter pub get
flutter run
```

### Test Steps

1. Open the app
2. Tap **"Enable Notification Listener"**
3. Enable in Android settings
4. Send a notification from any app (WhatsApp, Telegram, etc.)
5. Verify it appears in the UI instantly

---

## 🎯 Use Cases

| Use Case | Description |
|----------|-------------|
| **Notification Dashboard** | Centralized view of all your notifications |
| **Missed Notifications** | View notifications you missed while the app was closed |
| **Notification Analytics** | Track which apps send you the most notifications |
| **Backup** | Export notifications to a file for backup purposes |

---

## ⚠️ Permissions

This app requires **Notification Access** permission — a special Android permission granted per-app in system settings.

**No other permissions are needed.** The app does not:

- Access your location
- Access contacts
- Access camera or microphone
- Send any data to external servers

---

## 🤝 License

MIT License — feel free to use, modify, and distribute.

---

## 📬 Credits

- Built with [Flutter](https://flutter.dev)
- Uses Android's built-in `NotificationListenerService` API
