import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/result.dart';

/// 📝 ONLINE APPLICATION (leave/absence) — student app se hi bhejta hai.
///
/// Data model:
///   applications/{autoId} = {
///     uid, name, classSection, rollNumber,
///     type: 'leave' | 'other',
///     fromDate: '2026-09-02', toDate: '2026-09-03',
///     reason: '...', status: 'pending' | 'approved' | 'rejected',
///     createdAt: ts, decidedBy: uid?, decidedAt: ts?
///   }
/// Rules: student apni application create/read karta hai;
/// teacher/admin apni class ki read + status update karte hain.
class LeaveService {
  LeaveService(this._db);

  final FirebaseFirestore _db;

  /// Student: nayi application bhejo.
  Future<Result<void>> submit({
    required String uid,
    required String name,
    required String classSection,
    required String? rollNumber,
    required DateTime fromDate,
    required DateTime toDate,
    required String reason,
  }) async {
    try {
      await _db.collection('applications').add(<String, dynamic>{
        'uid': uid,
        'name': name,
        'classSection': classSection,
        'rollNumber': rollNumber,
        'type': 'leave',
        'fromDate': _d(fromDate),
        'toDate': _d(toDate),
        'reason': reason,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));
      return const Ok<void>(null);
    } on FirebaseException catch (e) {
      return Err<void>(AppFailure(
        e.code,
        e.code == 'permission-denied'
            ? 'Permission denied — admin se rules deploy karwao.'
            : 'Send failed: ${e.message}',
      ),);
    } catch (e) {
      return Err<void>(AppFailure('leave-send', 'Send failed: $e'));
    }
  }

  /// Student: meri applications (latest pehle).
  Stream<List<Map<String, dynamic>>> myApplications(String uid) {
    return _db
        .collection('applications')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> q) {
      final List<Map<String, dynamic>> list = q.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> d) =>
              <String, dynamic>{'id': d.id, ...d.data()},)
          .toList();
      list.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
        final Timestamp? ta = a['createdAt'] as Timestamp?;
        final Timestamp? tb = b['createdAt'] as Timestamp?;
        if (ta == null || tb == null) return 0;
        return tb.compareTo(ta);
      });
      return list;
    });
  }

  /// Teacher/Admin: class ki (ya saari) pending applications.
  Stream<List<Map<String, dynamic>>> forClass(String? classSection) {
    Query<Map<String, dynamic>> q = _db.collection('applications');
    if (classSection != null) {
      q = q.where('classSection', isEqualTo: classSection);
    }
    return q.snapshots().map((QuerySnapshot<Map<String, dynamic>> snap) {
      final List<Map<String, dynamic>> list = snap.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> d) =>
              <String, dynamic>{'id': d.id, ...d.data()},)
          .toList();
      list.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
        final Timestamp? ta = a['createdAt'] as Timestamp?;
        final Timestamp? tb = b['createdAt'] as Timestamp?;
        if (ta == null || tb == null) return 0;
        return tb.compareTo(ta);
      });
      return list;
    });
  }

  /// Teacher/Admin: approve ya reject.
  Future<Result<void>> decide({
    required String applicationId,
    required bool approve,
    required String decidedBy,
  }) async {
    try {
      await _db
          .collection('applications')
          .doc(applicationId)
          .update(<String, dynamic>{
        'status': approve ? 'approved' : 'rejected',
        'decidedBy': decidedBy,
        'decidedAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));
      return const Ok<void>(null);
    } catch (e) {
      return Err<void>(AppFailure('leave-decide', 'Update failed: $e'));
    }
  }

  static String _d(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
