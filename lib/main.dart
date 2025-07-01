import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/file_path.dart';
import 'package:ping_app/util/helper_class.dart';
import 'package:ping_app/util/web_notification_helper.dart';
import 'package:ping_app/view/check_payment/check_payment_provider.dart';
import 'package:provider/provider.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

final ValueNotifier<RemoteMessage?> currentMessage = ValueNotifier(null);



// void setupWebNotificationListener(notification) {
//   if (kIsWeb) {
//     // Listen for messages from service worker
//     html.window.addEventListener('message', (event) {
//       final messageEvent = event as html.MessageEvent;
//       print('Received message from service worker: ${messageEvent.data}');
//
//       if (messageEvent.data != null && messageEvent.data is Map) {
//         final data = Map<String, dynamic>.from(messageEvent.data);
//
//         if (data['type'] == 'showDialogFromNotification') {
//           print('Processing notification click: ${data['data']}');
//
//           // Create RemoteMessage from the notification data
//           final notificationData = Map<String, String>.from(data['data'] ?? {});
//           final message = RemoteMessage(data: notificationData);
//
//           // Handle the message (this should show your dialog)
//           notification.handleMessage(message);
//         }
//       }
//     });
//
//     // Also listen for service worker messages (alternative approach)
//     if (html.window.navigator.serviceWorker != null) {
//       html.window.navigator.serviceWorker!.addEventListener('message', (event) {
//         final messageEvent = event as html.MessageEvent;
//         print('SW message: ${messageEvent.data}');
//
//         if (messageEvent.data != null && messageEvent.data is Map) {
//           final data = Map<String, dynamic>.from(messageEvent.data);
//
//           if (data['type'] == 'showDialogFromNotification') {
//             final notificationData = Map<String, String>.from(data['data'] ?? {});
//             final message = RemoteMessage(data: notificationData);
//             notification.handleMessage(message);
//           }
//         }
//       });
//     }
//   }
// }

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await EasyLocalization.ensureInitialized();
  // await initializeService();
  final notification = FirebaseNotificationService();
  setupWebNotificationListener(notification);
  // 1. Foreground
  FirebaseMessaging.onMessage.listen(
    (message) {
      notification.handleMessage(message, playSound: true);
    },
  );
  // 2. Background (app already open in memory)
  FirebaseMessaging.onMessageOpenedApp.listen(
    (event) {
      notification.handleMessage(event);
    },
  );
  // 3. Terminated (app was closed)
  FirebaseMessaging.instance.getInitialMessage().then((message) {
    if (message != null) {
      HelperClass.message = message;
    }
  });

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  if(!kIsWeb){
    try {
      WatchConnectivity.instance.setupMethodChannel();
    } catch (e) {
      PingLog.pingLog('WatchConnectivity setup failed: $e');
    }
  }

  if (kIsWeb) {
    final uri = Uri.base;
    print("Query Parameters: ${uri.queryParameters}");
    if (uri.queryParameters['showDialog'] == 'true') {
      final data = uri.queryParameters;

      final message = RemoteMessage(
        data: {
          'id': data['id'] ?? '',
          'fromId': data['fromId'] ?? '',
          'toId': data['toId'] ?? '',
          'type': data['type'] ?? '',
          'message': data['message'] ?? '',
          'body': data['body'] ?? ''
        },
      );

      HelperClass.message = message;
      clearUrlQueryParams();
    }
  }


  runApp(EasyLocalization(
    supportedLocales: const [Locale('en'), Locale('de'), Locale('fr'), Locale('es'), Locale('it')],
    path: 'assets/translations',
    fallbackLocale: const Locale('en'),
    child: MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PingAuthState(userStream: FirebaseAuth.instance.userChanges())),
        ChangeNotifierProvider(create: (_) => MemberState()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => VoucherProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => CheckPaymentProvider()),
      ],
      child: const MyApp(),
    ),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<RemoteMessage?>(
        valueListenable: currentMessage,
        builder: (context, v, c) {
          return MaterialApp(
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            debugShowCheckedModeBanner: false,
            scaffoldMessengerKey: scaffoldMessengerKey,
            navigatorKey: navigatorKey,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                brightness: Brightness.dark,
                seedColor: Colors.white,
              ),
              useMaterial3: true,
              inputDecorationTheme: const InputDecorationTheme(
                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(80)),
                ),
              ),
            ),
            home: const LoadingScreen(message: "Please wait..."),
          );
        });
  }
}

/*
for team lead
funzoftapple786@gmail.com
Ping112233
for admin
apptweak.hafiz@gmail.com
Ping123456
*/
// if (Platform.isAndroid) {
//   notificationAlert(
//     onTap: () {
//       pop();
//       notification.handleMessage(message);
//     },
//     context: navigatorKey.currentState!.context,
//     title: message.notification?.title ?? "",
//     message: message.notification?.body ?? "",
//   );
// }
