import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/result.dart';

/// Daily diary and homework shared by teachers, students, and admins.
/// Class ownership is enforced again by Firestore rules; UI filtering is not
/// treated as security.
class SchoolworkService {
  SchoolworkService(this._db);

  final FirebaseFirestore _db;

  static String dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<Result<void>> submitDiary({
    required String teacherUid,
    required String classSection,
    required DateTime date,
    required String text,
  }) async {
    try {
      await _db.collection('diaries').doc('${classSection}_${dateKey(date)}').set(
        <String, dynamic>{
          'teacherUid': teacherUid,
          'classSection': classSection,
          'date': dateKey(date),
          'text': text.trim(),
          'submittedAt': FieldValue.serverTimestamp(),
        },
      ).timeout(const Duration(seconds: 10));
      return const Ok<void>(null);
    } on FirebaseException catch (e) {
      return Err<void>(AppFailure(
        e.code,
        e.code == 'permission-denied'
            ? 'Permission denied — class assignment or rules check karo.'
            : 'Diary save failed: ${e.message}',
      ));
    } catch (e) {
      return Err<void>(AppFailure('diary-save', 'Diary save failed: $e'));
    }
  }

  Stream<List<Map<String, dynamic>>> watchDiaries(String classSection) =>
      _db.collection('diaries')
          .where('classSection', isEqualTo: classSection)
          .snapshots()
          .map((QuerySnapshot<Map<String, dynamic>> q) => q.docs
              .map((QueryDocumentSnapshot<Map<String, dynamic>> d) =>
                  <String, dynamic>{'id': d.id, ...d.data()})
              .toList());

  Future<Result<void>> createHomework({
    required String teacherUid,
    required String classSection,
    required String subject,
    required DateTime date,
    required DateTime? deadline,
    required String description,
  }) async {
    try {
      await _db.collection('homework').add(<String, dynamic>{
        'teacherUid': teacherUid,
        'classSection': classSection,
        'subject': subject.trim(),
        'date': dateKey(date),
        'deadline': deadline == null ? null : dateKey(deadline),
        'description': description.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));
      return const Ok<void>(null);
    } on FirebaseException catch (e) {
      return Err<void>(AppFailure(
        e.code,
        e.code == 'permission-denied'
            ? 'Permission denied — class assignment or rules check karo.'
            : 'Homework save failed: ${e.message}',
      ));
    } catch (e) {
      return Err<void>(AppFailure('homework-save', 'Homework save failed: $e'));
    }
  }

  Stream<List<Map<String, dynamic>>> watchHomework(String classSection) =>
      _db.collection('homework')
          .where('classSection', isEqualTo: classSection)
          .snapshots()
          .map((QuerySnapshot<Map<String, dynamic>> q) {
        final List<Map<String, dynamic>> items = q.docs
            .map((QueryDocumentSnapshot<Map<String, dynamic>> d) =>
                <String, dynamic>{'id': d.id, ...d.data()})
            .toList();
        items.sort((Map<String, dynamic> a, Map<String, dynamic> b) =>
            '${b['date'] ?? ''}'.compareTo('${a['date'] ?? ''}'));
        return items;
      });
}
