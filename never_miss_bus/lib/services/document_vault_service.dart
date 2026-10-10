import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;

import '../core/utils/result.dart';

/// Student document storage.
///
/// If R2_WORKER_URL is supplied at build time, binaries are uploaded to the
/// Cloudflare R2 Worker and Firestore stores only R2 metadata. Without that
/// define, the existing Firebase Storage flow remains the safe fallback.
class DocumentVaultService {
  DocumentVaultService(this._db, this._storage, this._auth);

  static const String _r2WorkerUrl = String.fromEnvironment('R2_WORKER_URL');
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  bool get usesR2 => _r2WorkerUrl.trim().isNotEmpty;

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
    if (usesR2) {
      return _uploadToR2(
        studentUid: studentUid,
        label: label,
        file: file,
        contentType: contentType,
      );
    }
    return _uploadToFirebase(
      studentUid: studentUid,
      label: label,
      file: file,
      contentType: contentType,
    );
  }

  Future<Result<void>> _uploadToFirebase({
    required String studentUid,
    required String label,
    required PlatformFile file,
    required String contentType,
  }) async {
    try {
      final String safeName =
          '${DateTime.now().millisecondsSinceEpoch}_${_safeName(file.name)}';
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
        'storageProvider': 'firebase',
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

  Future<Result<void>> _uploadToR2({
    required String studentUid,
    required String label,
    required PlatformFile file,
    required String contentType,
  }) async {
    try {
      final User? user = _auth.currentUser;
      final String? token = await user?.getIdToken();
      if (token == null || token.isEmpty) {
        return const Err<void>(AppFailure.sessionExpired);
      }
      final http.MultipartRequest request = http.MultipartRequest(
        'POST',
        Uri.parse('$_r2WorkerUrl/documents/upload'),
      )
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['studentUid'] = studentUid
        ..fields['label'] = label.trim()
        ..fields['contentType'] = contentType;
      if (file.bytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          file.bytes!,
          filename: file.name,
        ));
      } else if (file.path != null && file.path!.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          file.path!,
          filename: file.name,
        ));
      } else {
        return const Err<void>(AppFailure(
          'document-file-missing',
          'File data नहीं मिली। Document फिर से select करें।',
        ));
      }
      final http.StreamedResponse streamed = await request.send();
      final String body = await streamed.stream.bytesToString();
      final Map<String, dynamic> response = _decode(body);
      if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
        return Err<void>(AppFailure(
          'r2-${streamed.statusCode}',
          _r2Message(response['error']),
        ));
      }
      await _db.collection('studentDocuments').add(<String, dynamic>{
        'studentUid': studentUid,
        'label': label.trim(),
        'fileName': file.name,
        'contentType': contentType,
        'sizeBytes': file.size,
        'storageProvider': 'r2',
        'objectKey': response['objectKey'],
        'uploadedAt': FieldValue.serverTimestamp(),
      });
      return const Ok<void>(null);
    } on FirebaseException catch (e) {
      return Err<void>(
          AppFailure(e.code, e.message ?? 'Firestore save failed.'));
    } on http.ClientException catch (e) {
      return Err<void>(AppFailure('r2-network', 'R2 upload failed: $e'));
    } catch (e) {
      return Err<void>(AppFailure('r2-upload', 'R2 upload failed: $e'));
    }
  }

  /// Resolves a fresh 15-minute R2 capability URL for a document.
  Future<Result<String>> resolveDownloadUrl(
      Map<String, dynamic> document) async {
    final String existing = '${document['downloadUrl'] ?? ''}';
    if (existing.isNotEmpty) return Ok<String>(existing);
    final String objectKey = '${document['objectKey'] ?? ''}';
    final String studentUid = '${document['studentUid'] ?? ''}';
    if (!usesR2 || objectKey.isEmpty || studentUid.isEmpty) {
      return const Err<String>(AppFailure(
        'document-url-missing',
        'Document download link उपलब्ध नहीं है।',
      ));
    }
    try {
      final String? token = await _auth.currentUser?.getIdToken();
      if (token == null || token.isEmpty) {
        return const Err<String>(AppFailure.sessionExpired);
      }
      final http.Response response = await http.post(
        Uri.parse('$_r2WorkerUrl/documents/view-url'),
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(<String, String>{
          'objectKey': objectKey,
          'studentUid': studentUid,
        }),
      );
      final Map<String, dynamic> data = _decode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return Err<String>(AppFailure(
          'r2-${response.statusCode}',
          _r2Message(data['error']),
        ));
      }
      return Ok<String>('${data['url']}');
    } catch (e) {
      return Err<String>(AppFailure('r2-url', 'Document link failed: $e'));
    }
  }

  static String _safeName(String value) => value.trim().isEmpty
      ? 'document'
      : value.trim().replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');

  static Map<String, dynamic> _decode(String body) {
    final dynamic value = jsonDecode(body);
    return value is Map<String, dynamic> ? value : <String, dynamic>{};
  }

  static String _r2Message(dynamic error) {
    switch (error) {
      case 'admin-only':
        return 'Only an admin can upload documents.';
      case 'file-too-large':
        return 'File 20 MB से छोटी होनी चाहिए.';
      case 'unsupported-type':
        return 'Only PDF, JPG, PNG और WEBP files supported हैं.';
      default:
        return 'R2 document service request failed.';
    }
  }
}
