import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:ping_app/auth/model/ping_user_model.dart';
import 'package:ping_app/auth/repo/auth_repo.dart';
import 'package:ping_app/auth/repo/ping_auth_state.dart';
import 'package:ping_app/auth/view/create_account_view.dart';
import 'package:ping_app/broadcast/view/broadcast_list_view.dart';
import 'package:ping_app/settings/view/linked_profile_view.dart';
import 'package:ping_app/settings/view/sub_view/activity_report.dart';
import 'package:ping_app/settings/view/sub_view/change_language_view.dart';
import 'package:ping_app/settings/view/sub_view/change_name_view.dart';
import 'package:ping_app/settings/view/sub_view/contact_support.dart';
import 'package:ping_app/settings/view/sub_view/message_template/message_template_list.dart';
import 'package:ping_app/settings/view/sub_view/update_password_view.dart';
import 'package:ping_app/util/ping_utils.dart';
import 'package:ping_app/view/subscription/purchased_view.dart';
import 'package:ping_app/view/subscription/subscription_info_view.dart';
import 'package:ping_app/util/dialogs.dart';
import 'package:ping_app/util/messenger.dart';
import 'package:ping_app/util/navigator.dart';
import 'package:ping_app/util/ping_heading_card.dart';
import 'package:ping_app/view/subscription/subscription_provider.dart';
import 'package:ping_app/view/voucher/voucher_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class SettingView extends StatefulWidget {
  const SettingView({super.key});

  @override
  State<SettingView> createState() => _SettingViewState();
}

class _SettingViewState extends State<SettingView> {
  late SubscriptionProvider subscriptionProvider;
  @override
  void initState() {
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) async {
      subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      // await subscriptionProvider.fetchSubscriptionDetails();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final pingUser = context.watch<PingAuthState>().currentPingUser;
    if (pingUser == null) {
      FirebaseAuth.instance.signOut();
      return getErrorMessage(context, 't_userIsLoggedIn'.tr());
    }
    return Scaffold(
      appBar: AppBar(title: Text('t_settings'.tr())),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              getUserCard(pingUser),
              const SizedBox(height: 24),
              PingHeadingCard(title: 't_messageTemplate'.tr()),
              ListTile(
                title: Text('t_allMessages'.tr()),
                leading: const Icon(Icons.message),
                onTap: () => push(const MessageListView()),
              ),
              ListTile(
                title: Text('t_broadcastGroups'.tr()),
                leading: const Icon(Icons.group),
                onTap: () => push(const BroadcastListView()),
              ),
              PingHeadingCard(title: 't_personalInformation'.tr()),
              ListTile(
                title: Text('t_changeYourName'.tr()),
                leading: const Icon(Icons.person),
                onTap: () => push(const ChangeNameView(mode: ChangeNameMode.fullName)),
              ),
              ListTile(
                title: Text('t_changeTeamName'.tr()),
                leading: const Icon(Icons.group),
                onTap: () => push(
                  const ChangeNameView(mode: ChangeNameMode.teamName),
                ),
              ),
              ListTile(
                title: Text('t_changePassword'.tr()),
                leading: const Icon(Icons.lock),
                onTap: () => push(const UpdatePasswordView()),
              ),
              ListTile(
                title: Text('t_linkedProfiles'.tr()),
                leading: const Icon(Icons.link),
                onTap: () => push(const LinkedProfilesScreen()),
              ),
              ListTile(
                title: Text('t_changeLanguage'.tr()),
                leading: const Icon(Icons.language),
                onTap: () async {
                  await push(const ChangeLanguageView());
                  setState(() {});
                },
              ),
              PingHeadingCard(title: 't_payments'.tr()),
              ListTile(
                title: Text('t_subscriptions'.tr()),
                leading: const Icon(Icons.payment),
                onTap: () {
                  if (subscriptionProvider.purchases.isEmpty) {
                    push(const SubscriptionInfoView());
                  } else {
                    push(const PurchasedView());
                  }
                },
              ),
              ListTile(
                title: Text('t_restorePurchase'.tr()),
                leading: const Icon(Icons.restore),
                onTap: () async {
                  try {
                    await subscriptionProvider.restorePurchases();
                    snack('t_purchasesRestored'.tr(), info: true);
                  } catch (e) {
                    snack(e);
                  }
                },
              ),
              ListTile(
                title: const Text('Voucher'),
                leading: const Icon(Icons.gif_box),
                onTap: () {
                  PingDialogs.showVoucherDialog(
                    context: context,
                    applyVoucher: () async {
                      await Provider.of<VoucherProvider>(context, listen: false).applyForVoucher(context);
                    },
                  );
                },
              ),
              ListTile(
                title: Text('t_generateActivityReport'.tr()),
                leading: const Icon(Icons.newspaper),
                onTap: () async {
                  final teamLead = context.read<PingAuthState>().currentPingUser;
                  if (teamLead == null) {
                    snack('t_teamLeadTheApp'.tr());
                    return;
                  }
                  push(ActivityReportProgress(teamLeadId: teamLead.userId));
                },
              ),
              PingHeadingCard(title: 't_help'.tr()),
              ListTile(
                title: Text('t_contactSupport'.tr()),
                leading: const Icon(Icons.help),
                onTap: () => push(const ContactSupport()),
              ),
              ListTile(
                title: const Text('Privacy Policy'),
                leading: const Icon(Icons.privacy_tip),
                onTap: () {
                  String url = "https://sites.google.com/view/pingsapp/privacy-policy";
                  context.launchURL(url);
                },
              ),
              ListTile(
                title: Text('t_shareApp'.tr()),
                leading: const Icon(Icons.share),
                onTap: () => Share.share(
                  "Download the ping app now!! https://www.pingapp.ch",
                ),
              ),
              ListTile(
                title: Text('t_logout'.tr()),
                leading: const Icon(Icons.logout),
                onTap: () async {
                  try {
                    replaceAll(const CreateAccountView());
                    await FirebaseAuth.instance.signOut();
                  } catch (e) {
                    snack(e);
                  }
                },
              ),
              ListTile(
                title: Text(
                  't_deleteAccount'.tr(),
                  style: const TextStyle(color: Colors.red),
                ),
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                onTap: () {
                  sureDialog(
                    context: context,
                    title: 't_deleteAccount'.tr(),
                    message: 't_areYouSameEmail'.tr(),
                    onYes: () async {
                      try {
                        replaceAll(const CreateAccountView());
                        await AuthRepo.instance.deleteUser(FirebaseAuth.instance.currentUser!.uid);
                        snack('t_accountDeletedSuccessfully'.tr());
                        FirebaseAuth.instance.signOut();
                      } catch (e) {
                        snack(e);
                      }
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget getUserCard(PingUserModel pingUser) {
    return Builder(
      builder: (context) => Align(
        alignment: Alignment.center,
        child: Column(
          children: [
            const CircleAvatar(radius: 32, child: Icon(Icons.person, size: 40)),
            const SizedBox(height: 8),
            Text(pingUser.fullName, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 4),
            Text(pingUser.email, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
