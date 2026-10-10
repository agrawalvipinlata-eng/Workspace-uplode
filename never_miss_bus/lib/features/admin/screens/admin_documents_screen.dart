import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/nmb_colors.dart';
import '../../../core/theme/nmb_typography.dart';
import '../../../core/utils/result.dart';
import '../../../core/widgets/nmb_card.dart';
import '../../../core/widgets/responsive_scaffold_body.dart';
import '../../../models/app_user.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';
import '../../../services/document_vault_service.dart';

class AdminDocumentsScreen extends ConsumerStatefulWidget {
  const AdminDocumentsScreen({super.key});

  @override
  ConsumerState<AdminDocumentsScreen> createState() =>
      _AdminDocumentsScreenState();
}

class _AdminDocumentsScreenState extends ConsumerState<AdminDocumentsScreen> {
  final TextEditingController _label = TextEditingController();
  String? _studentUid;
  bool _uploading = false;

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload() async {
    final String? uid = _studentUid;
    final String label = _label.text.trim();
    if (uid == null || label.isEmpty) {
      _snack('Student और document name select करो.', error: true);
      return;
    }
    final FilePickerResult? picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      allowMultiple: false,
      withData: true,
    );
    if (picked == null || picked.files.isEmpty || !mounted) return;
    final PlatformFile file = picked.files.single;
    if (file.size > 20 * 1024 * 1024) {
      _snack('File 20 MB से छोटी होनी चाहिए.', error: true);
      return;
    }
    if (file.bytes == null && (file.path == null || file.path!.isEmpty)) {
      _snack('File data नहीं मिली। Document फिर से select करें.', error: true);
      return;
    }
    final String extension = (file.extension ?? '').toLowerCase();
    final String contentType = extension == 'pdf'
        ? 'application/pdf'
        : extension == 'png'
            ? 'image/png'
            : extension == 'webp'
                ? 'image/webp'
                : 'image/jpeg';
    setState(() => _uploading = true);
    final Result<void> result =
        await ref.read(documentVaultServiceProvider).upload(
              studentUid: uid,
              label: label,
              file: file,
              contentType: contentType,
            );
    if (!mounted) return;
    setState(() => _uploading = false);
    result.when(
      ok: (_) {
        _label.clear();
        _snack('Original document uploaded.', success: true);
      },
      err: (AppFailure f) => _snack(f.message, error: true),
    );
  }

  void _snack(String message, {bool error = false, bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error
            ? NmbColors.danger
            : success
                ? NmbColors.success
                : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<AppUser> students =
        ref.watch(allStudentsProvider).valueOrNull ?? const <AppUser>[];
    final AppUser? selected = _studentUid == null
        ? null
        : students.cast<AppUser?>().firstWhere(
              (AppUser? s) => s?.uid == _studentUid,
              orElse: () => null,
            );

    return Scaffold(
      appBar: AppBar(title: const Text('Document Vault')),
      body: ResponsiveBody(
        child: ListView(
          children: <Widget>[
            Text('Original student documents',
                style: NmbTypography.screenTitle),
            const SizedBox(height: 4),
            Text(
              'Files are stored in private Cloud Storage without compression.',
              style: NmbTypography.bodySecondary,
            ),
            const SizedBox(height: 16),
            NmbCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  DropdownButtonFormField<String>(
                    value: _studentUid,
                    decoration: const InputDecoration(
                      labelText: 'Select student',
                      prefixIcon: Icon(Icons.person_search_rounded),
                    ),
                    items: <DropdownMenuItem<String>>[
                      for (final AppUser student in students)
                        DropdownMenuItem<String>(
                          value: student.uid,
                          child: Text(
                            '${student.fullName} • ${student.classSection ?? '-'} • Roll ${student.rollNumber ?? '-'}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (String? value) =>
                        setState(() => _studentUid = value),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _label,
                    decoration: const InputDecoration(
                      labelText: 'Document name',
                      hintText: 'Birth Certificate / Transfer Certificate',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _uploading ? null : _pickAndUpload,
                    icon: _uploading
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_upload_rounded),
                    label: Text(
                        _uploading ? 'Uploading…' : 'Upload original file'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (selected != null)
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: ref
                    .read(documentVaultServiceProvider)
                    .watchForStudent(selected.uid),
                builder: (BuildContext context,
                    AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final List<Map<String, dynamic>> docs = snapshot.data!;
                  if (docs.isEmpty) {
                    return const NmbCard(
                      child: Text('No documents uploaded for this student.'),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text('Uploaded documents',
                          style: NmbTypography.sectionTitle),
                      const SizedBox(height: 8),
                      for (final Map<String, dynamic> doc in docs)
                        _DocumentTile(
                          document: doc,
                          service: ref.read(documentVaultServiceProvider),
                        ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({required this.document, required this.service});
  final Map<String, dynamic> document;
  final DocumentVaultService service;

  @override
  Widget build(BuildContext context) {
    final String type = '${document['contentType'] ?? ''}';
    final bool image = type.startsWith('image/');
    return NmbCard(
      padding: const EdgeInsets.all(12),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          image ? Icons.image_rounded : Icons.picture_as_pdf_rounded,
          color: NmbColors.primary,
        ),
        title: Text('${document['label'] ?? 'Document'}'),
        subtitle: Text('${document['fileName'] ?? ''}'),
        trailing: IconButton(
          tooltip: 'View document',
          icon: const Icon(Icons.visibility_rounded),
          onPressed: (document['downloadUrl'] == null &&
                  document['objectKey'] == null)
              ? null
              : () async {
                  final Result<String> result =
                      await service.resolveDownloadUrl(document);
                  if (!context.mounted) return;
                  result.when(
                    ok: (String url) => launchUrl(
                      Uri.parse(url),
                      mode: LaunchMode.externalApplication,
                    ),
                    err: (AppFailure failure) => ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(failure.message))),
                  );
                },
        ),
      ),
    );
  }
}
