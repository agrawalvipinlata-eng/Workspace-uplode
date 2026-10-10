import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_language.dart';
import '../../../core/theme/nmb_colors.dart';
import '../../../core/theme/nmb_typography.dart';
import '../../../core/widgets/nmb_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/app_user.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';

class StudentDocumentsScreen extends ConsumerWidget {
  const StudentDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppUser? me = ref.watch(myProfileProvider).valueOrNull;
    if (me == null) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      appBar: AppBar(title: Text(tr('My Documents', 'मेरे दस्तावेज़'))),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: ref.read(documentVaultServiceProvider).watchForStudent(me.uid),
        builder: (BuildContext context,
            AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.hasError) {
            return const ErrorView(message: 'Could not load documents.');
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final List<Map<String, dynamic>> documents = snapshot.data!;
          if (documents.isEmpty) {
            return const EmptyState(
              icon: Icons.folder_open_rounded,
              title: 'No documents yet',
              message:
                  'School-uploaded certificates and records will appear here.',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Text(tr('Secure document vault', 'सुरक्षित डॉक्यूमेंट वॉल्ट'),
                  style: NmbTypography.screenTitle),
              const SizedBox(height: 4),
              Text(
                  tr('Original-quality files shared by the school.',
                      'School द्वारा share की गई original-quality files.'),
                  style: NmbTypography.bodySecondary),
              const SizedBox(height: 16),
              for (final Map<String, dynamic> document in documents)
                _DocumentCard(document: document),
            ],
          );
        },
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({required this.document});
  final Map<String, dynamic> document;

  @override
  Widget build(BuildContext context) {
    final String type = '${document['contentType'] ?? ''}';
    final String url = '${document['downloadUrl'] ?? ''}';
    final bool image = type.startsWith('image/');
    return NmbCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(children: <Widget>[
            CircleAvatar(
              backgroundColor: NmbColors.primarySoft,
              child: Icon(
                  image ? Icons.image_rounded : Icons.picture_as_pdf_rounded,
                  color: NmbColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                  Text('${document['label'] ?? 'Document'}',
                      style: NmbTypography.cardTitle),
                  Text('${document['fileName'] ?? ''}',
                      style: NmbTypography.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ])),
            Icon(Icons.verified_rounded, color: NmbColors.success),
          ]),
          const SizedBox(height: 10),
          if (image && url.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 1.6,
                child: Image.network(url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Center(child: Icon(Icons.broken_image_outlined))),
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: url.isEmpty
                ? null
                : () async {
                    if (image) {
                      await showDialog<void>(
                          context: context,
                          builder: (_) => Dialog(
                              child: InteractiveViewer(
                                  child: Image.network(url))));
                    } else {
                      await launchUrl(Uri.parse(url),
                          mode: LaunchMode.externalApplication);
                    }
                  },
            icon:
                Icon(image ? Icons.zoom_in_rounded : Icons.open_in_new_rounded),
            label: Text(image ? 'View full document' : 'Open PDF'),
          ),
        ],
      ),
    );
  }
}
