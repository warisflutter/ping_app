import 'dart:developer';
import 'package:flutter/foundation.dart';

class PingLog {
  static void pingLog(String text) {
    if (kDebugMode) {
      log("🔰 $text");
    }
  }
}
