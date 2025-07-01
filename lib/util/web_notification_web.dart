import 'dart:html' as html;
import 'package:firebase_messaging/firebase_messaging.dart';

void setupWebNotificationListenerImpl(dynamic notification) {
  // Listen for messages from service worker
  html.window.addEventListener('message', (event) {
    final messageEvent = event as html.MessageEvent;
    print('Received message from service worker: ${messageEvent.data}');

    if (messageEvent.data != null && messageEvent.data is Map) {
      final data = Map<String, dynamic>.from(messageEvent.data);

      if (data['type'] == 'showDialogFromNotification') {
        print('Processing notification click: ${data['data']}');

        // Create RemoteMessage from the notification data
        final notificationData = Map<String, String>.from(data['data'] ?? {});
        final message = RemoteMessage(data: notificationData);

        // Handle the message (this should show your dialog)
        notification.handleMessage(message);
      }
    }
  });

  // Also listen for service worker messages (alternative approach)
  if (html.window.navigator.serviceWorker != null) {
    html.window.navigator.serviceWorker!.addEventListener('message', (event) {
      final messageEvent = event as html.MessageEvent;
      print('SW message: ${messageEvent.data}');

      if (messageEvent.data != null && messageEvent.data is Map) {
        final data = Map<String, dynamic>.from(messageEvent.data);

        if (data['type'] == 'showDialogFromNotification') {
          final notificationData = Map<String, String>.from(data['data'] ?? {});
          final message = RemoteMessage(data: notificationData);
          notification.handleMessage(message);
        }
      }
    });
  }
}

void clearUrlQueryParamsImpl() {
  final uri = Uri.base;
  final cleanUri = uri.replace(query: '');

  // Use the browser's history API to remove the query parameters
  html.window.history.replaceState(null, '', cleanUri.toString());
}