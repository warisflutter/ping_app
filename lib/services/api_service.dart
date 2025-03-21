import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:ping_app/util/navigator.dart';
import 'package:ping_app/util/ping_log.dart';
import 'package:ping_app/view/check_payment/check_payment_provider.dart';
import 'package:provider/provider.dart';

class ApiService {
  Future<bool> checkPayment() async {
    try {
      final url = Uri.parse("https://luxuriouschauffeur.suhaatech.com/api/check-payment");
      final response = await http.get(url);
      PingLog.pingLog("response: ${response.body}");
      final data = jsonDecode(response.body);
      if (data["message"].toString().trim().isNotEmpty) {
        PingLog.pingLog("message: ${data["message"]}");
        String message = data["message"];
        if (navigatorKey.currentState!.mounted) {
          Provider.of<CheckPaymentProvider>(
            navigatorKey.currentState!.context,
            listen: false,
          ).message = message;
        }
        return true;
      }
      return false;
    } catch (e) {
      PingLog.pingLog("Check Payment Api Error: $e");
      return false;
    }
  }
}
