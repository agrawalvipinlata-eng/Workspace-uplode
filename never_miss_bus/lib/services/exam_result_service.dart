import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/result.dart';

class ExamResultService {
  ExamResultService(this._db);
  final FirebaseFirestore _db;

  Stream<List<Map<String, dynamic>>> watchAll() => _db
      .collection('examResults')
      .snapshots()
      .map((QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
              <String, dynamic>{'id': doc.id, ...doc.data()})
          .toList());

  Stream<List<Map<String, dynamic>>> watchForStudent(String studentUid) => _db
          .collection('examResults')
          .where('studentUid', isEqualTo: studentUid)
          .snapshots()
          .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
        final List<Map<String, dynamic>> rows = snapshot.docs
            .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                <String, dynamic>{'id': doc.id, ...doc.data()})
            .toList();
        rows.sort((Map<String, dynamic> a, Map<String, dynamic> b) =>
            '${b['examDate'] ?? ''}'.compareTo('${a['examDate'] ?? ''}'));
        return rows;
      });

  Future<Result<void>> save({
    required String studentUid,
    required String studentClass,
    required String examName,
    required String subject,
    required double marks,
    required double maxMarks,
  }) async {
    try {
      await _db.collection('examResults').add(<String, dynamic>{
        'studentUid': studentUid,
        'classSection': studentClass,
        'examName': examName.trim(),
        'subject': subject.trim(),
        'marks': marks,
        'maxMarks': maxMarks,
        'percentage': maxMarks == 0 ? 0 : (marks / maxMarks) * 100,
        'grade': grade(marks, maxMarks),
        'examDate': DateTime.now().toIso8601String().substring(0, 10),
        'createdAt': FieldValue.serverTimestamp(),
      });
      return const Ok<void>(null);
    } on FirebaseException catch (e) {
      return Err<void>(AppFailure(
        e.code,
        e.code == 'permission-denied'
            ? 'Result save permission denied — role/class rules check karo.'
            : 'Result save failed: ${e.message}',
      ));
    } catch (e) {
      return Err<void>(AppFailure('result-save', 'Result save failed: $e'));
    }
  }

  static String grade(double marks, double maxMarks) {
    if (maxMarks <= 0) return '-';
    final double percent = marks / maxMarks * 100;
    if (percent >= 90) return 'A+';
    if (percent >= 80) return 'A';
    if (percent >= 70) return 'B+';
    if (percent >= 60) return 'B';
    if (percent >= 50) return 'C';
    if (percent >= 33) return 'D';
    return 'E';
  }
}
