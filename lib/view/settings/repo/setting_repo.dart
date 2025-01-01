import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingRepo {
  static final SettingRepo instance = SettingRepo._internal();

  DocumentReference<Map<String, dynamic>> getMessageTemplateDoc(
          String userId) =>
      FirebaseFirestore.instance.collection('message_templates').doc(userId);

  String get currentUserId => FirebaseAuth.instance.currentUser?.uid ?? "all";

  SettingRepo._internal() {
    getMessageTemplateDoc(currentUserId).get().then((value) {
      if (!value.exists) {
        getMessageTemplateDoc(currentUserId).set({'messages': []});
      }
    });
  }

  Future<void> addMessage(String message) async {
    await getMessageTemplateDoc(currentUserId).update({
      'messages': FieldValue.arrayUnion([message])
    });
  }

  Future<void> updateMessage(String oldMessage, String newMessage) async {
    final snapshot = await getMessageTemplateDoc(currentUserId).get();
    final messages = snapshot.data()?['messages'] as List<dynamic>? ?? [];
    final index = messages.indexOf(oldMessage);
    if (index != -1) {
      messages[index] = newMessage;
      await getMessageTemplateDoc(currentUserId).update({'messages': messages});
    }
  }

  Future<void> removeMessage(String message) async {
    await getMessageTemplateDoc(currentUserId).update({
      'messages': FieldValue.arrayRemove([message])
    });
  }

  Future<void> reorderMessages(int oldIndex, int newIndex) async {
    final snapshot = await getMessageTemplateDoc(currentUserId).get();
    final messages = snapshot.data()?['messages'] as List<dynamic>? ?? [];
    final message = messages.removeAt(oldIndex);
    final fixedNewIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    messages.insert(fixedNewIndex, message);
    await getMessageTemplateDoc(currentUserId).update({'messages': messages});
  }

  Stream<List<String>> getMessages(String teamLeadId) {

    print("getting messages for $teamLeadId");
    return getMessageTemplateDoc(teamLeadId).snapshots().map((snapshot) =>
        (snapshot.data()?['messages'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        []);
  }

  Future<int> getMessageCount() async {
    final snapshot = await getMessageTemplateDoc(currentUserId).get();
    return (snapshot.data()?['messages'] as List<dynamic>? ?? []).length;
  }
}
