import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BroadcastModel {
  static const String idKey = 'id';
  static const String nameKey = 'name';
  static const String teamLeadIdKey = 'teamLeadId';
  static const String createdAtKey = 'createdAt';
  static const String memberIdsKey = 'memberIds';

  final String id;
  final String name;
  final String teamLeadId;
  final DateTime? _createdAt;
  final List<String> memberIds;

  BroadcastModel({
    required this.name,
    required this.teamLeadId,
  })  : id = "",
        memberIds = [],
        _createdAt = null;

  DateTime get createdAt => _createdAt ?? DateTime.now();

  BroadcastModel.fromJson(this.id, Map<String, dynamic> json)
      : name = json[nameKey] as String,
        teamLeadId = json[teamLeadIdKey] as String,
        _createdAt = (json[createdAtKey] as Timestamp?)?.toDate() ?? DateTime.now(),
        memberIds = List<String>.from(json[memberIdsKey] as List);

  Map<String, dynamic> toJson() => {
        nameKey: name,
        teamLeadIdKey: teamLeadId,
        createdAtKey: _createdAt ?? FieldValue.serverTimestamp(),
        memberIdsKey: memberIds,
      };
}

class BroadcastRepository {
  static final BroadcastRepository instance = BroadcastRepository._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'broadcasts';

  BroadcastRepository._internal();

  // Add a new broadcast
  Future<String> addBroadcast(String name) async {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    final broadcast = BroadcastModel(
      name: name,
      teamLeadId: uid,
    );
    DocumentReference docRef = await _firestore.collection(_collection).add(broadcast.toJson());
    return docRef.id;
  }

  // Add memberId to broadcast
  Future<void> addMemberToBroadcast(String broadcastId, String memberId) async {
    await _firestore.collection(_collection).doc(broadcastId).update({
      BroadcastModel.memberIdsKey: FieldValue.arrayUnion([memberId]),
    });
  }

  Future<void> removeMemberFromBroadcast(
    String broadcastId,
    String memberId,
  ) async {
    await _firestore.collection(_collection).doc(broadcastId).update({
      BroadcastModel.memberIdsKey: FieldValue.arrayRemove([memberId]),
    });
  }

  // Stream broadcast model
  Stream<BroadcastModel> streamBroadcast(String broadcastId) {
    return _firestore.collection(_collection).doc(broadcastId).snapshots().map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return BroadcastModel.fromJson(doc.id, data);
    });
  }

  Future<void> updateBroadcastMembers(String broadcastId, List<String> memberIds) async {
    await _firestore.collection(_collection).doc(broadcastId).update({
      BroadcastModel.memberIdsKey: memberIds,
    });
  }

  // Update broadcast name
  Future<void> updateBroadcastName(String broadcastId, String newName) async {
    await _firestore.collection(_collection).doc(broadcastId).update({
      BroadcastModel.nameKey: newName,
    });
  }

  Stream<List<BroadcastModel>> getAllBroadcasts() {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    String teamLeadIdKey = BroadcastModel.teamLeadIdKey;
    return _firestore
        .collection(_collection)
        .where(teamLeadIdKey, isEqualTo: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => BroadcastModel.fromJson(doc.id, doc.data())).toList());
  }
}
