import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

// ---------------------------------------------------------
// Notification model
// ---------------------------------------------------------

class CapturedNotification {
  final String packageName;
  final String tag;
  final String title;
  final String text;
  final String bigText;
  final int timestamp;

  CapturedNotification({
    required this.packageName,
    required this.tag,
    required this.title,
    required this.text,
    required this.bigText,
    required this.timestamp,
  });

  factory CapturedNotification.fromMap(Map<dynamic, dynamic> map) {
    return CapturedNotification(
      packageName: map['packageName']?.toString() ?? '',
      tag: map['tag']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      text: map['text']?.toString() ?? '',
      bigText: map['bigText']?.toString() ?? '',
      timestamp: map['timestamp'] is int
          ? map['timestamp'] as int
          : int.tryParse(map['timestamp']?.toString() ?? '') ?? 0,
    );
  }

  String get content {
    if (bigText.isNotEmpty) {
      return bigText;
    }

    return text;
  }

  DateTime get dateTime {
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }
}

// ---------------------------------------------------------
// App
// ---------------------------------------------------------

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Notification Capturer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const NotificationCaptureUI(),
    );
  }
}

// ---------------------------------------------------------
// UI
// ---------------------------------------------------------

class NotificationCaptureUI extends StatefulWidget {
  const NotificationCaptureUI({super.key});

  @override
  State<NotificationCaptureUI> createState() => _NotificationCaptureUIState();
}

class _NotificationCaptureUIState extends State<NotificationCaptureUI> {
  static const MethodChannel _methods = MethodChannel(
    'com.example.background_notif/methods',
  );

  static const EventChannel _events = EventChannel(
    'com.example.background_notif/events',
  );

  StreamSubscription? _notificationSubscription;

  List<CapturedNotification> notifications = [];

  bool isListening = false;

  @override
  void initState() {
    super.initState();

    _loadSavedNotifications();
    _startListening();
  }

  // -------------------------------------------------------
  // Load notifications captured while Flutter was closed
  // -------------------------------------------------------

  Future<void> _loadSavedNotifications() async {
    try {
      final result = await _methods.invokeMethod<List<dynamic>>(
        'getSavedNotifications',
      );

      if (result == null) {
        return;
      }

      final loaded = result
          .map(
            (item) =>
                CapturedNotification.fromMap(item as Map<dynamic, dynamic>),
          )
          .toList();

      if (!mounted) {
        return;
      }

      setState(() {
        notifications = loaded;
      });
    } catch (e) {
      debugPrint('Failed to load notifications: $e');
    }
  }

  // -------------------------------------------------------
  // Receive live notifications from Kotlin
  // -------------------------------------------------------

  void _startListening() {
    _notificationSubscription = _events.receiveBroadcastStream().listen(
      (event) {
        try {
          final notification = CapturedNotification.fromMap(
            event as Map<dynamic, dynamic>,
          );

          if (!mounted) {
            return;
          }

          setState(() {
            notifications.insert(0, notification);
          });
        } catch (e) {
          debugPrint('Invalid notification event: $e');
        }
      },
      onError: (error) {
        debugPrint('Notification stream error: $error');
      },
    );

    setState(() {
      isListening = true;
    });
  }

  // -------------------------------------------------------
  // Open Android Notification Access settings
  // -------------------------------------------------------

  Future<void> _openNotificationSettings() async {
    try {
      await _methods.invokeMethod('openNotificationSettings');
    } catch (e) {
      debugPrint('Failed to open settings: $e');
    }
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  // -------------------------------------------------------
  // UI
  // -------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Capturer'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadSavedNotifications,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: Column(
        children: [
          // -------------------------------------------------
          // Status / controls
          // -------------------------------------------------

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      isListening ? Icons.check_circle : Icons.warning,
                      color: isListening ? Colors.green : Colors.orange,
                    ),

                    const SizedBox(width: 8),

                    Text(
                      isListening
                          ? 'Listening for notifications'
                          : 'Not listening',
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _openNotificationSettings,
                    icon: const Icon(Icons.settings),
                    label: const Text('Enable Notification Listener'),
                  ),
                ),

                const SizedBox(height: 8),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${notifications.length} captured notifications',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // -------------------------------------------------
          // Notifications
          // -------------------------------------------------
          Expanded(
            child: notifications.isEmpty
                ? const Center(child: Text('No notifications captured yet.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];

                      if (notification.title == "Chat heads active" ||
                          notification.title == "" ||
                          notification.packageName == "android") {
                        return Container();
                      }
                      return GestureDetector(
                        onTap: () {
                          print(notification.packageName);
                        },
                        child: _NotificationCard(notification: notification),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// Notification card
// ---------------------------------------------------------

class _NotificationCard extends StatelessWidget {
  final CapturedNotification notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    final content = notification.content;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App package
            Row(
              children: [
                const Icon(Icons.notifications, size: 20),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    notification.packageName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Title
            if (notification.title.isNotEmpty)
              Text(
                notification.title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),

            // Content
            if (content.isNotEmpty) ...[
              const SizedBox(height: 5),

              Text(content, style: const TextStyle(fontSize: 15)),
            ],

            const SizedBox(height: 8),

            // Timestamp
            Text(
              notification.dateTime.toLocal().toString(),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
