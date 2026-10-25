import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/result.dart';

class LibraryService {
  LibraryService(this._db);
  final FirebaseFirestore _db;

  Stream<List<Map<String, dynamic>>> watchPublished() => _db
      .collection('libraryBooks')
      .where('isPublished', isEqualTo: true)
      .snapshots()
      .map(_rowsAndSort);

  Stream<List<Map<String, dynamic>>> watchAll() =>
      _db.collection('libraryBooks').snapshots().map(_rowsAndSort);

  List<Map<String, dynamic>> _rows(
          QuerySnapshot<Map<String, dynamic>> snapshot) =>
      snapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
              <String, dynamic>{
                'id': doc.id,
                ...doc.data(),
              })
          .toList();

  List<Map<String, dynamic>> _rowsAndSort(
      QuerySnapshot<Map<String, dynamic>> snapshot) {
    final List<Map<String, dynamic>> rows = _rows(snapshot);
    rows.sort((Map<String, dynamic> a, Map<String, dynamic> b) =>
        '${a['title'] ?? ''}'.toLowerCase().compareTo(
              '${b['title'] ?? ''}'.toLowerCase(),
            ));
    return rows;
  }

  Future<Result<void>> create({
    required String title,
    required String titleHi,
    required String author,
    required String category,
    required String language,
    required String description,
    required String descriptionHi,
    required String coverUrl,
    required String pdfUrl,
    required String audioUrl,
    required String licenseType,
    required String licenseUrl,
    required String sourceUrl,
    required bool isPublished,
    required String createdBy,
  }) async {
    try {
      await _db.collection('libraryBooks').add(<String, dynamic>{
        'title': title.trim(),
        'titleHi': titleHi.trim(),
        'author': author.trim(),
        'category': category.trim(),
        'language': language.trim(),
        'description': description.trim(),
        'descriptionHi': descriptionHi.trim(),
        'coverUrl': coverUrl.trim(),
        'pdfUrl': pdfUrl.trim(),
        'audioUrl': audioUrl.trim(),
        'licenseType': licenseType.trim(),
        'licenseUrl': licenseUrl.trim(),
        'sourceUrl': sourceUrl.trim(),
        'isPublished': isPublished,
        'createdBy': createdBy,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return const Ok<void>(null);
    } on FirebaseException catch (e) {
      return Err<void>(AppFailure(e.code, 'Library save failed: ${e.message}'));
    } catch (e) {
      return Err<void>(AppFailure('library-save', 'Library save failed: $e'));
    }
  }

  Future<Result<void>> delete(String id) async {
    try {
      await _db.collection('libraryBooks').doc(id).delete();
      return const Ok<void>(null);
    } on FirebaseException catch (e) {
      return Err<void>(
          AppFailure(e.code, 'Library delete failed: ${e.message}'));
    } catch (e) {
      return Err<void>(
          AppFailure('library-delete', 'Library delete failed: $e'));
    }
  }
}
