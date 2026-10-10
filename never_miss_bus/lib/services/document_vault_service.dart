import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
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
    required PlatformFile file,
    required String contentType,
  }) async {
    try {
      final String originalName = file.name.trim().isEmpty
          ? 'document'
          : file.name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final String safeName =
          '${DateTime.now().millisecondsSinceEpoch}_$originalName';
      final Reference ref =
          _storage.ref().child('studentDocuments/$studentUid/$safeName');
      final SettableMetadata metadata =
          SettableMetadata(contentType: contentType);
      final UploadTask task;
      if (file.bytes != null) {
        task = ref.putData(file.bytes!, metadata);
      } else if (file.path != null && file.path!.isNotEmpty) {
        task = ref.putFile(File(file.path!), metadata);
      } else {
        return const Err<void>(AppFailure(
          'document-file-missing',
          'File data नहीं मिली। Document फिर से select करें।',
        ));
      }
      final TaskSnapshot uploaded = await task;
      final String url = await uploaded.ref.getDownloadURL();
      await _db.collection('studentDocuments').add(<String, dynamic>{
        'studentUid': studentUid,
        'label': label.trim(),
        'fileName': file.name,
        'contentType': contentType,
        'sizeBytes': file.size,
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
