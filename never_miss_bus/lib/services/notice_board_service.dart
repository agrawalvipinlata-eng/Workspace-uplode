import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/result.dart';

class NoticeBoardService {
  NoticeBoardService(this._db);
  final FirebaseFirestore _db;

  Stream<List<Map<String, dynamic>>> watchAll() => _db
          .collection('notices')
          .snapshots()
          .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
        final List<Map<String, dynamic>> notices = snapshot.docs
            .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                <String, dynamic>{'id': doc.id, ...doc.data()})
            .toList();
        notices.sort((Map<String, dynamic> a, Map<String, dynamic> b) =>
            '${b['createdAt'] ?? ''}'.compareTo('${a['createdAt'] ?? ''}'));
        return notices;
      });

  Stream<List<Map<String, dynamic>>> watchForClass(String classSection) => _db
      .collection('notices')
      .where('targetClass', whereIn: <String>[classSection, 'ALL'])
      .snapshots()
      .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
        final List<Map<String, dynamic>> notices = snapshot.docs
            .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                <String, dynamic>{'id': doc.id, ...doc.data()})
            .toList();
        notices.sort((Map<String, dynamic> a, Map<String, dynamic> b) =>
            '${b['createdAt'] ?? ''}'.compareTo('${a['createdAt'] ?? ''}'));
        return notices;
      });

  Future<Result<void>> publish({
    required String title,
    required String body,
    required String targetClass,
    required String createdBy,
  }) async {
    try {
      await _db.collection('notices').add(<String, dynamic>{
        'title': title.trim(),
        'body': body.trim(),
        'targetClass': targetClass,
        'createdBy': createdBy,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return const Ok<void>(null);
    } on FirebaseException catch (e) {
      return Err<void>(
          AppFailure(e.code, 'Notice publish failed: ${e.message}'));
    } catch (e) {
      return Err<void>(
          AppFailure('notice-publish', 'Notice publish failed: $e'));
    }
  }
}
