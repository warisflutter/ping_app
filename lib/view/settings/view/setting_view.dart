import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/auth/model/ping_user_model.dart';
import 'package:ping_app/auth/repo/auth_repo.dart';
import 'package:ping_app/auth/repo/ping_auth_state.dart';
import 'package:ping_app/auth/view/create_account_view.dart';
import 'package:ping_app/broadcast/view/broadcast_list_view.dart';
import 'package:ping_app/services/notification_service.dart';
import 'package:ping_app/util/messenger.dart';
import 'package:ping_app/util/navigator.dart';
import 'package:ping_app/util/ping_styles.dart';
import 'package:ping_app/util/ping_utils.dart';
import 'package:ping_app/view/admin/admin_provider.dart';
import 'package:ping_app/view/settings/view/change_language/change_language_view.dart';
import 'package:ping_app/view/settings/view/linked_profile_view.dart';
import 'package:ping_app/view/settings/view/sub_view/activity_report.dart';
import 'package:ping_app/view/settings/view/sub_view/change_name_view.dart';
import 'package:ping_app/view/settings/view/sub_view/contact_support.dart';
import 'package:ping_app/view/settings/view/sub_view/message_template/message_template_list.dart';
import 'package:ping_app/view/subscription/purchased_view.dart';
import 'package:ping_app/view/subscription/subscription_info_view.dart';
import 'package:ping_app/view/subscription/subscription_provider.dart';
import 'package:ping_app/view/update_password/update_password_view.dart';
import 'package:ping_app/view/voucher/voucher_view.dart';
import 'package:ping_app/widgets/base_widget.dart';
import 'package:ping_app/widgets/ping_list_tile.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../widgets/numeric_list_tile.dart';

class SettingView extends StatefulWidget {
  const SettingView({super.key});

  @override
  State<SettingView> createState() => _SettingViewState();
}

