import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../core/utils/result.dart';

/// Original-quality student document storage.
///
/// Binary files live in Cloud Storage. Firestore stores only metadata and the
/// generated download URL so the app can render the document without opening
/// the GitHub website or exposing repository credentials.
class DocumentVaultService {
  DocumentVaultService(this._db, this._storage);

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  Stream<List<Map<String, dynamic>>> watchForStudent(String studentUid) => _db
          .collection('studentDocuments')
          .where('studentUid', isEqualTo: studentUid)
          .snapshots()
          .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
        final List<Map<String, dynamic>> docs = snapshot.docs
            .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                <String, dynamic>{'id': doc.id, ...doc.data()})
            .toList();
        docs.sort((Map<String, dynamic> a, Map<String, dynamic> b) =>
            '${b['uploadedAt'] ?? ''}'.compareTo('${a['uploadedAt'] ?? ''}'));
        return docs;
      });

  Future<Result<void>> upload({
    required String studentUid,
    required String label,
    required File file,
    required String contentType,
  }) async {
    try {
      final String safeName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';
      final Reference ref =
          _storage.ref().child('studentDocuments/$studentUid/$safeName');
      final UploadTask task = ref.putFile(
        file,
        SettableMetadata(contentType: contentType),
      );
      final TaskSnapshot uploaded = await task;
      final String url = await uploaded.ref.getDownloadURL();
      await _db.collection('studentDocuments').add(<String, dynamic>{
        'studentUid': studentUid,
        'label': label.trim(),
        'fileName': file.uri.pathSegments.last,
        'contentType': contentType,
        'sizeBytes': await file.length(),
        'storagePath': uploaded.ref.fullPath,
        'downloadUrl': url,
        'uploadedAt': FieldValue.serverTimestamp(),
      });
      return const Ok<void>(null);
    } on FirebaseException catch (e) {
      return Err<void>(AppFailure(
        e.code,
        e.code == 'unauthorized'
            ? 'Document permission denied. Storage Rules check karo.'
            : 'Document upload failed: ${e.message}',
      ));
    } catch (e) {
      return Err<void>(AppFailure('document-upload', 'Upload failed: $e'));
    }
  }
}
