import 'package:shared_preferences/shared_preferences.dart';

class SPService {
  Future<String> getMemberId() async {
    final sp = await SharedPreferences.getInstance();
    String memberId = sp.getString("memberId") ?? "";
    return memberId;
  }
}
