import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:web/web.dart' as web;

void showWebNotification(RemoteNotification notification) {
  if (web.window.navigator.permissions != null) {
    web.Notification(
      notification.title ?? 'New Notification',
      web.NotificationOptions(body: notification.body ?? ''),
    );
  }
}
