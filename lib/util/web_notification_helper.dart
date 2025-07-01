import 'package:firebase_messaging/firebase_messaging.dart';
import 'web_notification_stub.dart'
if (dart.library.html) 'web_notification_web.dart';

void setupWebNotificationListener(dynamic notification) {
  setupWebNotificationListenerImpl(notification);
}

void clearUrlQueryParams(){
  clearUrlQueryParamsImpl();
}