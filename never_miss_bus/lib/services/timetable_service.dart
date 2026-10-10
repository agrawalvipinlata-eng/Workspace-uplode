import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/result.dart';

class TimetableService {
  TimetableService(this._db);
  final FirebaseFirestore _db;

  static const List<String> weekdays = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday'
  ];

  Stream<List<Map<String, dynamic>>> watchForClass(String classSection) => _db
          .collection('timetable')
          .where('classSection', isEqualTo: classSection)
          .snapshots()
          .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
        final List<Map<String, dynamic>> rows = snapshot.docs
            .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                <String, dynamic>{'id': doc.id, ...doc.data()})
            .toList();
        rows.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
          final int dayA = weekdays.indexOf('${a['day'] ?? ''}');
          final int dayB = weekdays.indexOf('${b['day'] ?? ''}');
          if (dayA != dayB) return dayA.compareTo(dayB);
          return _period(a).compareTo(_period(b));
        });
        return rows;
      });

  Future<Result<void>> save({
    required String classSection,
    required String day,
    required int period,
    required String subject,
    required String teacher,
    String room = '',
  }) async {
    try {
      await _db.collection('timetable').add(<String, dynamic>{
        'classSection': classSection,
        'day': day,
        'period': period,
        'subject': subject.trim(),
        'teacher': teacher.trim(),
        'room': room.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return const Ok<void>(null);
    } on FirebaseException catch (e) {
      return Err<void>(
          AppFailure(e.code, 'Timetable save failed: ${e.message}'));
    } catch (e) {
      return Err<void>(
          AppFailure('timetable-save', 'Timetable save failed: $e'));
    }
  }

  static int _period(Map<String, dynamic> row) {
    final Object? value = row['period'];
    return value is num ? value.toInt() : int.tryParse('$value') ?? 0;
  }
}
