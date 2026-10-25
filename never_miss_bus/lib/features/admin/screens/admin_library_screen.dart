import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/nmb_colors.dart';
import '../../../core/theme/nmb_typography.dart';
import '../../../core/widgets/nmb_card.dart';
import '../../../core/utils/result.dart';
import '../../../providers/app_providers.dart';

class AdminLibraryScreen extends ConsumerWidget {
  const AdminLibraryScreen({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final Map<String, String>? data = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const _LibraryEntryDialog(),
    );
    if (data == null || !context.mounted) return;
    final String uid = ref.read(currentSessionProvider)?.uid ?? '';
    final Result<void> result = await ref.read(libraryServiceProvider).create(
          title: data['title'] ?? '',
          author: data['author'] ?? '',
          category: data['category'] ?? 'General',
          language: data['language'] ?? 'English',
          description: data['description'] ?? '',
          coverUrl: data['coverUrl'] ?? '',
          pdfUrl: data['pdfUrl'] ?? '',
          audioUrl: data['audioUrl'] ?? '',
          licenseType: data['licenseType'] ?? '',
          licenseUrl: data['licenseUrl'] ?? '',
          sourceUrl: data['sourceUrl'] ?? '',
          isPublished: data['isPublished'] == 'true',
          createdBy: uid,
        );
    if (!context.mounted) return;
    result.when(
      ok: (_) => ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Library item added.'))),
      err: (AppFailure error) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message))),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(
          title: const Text('Library'),
          actions: <Widget>[
            IconButton(
              tooltip: 'Add book',
              onPressed: () => _add(context, ref),
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _add(context, ref),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add resource'),
        ),
        body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: ref.read(libraryServiceProvider).watchAll(),
          builder: (BuildContext context,
              AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
            final List<Map<String, dynamic>> books =
                snapshot.data ?? const <Map<String, dynamic>>[];
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: <Widget>[
                NmbCard(
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.cloud_outlined,
                          color: NmbColors.primary, size: 30),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Store only metadata here. Keep PDF/audio files in R2 or another licensed external host.',
                          style: NmbTypography.bodySecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (books.isEmpty)
                  const NmbCard(child: Text('No library resources added yet.'))
                else
                  for (final Map<String, dynamic> book in books)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: NmbCard(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            book['isPublished'] == true
                                ? Icons.public_rounded
                                : Icons.visibility_off_rounded,
                            color: book['isPublished'] == true
                                ? NmbColors.success
                                : NmbColors.warning,
                          ),
                          title: Text('${book['title'] ?? 'Untitled'}',
                              style: NmbTypography.cardTitle),
                          subtitle: Text(
                              '${book['author'] ?? ''} • ${book['category'] ?? 'General'}\nLicense: ${book['licenseType'] ?? 'Not set'}'),
                          isThreeLine: true,
                          trailing: IconButton(
                            tooltip: 'Delete',
                            color: NmbColors.danger,
                            icon: const Icon(Icons.delete_outline_rounded),
                            onPressed: () async {
                              final bool? yes = await showDialog<bool>(
                                context: context,
                                builder: (BuildContext dialog) => AlertDialog(
                                  title: const Text('Delete library item?'),
                                  content: Text('${book['title'] ?? ''}'),
                                  actions: <Widget>[
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialog, false),
                                        child: const Text('Cancel')),
                                    FilledButton(
                                        onPressed: () =>
                                            Navigator.pop(dialog, true),
                                        child: const Text('Delete')),
                                  ],
                                ),
                              );
                              if (yes == true) {
                                await ref
                                    .read(libraryServiceProvider)
                                    .delete('${book['id']}');
                              }
                            },
                          ),
                        ),
                      ),
                    ),
              ],
            );
          },
        ),
      );
}

class _LibraryEntryDialog extends StatefulWidget {
  const _LibraryEntryDialog();
  @override
  State<_LibraryEntryDialog> createState() => _LibraryEntryDialogState();
}

class _LibraryEntryDialogState extends State<_LibraryEntryDialog> {
  final Map<String, TextEditingController> _c = <String, TextEditingController>{
    for (final String key in <String>[
      'title',
      'author',
      'category',
      'language',
      'description',
      'coverUrl',
      'pdfUrl',
      'audioUrl',
      'licenseType',
      'licenseUrl',
      'sourceUrl'
    ])
      key: TextEditingController(),
  };
  bool _published = false;

  @override
  void dispose() {
    for (final TextEditingController controller in _c.values)
      controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Add legal library resource'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                      'Use only public-domain, Creative Commons or licensed content.',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 10),
                for (final String key in <String>[
                  'title',
                  'author',
                  'category',
                  'language',
                  'description',
                  'coverUrl',
                  'pdfUrl',
                  'audioUrl',
                  'licenseType',
                  'licenseUrl',
                  'sourceUrl'
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextField(
                      controller: _c[key],
                      maxLines: key == 'description' ? 3 : 1,
                      decoration: InputDecoration(
                          labelText: _label(key),
                          hintText: key.endsWith('Url') ? 'https://...' : null),
                    ),
                  ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Publish now'),
                  subtitle:
                      const Text('Only publish after license verification'),
                  value: _published,
                  onChanged: (bool value) => setState(() => _published = value),
                ),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (_c['title']!.text.trim().isEmpty) return;
              Navigator.pop(context, <String, String>{
                for (final MapEntry<String, TextEditingController> entry
                    in _c.entries)
                  entry.key: entry.value.text,
                'isPublished': '$_published',
              });
            },
            child: const Text('Save'),
          ),
        ],
      );

  String _label(String key) => key == 'pdfUrl'
      ? 'PDF URL (R2/CDN)'
      : key == 'audioUrl'
          ? 'Audio URL (R2/CDN)'
          : key == 'coverUrl'
              ? 'Cover URL'
              : key == 'licenseUrl'
                  ? 'License proof URL'
                  : key == 'sourceUrl'
                      ? 'Original source URL'
                      : key[0].toUpperCase() + key.substring(1);
}
