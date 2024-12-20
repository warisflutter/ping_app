import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/dashboard/member_dashboard.dart';
import 'package:ping_app/member/repo/member_state.dart';
import 'package:ping_app/member/view/join_member_view/join_id_view.dart';
import 'package:ping_app/util/messenger.dart';
import 'package:ping_app/util/navigator.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class JoinQrView extends StatefulWidget {
  const JoinQrView({super.key});

  @override
  State<JoinQrView> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<JoinQrView> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;

  bool loading = false;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    } else if (Platform.isIOS) {
      controller!.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('t_joinByQr'.tr())),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  QRView(key: qrKey, onQRViewCreated: _onQRViewCreated),
                  if (loading) getLoader(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () => replace(const JoinIdView()),
                child: Text('t_joinById'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      final data = scanData.code;
      if (data != null) {
        actionJoinByQr(data);
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void actionJoinByQr(String memberId) async {
    if (loading || memberId.isEmpty) {
      return;
    }

    final memberState = context.read<MemberState>();
    setState(() => loading = true);
    try {
      await memberState.setMemberId(memberId);
      replaceAll(const MemberDashboard());
    } catch (e) {
      setState(() => loading = false);
      snack(e);
    }
  }
}
