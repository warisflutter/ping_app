import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ping_app/util/loading_screen.dart';
import 'package:ping_app/dashboard/dashboard_view.dart';
import 'package:ping_app/auth/repo/ping_auth_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ping_app/auth/view/verify_email_view.dart';
import 'package:ping_app/auth/view/create_account_view.dart';
import 'package:ping_app/auth/repo/app_lifecycle_service.dart';
import 'package:ping_app/auth/view/complete_profile_view.dart';
import 'package:ping_app/auth/view/verify_subscription_view.dart';
import 'package:ping_app/subscription/model/subscription_model.dart';
import 'package:ping_app/subscription/view/subscription_pay_wall.dart';
import 'package:ping_app/firebase_options.dart';
import 'package:ping_app/member/repo/member_state.dart';
import 'package:ping_app/dashboard/member_dashboard.dart';
import 'package:ping_app/notification/repo/notification_service.dart';
import 'package:ping_app/subscription/repo/subscription_state.dart';
import 'package:ping_app/util/fcm_repo.dart';
import 'package:ping_app/util/messenger.dart';
import 'package:ping_app/util/navigator.dart';
import 'package:ping_app/watch_os/watch_repo.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FcmRepo.instance.initialise();
  WatchConnectivity.instance.setupMethodChannel();

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
        child: const MyApp()),
  );

  // runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              PingAuthState(userStream: FirebaseAuth.instance.userChanges()),
        ),
        ChangeNotifierProvider(create: (_) => MemberState()),
        ChangeNotifierProvider(create: (_) => SubscriptionState()),
      ],
      child: MaterialApp(
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
        home: Builder(builder: (context) {
          return PopScope(
            canPop: false,
            onPopInvoked: (didPop) {
              if (didPop) {
                return;
              }
              _onPopInvoked(context);
            },
            child: const HomeWidget(),
          );
        }),
      ),
    );
  }

  void _onPopInvoked(BuildContext context) async {
    final bool shouldPop = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('t_areYouSure'.tr()),
            content: Text('t_closingThisWorkProperly'.tr()),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('t_no'.tr()),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: Text('t_yes'.tr()),
              ),
            ],
          ),
        ) ??
        false;

    if (shouldPop) {
      SystemNavigator.pop(); // This will close the app
    }
  }
}

class HomeWidget extends StatelessWidget {
  const HomeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PingAuthState>();
    AppLifecycleService().reset();

    if (state.loading) {
      return LoadingScreen(message: 't_authenticating'.tr());
    }

    final pingUser = state.currentPingUser;
    final firebaseUser = state.currentFirebaseUser;

    if (firebaseUser != null && pingUser == null) {
      return CompleteProfileView(firebaseUser: firebaseUser);
    }

    if (firebaseUser == null || pingUser == null) {
      final memberState = context.watch<MemberState>();
      final member = memberState.member;
      if (member != null) {
        final subscriptionState = context.watch<SubscriptionState>();
        if (subscriptionState.error != null) {
          return LoadingScreen(
            message: 't_anErrorTheApp'.tr(),
            error: subscriptionState.error,
          );
        }

        if (subscriptionState.loading) {
          return LoadingScreen(
            message: 't_checkingSubscriptionPleaseWait'.tr(),
          );
        }
        NotificationService.instance.setNotificationListener(
          context,
          member.id,
          -1,
        );
        subscriptionState.updateUser(member.teamLeadId);
        FcmRepo.instance.updateMemberFcmToken(member.id);
        AppLifecycleService().initialize(isMember: true, userId: member.id);

        return const MemberDashboard();
      }
      return const CreateAccountView();
    }
    if (!firebaseUser.emailVerified) {
      return VerifyEmailView(user: firebaseUser);
    }

    final subscriptionState = context.watch<SubscriptionState>();
    if (subscriptionState.error != null) {
      return LoadingScreen(
        message: 't_anErrorTheApp'.tr(),
        error: subscriptionState.error,
      );
    }

    if (subscriptionState.loading) {
      return LoadingScreen(
        message: 't_checkingSubscriptionPleaseWait'.tr(),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      subscriptionState.updateUser(firebaseUser.uid);
    });

    if (subscriptionState.subscriptionType != EntitlementType.none) {
      NotificationService.instance
          .setNotificationListener(context, firebaseUser.uid, 1);
      FcmRepo.instance.updateTeamLeadFcmToken(firebaseUser.uid);
      AppLifecycleService().initialize(
        isMember: false,
        userId: firebaseUser.uid,
      );
      return const DashboardView();
    } else {
      if (kIsWeb) {
        return const VerifySubscriptionView();
      }
      return const SubscriptionPayWall();
    }
  }
}
