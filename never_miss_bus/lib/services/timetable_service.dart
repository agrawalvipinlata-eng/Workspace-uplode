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
  static const List<int> periods = <int>[1, 2, 3, 4, 5, 6, 7, 8];
  static const List<String> periodTimes = <String>[
    '8:00 - 8:45',
    '8:45 - 9:30',
    '9:30 - 10:15',
    '10:15 - 11:00',
    '11:00 - 11:45',
    '11:45 - 12:30',
    '12:30 - 1:15',
    '1:15 - 2:00'
  ];
  static const List<String> lunchFloors = <String>[
    'Ground Floor',
    'First Floor',
    'Second Floor',
    'Third Floor',
    'Canteen Area'
  ];

  Stream<List<Map<String, dynamic>>> watchForClass(String classSection) =>
      _watch(_db
          .collection('timetable')
          .where('classSection', isEqualTo: classSection));
  Stream<List<Map<String, dynamic>>> watchForTeacher(String teacherUid) =>
      _watch(_db
          .collection('timetable')
          .where('teacherUid', isEqualTo: teacherUid));
  Stream<List<Map<String, dynamic>>> watchAll() =>
      _watch(_db.collection('timetable'));
  Stream<List<Map<String, dynamic>>> watchLunchDuties() => _watch(
      _db.collection('timetable').where('entryType', isEqualTo: 'lunchDuty'));

  Stream<List<Map<String, dynamic>>> _watch(
          Query<Map<String, dynamic>> query) =>
      query.snapshots().map((QuerySnapshot<Map<String, dynamic>> snapshot) {
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

  Future<Result<void>> save(
      {required String classSection,
      required String day,
      required int period,
      required String subject,
      required String teacher,
      required String teacherUid,
      String room = ''}) async {
    try {
      await _db.collection('timetable').add(<String, dynamic>{
        'entryType': 'class',
        'classSection': classSection.trim(),
        'day': day,
        'period': period,
        'subject': subject.trim(),
        'teacher': teacher.trim(),
        'teacherUid': teacherUid,
        'room': room.trim(),
        'updatedAt': FieldValue.serverTimestamp()
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

  Future<Result<void>> saveLunchDuty(
      {required String teacher,
      required String teacherUid,
      required String floor,
      required String day}) async {
    try {
      await _db.collection('timetable').add(<String, dynamic>{
        'entryType': 'lunchDuty',
        'teacher': teacher.trim(),
        'teacherUid': teacherUid,
        'floor': floor,
        'day': day,
        'period': 0,
        'lunchTime': '11:00 - 1:00',
        'updatedAt': FieldValue.serverTimestamp()
      });
      return const Ok<void>(null);
    } on FirebaseException catch (e) {
      return Err<void>(
          AppFailure(e.code, 'Lunch duty save failed: ${e.message}'));
    } catch (e) {
      return Err<void>(
          AppFailure('lunch-duty-save', 'Lunch duty save failed: $e'));
    }
  }

  static int _period(Map<String, dynamic> row) {
    final Object? value = row['period'];
    return value is num ? value.toInt() : int.tryParse('$value') ?? 0;
  }
}
