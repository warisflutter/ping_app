import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/auth/repo/ping_auth_state.dart';
import 'package:ping_app/firebase_options.dart';
import 'package:ping_app/member/repo/member_state.dart';
import 'package:ping_app/notification/repo/notification_service.dart';
import 'package:ping_app/util/fcm_repo.dart';
import 'package:ping_app/util/loading_screen.dart';
import 'package:ping_app/util/messenger.dart';
import 'package:ping_app/util/navigator.dart';
import 'package:ping_app/util/ping_log.dart';
import 'package:ping_app/view/admin/admin_provider.dart';
import 'package:ping_app/view/admin/admin_view.dart';
import 'package:ping_app/view/subscription/subscription_provider.dart';
import 'package:ping_app/view/voucher/voucher_provider.dart';
import 'package:ping_app/watch_os/watch_repo.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FcmRepo.instance.initialise();
  final notification = FirebaseNotificationService();
  notification.forGroundMessage();
  FirebaseMessaging.onMessage.listen(
    (message) {
      notificationAlert(
        onTap: () {
          pop();
          notification.handleMessage(message);
        },
        context: navigatorKey.currentState!.context,
        title: message.notification?.title ?? "",
        message: message.notification?.body ?? "",
      );
    },
  );
  //when app ins background
  FirebaseMessaging.onMessageOpenedApp.listen(
    (event) {
      notification.handleMessage(event);
    },
  );
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();

  if (initialMessage != null) {
    notification.handleMessage(initialMessage);
  } else {
    PingLog.pingLog('No message data');
  }
  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('de'),
        Locale('fr'),
        Locale('es'),
        Locale('it'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: MultiProvider(providers: [
        ChangeNotifierProvider(create: (_) => PingAuthState(userStream: FirebaseAuth.instance.userChanges())),
        ChangeNotifierProvider(create: (_) => MemberState()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => VoucherProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
      ], child: const MyApp()),
    ),
  );
  WatchConnectivity.instance.setupMethodChannel();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
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
  }
}

/*
funzoftapple786@gmail.com
Fun112233
for admin
Ping123456
*/