class _SettingViewState extends State<SettingView> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pingUser = context.watch<PingAuthState>().currentPingUser;
    if (pingUser == null) {
      return getErrorMessage(context, "");
    }
    // controller.text = pingUser.dialogTimer.toString();
    return BaseWidget(
      showBackIcon: false,
      title: Text(
        "t_settings".tr(),
        style: (context.isWatch) ? PingStyles.watchStyle : null,
      ),
      body: Consumer<SubscriptionProvider>(builder: (context, subscriptionProvider, widget) {
        return SingleChildScrollView(
          child: LayoutBuilder(builder: (context, constraints) {
            double maxWidth = constraints.maxWidth > 800 ? 200.0 : 16.0;
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: (kIsWeb) ? maxWidth : 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  getUserCard(pingUser),
                  SizedBox(height: (context.isWatch) ? 8.0 : 24),
                  PingListTile(title: 't_messageTemplate'.tr()),
                  PingListTile(
                    title: 't_allMessages'.tr(),
                    iconData: Icons.message,
                    onTap: () => push(const MessageListView()),
                  ),
                  PingListTile(
                    title: 't_broadcastGroups'.tr(),
                    iconData: Icons.group,
                    onTap: () => push(const BroadcastListView()),
                  ),
                  PingListTile(title: 't_personalInformation'.tr()),
                  PingListTile(
                    title: 't_changeYourName'.tr(),
                    iconData: Icons.person,
                    onTap: () => push(const ChangeNameView(mode: ChangeNameMode.fullName)),
                  ),
                  PingListTile(
                    title: 't_changeTeamName'.tr(),
                    iconData: Icons.group,
                    onTap: () => push(const ChangeNameView(mode: ChangeNameMode.teamName)),
                  ),
                  PingListTile(
                    title: 't_changePassword'.tr(),
                    iconData: Icons.lock,
                    onTap: () => push(const UpdatePasswordView()),
                  ),
                  PingListTile(
                    title: 't_linkedProfiles'.tr(),
                    iconData: Icons.link,
                    onTap: () => push(const LinkedProfilesScreen()),
                  ),
                  PingListTile(
                    title: 't_changeLanguage'.tr(),
                    iconData: Icons.language,
                    onTap: () async {
                      await push(const ChangeLanguageView());
                      setState(() {});
                    },
                  ),
                  PingListTile(title: 't_payments'.tr()),
                  PingListTile(
                    title: 't_subscriptions'.tr(),
                    iconData: Icons.payment,
                    onTap: () {
                      if (kIsWeb || context.isWatch) {
                        snack(
                          "t_Checkoutthemobileversiontoviewyoursubscriptiondetails".tr(),
                          backgroundColor: Colors.green,
                        );
                        return;
                      }
                      if (subscriptionProvider.purchases.isEmpty) {
                        push(const SubscriptionInfoView());
                      } else {
                        push(const PurchasedView());
                      }
                    },
                  ),
                  PingListTile(
                    title: 't_restorePurchase'.tr(),
                    iconData: Icons.restore,
                    onTap: () async {
                      try {
                        if (kIsWeb || context.isWatch) {
                          snack(
                            "t_CheckoutTheMobileVersionToRestorePurchase".tr(),
                            backgroundColor: Colors.green,
                          );
                          return;
                        }
                        await subscriptionProvider.restorePurchases();
                        snack('t_purchasesRestored'.tr(), info: true);
                      } catch (e) {
                        snack(e);
                      }
                    },
                  ),
                  PingListTile(
                    title: 't_voucher'.tr(),
                    iconData: Icons.gif_box,
                    onTap: () async {
                      if (kIsWeb || context.isWatch) {
                        snack(
                          "${"t_CheckOutTheMobileVersionToView".tr()} ${'t_voucher'.tr()}",
                          backgroundColor: Colors.green,
                        );
                        return;
                      }
                      final adminP = Provider.of<AdminProvider>(context, listen: false);
                      final voucherData = await adminP.fetchVoucher();
                      debugPrint("voucherData $voucherData");
                      if (voucherData.isEmpty || voucherData == "Voucher is Expire|Pro") {
                        push(const VoucherView());
                      } else {
                        adminP.startCountDown();
                        push(const PurchasedView());
                      }
                    },
                  ),
                  PingListTile(
                    title: 't_generateActivityReport'.tr(),
                    iconData: Icons.newspaper,
                    onTap: () async {
                      final teamLead = context.read<PingAuthState>().currentPingUser;
                      if (teamLead == null) {
                        snack('t_teamLeadTheApp'.tr());
                        return;
                      }
                      push(ActivityReportProgress(teamLeadId: teamLead.userId));
                    },
                  ),
                  PingListTile(title: 't_appSettings'.tr()),
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(pingUser.userId).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const LinearProgressIndicator();

                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    final dialogTimer = data['dialogTimer'] ?? 0;
                    controller.text = dialogTimer.toString();
                    return NumericListTile(
                      title: "Dialog Timer",
                      controller: controller,
                      uid: pingUser.userId,
                      iconData: Icons.timer,
                      iconColor: Colors.white,
                    );
                  },
                ),
                  // NumericListTile(title: 't_dialogTimer'.tr(), iconData: Icons.access_alarm, controller: controller, uid: pingUser.userId,),
                  PingListTile(title: 't_help'.tr()),
                  PingListTile(
                    title: 't_contactSupport'.tr(),
                    iconData: Icons.help,
                    onTap: () => push(const ContactSupport()),
                  ),
                  PingListTile(
                    title: 't_privacyPolicy'.tr(),
                    iconData: Icons.privacy_tip,
                    onTap: () {
                      String url = "https://sites.google.com/view/pingsapp/privacy-policy";
                      context.launchURL(url);
                    },
                  ),
                  PingListTile(
                    title: 't_shareApp'.tr(),
                    iconData: Icons.share,
                    onTap: () => Share.share(
                      "${"t_DownloadThePingAppNow".tr()}!! https://www.pingapp.ch",
                    ),
                  ),
                  PingListTile(
                    title: 't_logout'.tr(),
                    iconData: Icons.logout,
                    onTap: () async {
                      try {
                        final isConnected = await context.isInternetAvailable();
                        if (!isConnected) {
                          snack("t_noInternetPleaseConnectToTheInternet".tr());
                          return;
                        }

                        String uid = FirebaseAuth.instance.currentUser?.uid ?? "";
                        String? fcmToken = await FirebaseMessaging.instance.getToken();

                        if (fcmToken != null) {
                          FirebaseNotificationService().removeToken(
                            fcmToken: fcmToken,
                            uid: uid,
                            collectionName: "users",
                          );
                        }
                        replaceAll(const CreateAccountView());
                        await FirebaseAuth.instance.signOut();
                      } catch (e) {
                        snack(e.toString());
                      }
                    },
                  ),
                  PingListTile(
                    title: 't_deleteAccount'.tr(),
                    iconData: Icons.delete_outline,
                    onTap: () {
                      sureDialog(
                        context: context,
                        title: 't_deleteAccount'.tr(),
                        message: 't_areYouSameEmail'.tr(),
                        onYes: () async {
                          try {
                            final isConnected = await context.isInternetAvailable();
                            if (isConnected) {
                              replaceAll(const CreateAccountView());
                              await AuthRepo.instance.deleteUser();
                              snack('t_accountDeletedSuccessfully'.tr());
                            } else {
                              snack("t_noInternetPleaseConnectToTheInternet".tr());
                            }
                          } catch (e) {
                            snack(e);
                          }
                        },
                      );
                    },
                  ),
                ],
              ),
            );
          }),
        );
      }),
    );
  }

  Widget getUserCard(PingUserModel pingUser) {
    return Builder(
      builder: (context) => Align(
        alignment: Alignment.center,
        child: Column(
          children: [
            CircleAvatar(
              radius: (context.isWatch) ? PingStyles.watchIconSize : 32,
              child: Icon(
                Icons.person,
                size: (context.isWatch) ? PingStyles.watchIconSize : 40,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              pingUser.fullName,
              style: (context.isWatch) ? PingStyles.watchStyle : Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 4),
            Text(
              pingUser.email,
              style: (context.isWatch) ? PingStyles.watchStyle : Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
