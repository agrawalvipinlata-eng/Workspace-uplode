import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_language.dart';
import '../../core/theme/nmb_colors.dart';
import '../../core/theme/nmb_typography.dart';
import '../../core/widgets/nmb_card.dart';
import '../../core/widgets/state_views.dart';
import '../../providers/app_providers.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  String _query = '';
  String _category = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Knowledge Library', 'नॉलेज लाइब्रेरी')),
        actions: <Widget>[
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: ref.read(libraryServiceProvider).watchPublished(),
        builder: (BuildContext context,
            AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.hasError) {
            return ErrorView(
                message: 'Library could not load: ${snapshot.error}');
          }
          final List<Map<String, dynamic>> books =
              snapshot.data ?? const <Map<String, dynamic>>[];
          final Set<String> categories = <String>{
            'All',
            ...books.map((Map<String, dynamic> book) =>
                '${book['category'] ?? 'General'}')
          };
          final String q = _query.trim().toLowerCase();
          final List<Map<String, dynamic>> visible =
              books.where((Map<String, dynamic> book) {
            final String text =
                '${book['title'] ?? ''} ${book['author'] ?? ''} ${book['description'] ?? ''}'
                    .toLowerCase();
            return (_category == 'All' ||
                    '${book['category'] ?? 'General'}' == _category) &&
                (q.isEmpty || text.contains(q));
          }).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
            children: <Widget>[
              NmbCard(
                child: Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 27,
                      backgroundColor: NmbColors.primarySoft,
                      child: Icon(Icons.local_library_rounded,
                          color: NmbColors.primary, size: 29),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Read. Listen. Learn.',
                              style: NmbTypography.cardTitle),
                          const SizedBox(height: 3),
                          Text('Curated legal books and audio resources',
                              style: NmbTypography.bodySecondary),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Search title, author or topic',
                ),
                onChanged: (String value) => setState(() => _query = value),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: <Widget>[
                    for (final String category in categories)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: _category == category,
                          onSelected: (_) =>
                              setState(() => _category = category),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (snapshot.connectionState == ConnectionState.waiting &&
                  books.isEmpty)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ))
              else if (visible.isEmpty)
                const EmptyState(
                  icon: Icons.menu_book_outlined,
                  title: 'No books found',
                  message: 'New legal learning resources will appear here.',
                )
              else
                for (final Map<String, dynamic> book in visible)
                  _BookCard(book: book),
            ],
          );
        },
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard({required this.book});
  final Map<String, dynamic> book;

  Future<void> _open(BuildContext context, String value, String label) async {
    final Uri? uri = Uri.tryParse(value);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$label link is not available.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title = '${book['title'] ?? 'Untitled book'}';
    final String pdf = '${book['pdfUrl'] ?? ''}';
    final String audio = '${book['audioUrl'] ?? ''}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: NmbCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 58,
              height: 76,
              decoration: BoxDecoration(
                color: NmbColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
                image: '${book['coverUrl'] ?? ''}'.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage('${book['coverUrl']}'),
                        fit: BoxFit.cover)
                    : null,
              ),
              child: '${book['coverUrl'] ?? ''}'.isEmpty
                  ? Icon(Icons.menu_book_rounded, color: NmbColors.primary)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: NmbTypography.cardTitle),
                  const SizedBox(height: 3),
                  Text(
                      '${book['author'] ?? 'Unknown author'} • ${book['language'] ?? 'English'}',
                      style: NmbTypography.bodySecondary),
                  if ('${book['description'] ?? ''}'.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 5),
                    Text('${book['description']}',
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: <Widget>[
                      if (pdf.isNotEmpty)
                        OutlinedButton.icon(
                          onPressed: () => _open(context, pdf, 'PDF'),
                          icon: const Icon(Icons.picture_as_pdf_rounded,
                              size: 17),
                          label: const Text('Read PDF'),
                        ),
                      if (audio.isNotEmpty)
                        FilledButton.tonalIcon(
                          onPressed: () => _open(context, audio, 'Audio'),
                          icon: const Icon(Icons.headphones_rounded, size: 17),
                          label: const Text('Listen'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
