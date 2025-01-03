// import 'package:easy_localization/easy_localization.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:ping_app/util/messenger.dart';
// import 'package:ping_app/util/navigator.dart';
// import 'package:ping_app/util/ping_utils.dart';
// import 'package:ping_app/util/validator.dart';
//
// class UpdatePasswordView extends StatefulWidget {
//   const UpdatePasswordView({super.key});
//
//   @override
//   State<UpdatePasswordView> createState() => _UpdatePasswordViewState();
// }
//
// class _UpdatePasswordViewState extends State<UpdatePasswordView> {
//   final password = TextEditingController();
//   final confirmPassword = TextEditingController();
//   final formKey = GlobalKey<FormState>();
//
//   bool loading = false;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       key: const Key("viewUpdatePassword"),
//       appBar: AppBar(title: Text('t_updatePassword'.tr())),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Form(
//             key: formKey,
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 TextFormField(
//                   key: const Key("inputPassword"),
//                   decoration: InputDecoration(
//                     labelText: 't_password'.tr(),
//                     prefixIcon: Icon(Icons.lock),
//                   ),
//                   keyboardType: TextInputType.text,
//                   obscureText: true,
//                   textInputAction: TextInputAction.next,
//                   validator: passwordValidator,
//                   controller: password,
//                   readOnly: loading,
//                 ),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   key: const Key("inputConfirmPassword"),
//                   decoration: InputDecoration(
//                     labelText: 't_confirmPassword'.tr(),
//                     prefixIcon: Icon(Icons.lock_reset),
//                   ),
//                   obscureText: true,
//                   keyboardType: TextInputType.text,
//                   textInputAction: TextInputAction.done,
//                   validator: (value) {
//                     if (value != password.text) {
//                       return 't_passwordsDoNotMatch'.tr();
//                     }
//                     return null;
//                   },
//                   readOnly: loading,
//                 ),
//                 const SizedBox(height: 24),
//                 Builder(
//                   key: const Key("buttonUpdatePassword"),
//                   builder: (context) {
//                     return loading
//                         ? getLoader()
//                         : ElevatedButton(
//                             onPressed: () async {
//                               bool isInternet = await context.isInternetAvailable();
//                               if (isInternet) {
//                                 updatePassword();
//                               } else {
//                                 if (context.mounted) {
//                                   snack(context.pingString("t_noInternetPleaseConnectToTheInternet"));
//                                 }
//                               }
//                             },
//                             child: Text('t_updatePassword'.tr()),
//                           );
//                   },
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   void updatePassword() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) {
//       snack('t_userIsTheApp'.tr());
//       return;
//     }
//     final validated = formKey.currentState?.validate() ?? false;
//     if (!validated) {
//       return;
//     }
//
//     setState(() => loading = true);
//     try {
//       await user.updatePassword(password.text);
//       pop();
//       snack('t_passwordUpdatedSuccessfully'.tr(), info: true);
//     } catch (e) {
//       snack(e);
//     }
//     setState(() => loading = false);
//   }
// }
import 'package:flutter/material.dart';
import 'package:ping_app/util/messenger.dart';
import 'package:ping_app/view/update_password/update_password_provider.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

class UpdatePasswordView extends StatelessWidget {
  const UpdatePasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UpdatePasswordProvider(),
      child: Scaffold(
        key: const Key("viewUpdatePassword"),
        appBar: AppBar(title: Text('t_updatePassword'.tr())),
        body: SafeArea(
          child: Consumer<UpdatePasswordProvider>(
            builder: (context, provider, child) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: provider.formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        key: const Key("inputPassword"),
                        decoration: InputDecoration(
                          labelText: 't_password'.tr(),
                          prefixIcon: const Icon(Icons.lock),
                        ),
                        keyboardType: TextInputType.text,
                        obscureText: true,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 't_invalidPassword'.tr();
                          }
                          return null;
                        },
                        controller: provider.password,
                        readOnly: provider.loading,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key("inputConfirmPassword"),
                        decoration: InputDecoration(
                          labelText: 't_confirmPassword'.tr(),
                          prefixIcon: const Icon(Icons.lock_reset),
                        ),
                        obscureText: true,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.done,
                        validator: (value) {
                          if (value != provider.password.text) {
                            return 't_passwordsDoNotMatch'.tr();
                          }
                          return null;
                        },
                        controller: provider.confirmPassword,
                        readOnly: provider.loading,
                      ),
                      const SizedBox(height: 24),
                      provider.loading
                          ? getLoader()
                          : ElevatedButton(
                              onPressed: () async {
                                provider.updatePassword(context);
                              },
                              child: Text('t_updatePassword'.tr()),
                            ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
