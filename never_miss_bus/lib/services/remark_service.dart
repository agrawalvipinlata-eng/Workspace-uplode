import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/result.dart';

class RemarkService {
  RemarkService(this._db);

  final FirebaseFirestore _db;

  static const List<String> categories = <String>[
    'Homework',
    'Achievement',
    'Class Test',
    'Behaviour',
  ];

  Stream<List<Map<String, dynamic>>> watchForStudent(String uid) => _db
      .collection('remarks')
      .where('studentUid', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((QuerySnapshot<Map<String, dynamic>> snap) => snap.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> d) =>
              <String, dynamic>{
                'id': d.id,
                ...d.data(),
              })
          .toList());

  Future<Result<void>> add({
    required String studentUid,
    required String classSection,
    required String teacherUid,
    required String category,
    required String text,
  }) async {
    if (!categories.contains(category)) {
      return const Err<void>(
          AppFailure('invalid-category', 'Invalid remark category.'));
    }
    if (text.trim().length < 2 || text.trim().length > 300) {
      return const Err<void>(
          AppFailure('invalid-remark', 'Remark must be 2–300 characters.'));
    }
    try {
      await _db.collection('remarks').add(<String, dynamic>{
        'studentUid': studentUid,
        'classSection': classSection,
        'teacherUid': teacherUid,
        'category': category,
        'text': text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      return const Ok<void>(null);
    } on FirebaseException catch (e) {
      return Err<void>(e.code == 'permission-denied'
          ? AppFailure.permissionDenied
          : AppFailure.unknown);
    }
  }
}
