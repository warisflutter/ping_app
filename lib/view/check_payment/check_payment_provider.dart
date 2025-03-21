import 'package:flutter/cupertino.dart';

class CheckPaymentProvider extends ChangeNotifier {
  String message = "";
  void updateMessage(String data) {
    message = data;
    notifyListeners();
  }
}
