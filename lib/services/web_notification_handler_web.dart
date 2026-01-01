import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:web/web.dart' as web;

void showWebNotification(RemoteNotification notification) {
  // Correct check for browser notification permission
  if (web.Notification.permission == 'granted') {
    web.Notification(
      notification.title ?? 'New Notification',
      web.NotificationOptions(
        body: notification.body ?? '',
        icon: '/icons/Icon-192.png', // PWA Icon
      ),
    );
  } else if (web.Notification.permission != 'denied') {
    // Request permission if not already handled
    web.Notification.requestPermission();
  }
}
