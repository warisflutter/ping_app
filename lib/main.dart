import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:ping_app/file_path.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
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
  runApp(EasyLocalization(
    supportedLocales: const [Locale('en'), Locale('de'), Locale('fr'), Locale('es'), Locale('it')],
    path: 'assets/translations',
    fallbackLocale: const Locale('en'),
    child: MultiProvider(providers: [
      ChangeNotifierProvider(
          create: (_) => PingAuthState(userStream: FirebaseAuth.instance.userChanges())),
      ChangeNotifierProvider(create: (_) => MemberState()),
      ChangeNotifierProvider(create: (_) => AdminProvider()),
      ChangeNotifierProvider(create: (_) => VoucherProvider()),
      ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
    ], child: const MyApp()),
  ));
  WatchConnectivity.instance.setupMethodChannel();
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    PingLog.pingLog("MyApp initState");
    super.initState();
  }

  @override
  void dispose() {
    PingLog.pingLog("MyApp dispose");
    super.dispose();
  }

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
for team lead
funzoftapple786@gmail.com
Fun112233
for admin
apptweak.hafiz@gmail.com
Ping123456
*/
