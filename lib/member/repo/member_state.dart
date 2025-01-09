import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:ping_app/auth/model/ping_user_model.dart';
import 'package:ping_app/auth/repo/auth_repo.dart';
import 'package:ping_app/member/model/member_model.dart';
import 'package:ping_app/member/repo/member_repo.dart';
import 'package:ping_app/util/ping_log.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemberState extends ChangeNotifier {
  static final instance = MemberState._();

  MemberState._();

  MemberModel? _memberModel;
  PingUserModel? _teamLead;

  StreamSubscription<PingUserModel?>? _teamLeadSubscription;

  List<String>? _idOrder;

  MemberModel? get member => _memberModel;

  PingUserModel? get teamLead => _teamLead;

  List<String>? get idOrder => _idOrder;

  void Function(MemberModel?)? onMemberChanged;

  @override
  void notifyListeners() {
    super.notifyListeners();
    if (onMemberChanged != null) {
      onMemberChanged!(_memberModel);
    }
  }

  int onlineMembers = 0;

  void initIdOrder() async {
    _idOrder = await MemberRepo.instance.getMemberOrder();
    notifyListeners();
  }

  void reorderIdOrder(List<String> nowIds, int oldIndex, int newIndex) {
    _idOrder = nowIds;
    final id = _idOrder!.removeAt(oldIndex);
    final fixedNewIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    _idOrder!.insert(fixedNewIndex, id);
    MemberRepo.instance.saveMemberOrder(_idOrder!);
    notifyListeners();
  }

  MemberState() {
    initIdOrder();
    loadMemberIdFromPrefs();
    fetchOnlineMembers();
  }

  Future<bool> loadMemberIdFromPrefs() async {
    Completer<bool> completer = Completer<bool>();
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString("memberId");
      PingLog.pingLog("id: $id");
      if (id != null) {
        final memberModel = await MemberRepo.instance.getMemberById(id);
        final pingUser = await AuthRepo.instance.getUserById(memberModel.teamLeadId);
        _memberModel = memberModel;
        debugPrint("This is member model:: $_memberModel");
        _teamLead = pingUser;
        final teamLeadId = _teamLead?.userId;
        if (teamLeadId != null) {
          listenToTeamLeadUpdates(teamLeadId);
        }
        completer.complete(true);
      } else {
        completer.complete(false);
      }
    } catch (e) {
      debugPrint("Error in loadMemberIdFromPrefs: $e");
      completer.complete(false);
    } finally {
      notifyListeners();
    }
    return completer.future;
  }

  void listenToTeamLeadUpdates(String teamLeadId) async {
    if (_teamLeadSubscription != null) {
      await _teamLeadSubscription!.cancel();
    }
    _teamLeadSubscription = AuthRepo.instance.getUserStreamById(teamLeadId).listen((pingUser) {
      _teamLead = pingUser;
      notifyListeners();
    });
  }

  Future<void> setMemberId(String memberId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("memberId", memberId);
    final memberModel = await MemberRepo.instance.getMemberById(memberId);
    final pingUser = await AuthRepo.instance.getUserById(memberModel.teamLeadId);
    _memberModel = memberModel;
    _teamLead = pingUser;
    notifyListeners();
  }

  Future<void> leaveTeam() async {
    final prefs = await SharedPreferences.getInstance();
    String id = prefs.getString("memberId") ?? "";
    changeMemberOnlineStatus(id: id, status: false);
    await prefs.remove("memberId");
    _memberModel = null;
    // loadMemberIdFromPrefs();
    notifyListeners();
  }

  @override
  void dispose() {
    if (_teamLeadSubscription != null) {
      _teamLeadSubscription!.cancel();
    }
    super.dispose();
  }

  Future<void> fetchOnlineMembers() async {
    String memberId = member?.id ?? "";
    final querySnapshot = await FirebaseFirestore.instance
        .collection("members")
        .where("teamLeadId", isEqualTo: teamLead?.userId ?? "")
        .where(
          "isOnline",
          isEqualTo: true,
        )
        .get();
    final data = querySnapshot.docs.map((e) => e.id != memberId).toList();
    int value = data.length;
    onlineMembers = value;
    PingLog.pingLog("online members: $value");
    notifyListeners();
  }
}

void changeMemberOnlineStatus({
  required String id,
  required bool status,
}) {
  FirebaseFirestore.instance.collection("members").doc(id).update({
    "isOnline": status,
    "fcm": "",
  });
}
