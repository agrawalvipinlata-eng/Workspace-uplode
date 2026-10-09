import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/result.dart';

/// CLASS ATTENDANCE (teacher lagata hai, student dekhta hai).
///
/// Data model:
///   attendance/{classSection}_{yyyy-MM-dd} = {
///     classSection: '7-B', date: '2026-08-30',
///     takenBy: uid, takenAt: ts,
///     marks: { studentUid: true(present)/false(absent), ... }
///   }
/// Rules: teacher/admin apni class ka doc likh sakta hai; student sirf
/// woh docs padh sakta hai jisme uska uid marks me hai (apni class ke).
class AttendanceService {
  AttendanceService(this._db);

  final FirebaseFirestore _db;

  static String dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String docId(String classSection, DateTime d) =>
      '${classSection}_${dateKey(d)}';

  /// Aaj ki attendance load karo (edit ke liye) — null = abhi nahi lagi.
  Future<Map<String, bool>?> getForDate(
    String classSection,
    DateTime date,
  ) async {
    final DocumentSnapshot<Map<String, dynamic>> doc = await _db
        .collection('attendance')
        .doc(docId(classSection, date))
        .get()
        .timeout(const Duration(seconds: 10));
    final Map<String, dynamic>? marks =
        (doc.data()?['marks'] as Map?)?.cast<String, dynamic>();
    if (marks == null) return null;
    return marks.map(
      (String k, dynamic v) => MapEntry<String, bool>(k, v == true),
    );
  }

  /// Teacher: poori class ki attendance save (ek hi write).
  Future<Result<void>> save({
    required String classSection,
    required DateTime date,
    required Map<String, bool> marks,
    required String takenBy,
  }) async {
    try {
      await _db
          .collection('attendance')
          .doc(docId(classSection, date))
          .set(<String, dynamic>{
        'classSection': classSection,
        'date': dateKey(date),
        'takenBy': takenBy,
        'takenAt': FieldValue.serverTimestamp(),
        'marks': marks,
      }).timeout(const Duration(seconds: 10));
      return const Ok<void>(null);
    } on FirebaseException catch (e) {
      return Err<void>(AppFailure(
        e.code,
        e.code == 'permission-denied'
            ? 'Permission denied — rules deploy karo.'
            : 'Save failed: ${e.message}',
      ),);
    } catch (e) {
      return Err<void>(AppFailure('att-save', 'Save failed: $e'));
    }
  }

  /// Student: apna is mahine ka record (present/absent din).
  Future<({int present, int absent, Map<String, bool> days})> myMonth({
    required String classSection,
    required String uid,
    required DateTime month,
  }) async {
    // RULES-SAFE: har din ka doc DIRECT ID se read (range-query student
    // ke rules me fail hoti thi = attendance error). Sirf aaj tak ke din.
    final DateTime now = DateTime.now();
    final int lastDay = (month.year == now.year && month.month == now.month)
        ? now.day
        : DateTime(month.year, month.month + 1, 0).day;
    // Har read alag-alag safe: doc na ho (ya rules deny) to null —
    // poora month kabhi fail nahi hota.
    final List<Future<DocumentSnapshot<Map<String, dynamic>>?>> reads =
        <Future<DocumentSnapshot<Map<String, dynamic>>?>>[
      for (int day = 1; day <= lastDay; day++)
        _db
            .collection('attendance')
            .doc(docId(classSection,
                DateTime(month.year, month.month, day),),)
            .get()
            .then<DocumentSnapshot<Map<String, dynamic>>?>(
              (DocumentSnapshot<Map<String, dynamic>> d) => d,
            )
            .catchError(
              (Object _) => null,
            ),
    ];
    final List<DocumentSnapshot<Map<String, dynamic>>?> docs =
        await Future.wait(reads).timeout(const Duration(seconds: 20));
    int present = 0;
    int absent = 0;
    final Map<String, bool> days = <String, bool>{};
    for (final DocumentSnapshot<Map<String, dynamic>>? d in docs) {
      if (d == null || !d.exists) continue;
      final Map<String, dynamic>? marks =
          (d.data()?['marks'] as Map?)?.cast<String, dynamic>();
      if (marks == null || !marks.containsKey(uid)) continue;
      final bool p = marks[uid] == true;
      days[(d.data()?['date'] as String?) ?? d.id] = p;
      if (p) {
        present++;
      } else {
        absent++;
      }
    }
    return (present: present, absent: absent, days: days);
  }
}
