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
        title: Text(tr('Library', 'लाइब्रेरी')),
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
              message:
                  'Library could not load. Please check Firebase rules and sign in again.\n\n${snapshot.error}',
            );
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
    return ValueListenableBuilder<String>(
      valueListenable: appLanguage,
      builder: (BuildContext context, String language, Widget? child) {
        final bool hindi = language == 'hi';
        final String title =
            '${book[hindi ? 'titleHi' : 'title'] ?? ''}'.trim();
        final String fallbackTitle =
            '${book[hindi ? 'title' : 'titleHi'] ?? 'Untitled book'}';
        final String description =
            '${book[hindi ? 'descriptionHi' : 'description'] ?? ''}'.trim();
        final String fallbackDescription =
            '${book[hindi ? 'description' : 'descriptionHi'] ?? ''}'.trim();
        final String displayTitle = title.isEmpty ? fallbackTitle : title;
        final String displayDescription =
            description.isEmpty ? fallbackDescription : description;
        final String pdf = '${book['pdfUrl'] ?? ''}';
        final String audio = '${book['audioUrl'] ?? ''}';
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: NmbCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _BookVisual(book: book, title: displayTitle),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(displayTitle, style: NmbTypography.cardTitle),
                      const SizedBox(height: 3),
                      Text(
                          '${book['author'] ?? 'Unknown author'} • ${book['language'] ?? 'English'}',
                          style: NmbTypography.bodySecondary),
                      if (displayDescription.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 5),
                        Text(displayDescription,
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
                              icon: const Icon(Icons.headphones_rounded,
                                  size: 17),
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
      },
    );
  }
}

class _BookVisual extends StatelessWidget {
  const _BookVisual({required this.book, required this.title});
  final Map<String, dynamic> book;
  final String title;

  @override
  Widget build(BuildContext context) {
    final String cover = '${book['coverUrl'] ?? ''}';
    return SizedBox(
      width: 78,
      height: 100,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned(
            left: 5,
            top: 5,
            bottom: 0,
            child: Container(
              width: 12,
              decoration: BoxDecoration(
                color: NmbColors.primary.withOpacity(0.75),
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(8),
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            top: 0,
            bottom: 5,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.skewY(-0.04),
              child: Container(
                width: 62,
                decoration: BoxDecoration(
                  color: NmbColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 8,
                      offset: Offset(3, 5),
                    ),
                  ],
                  image: cover.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(cover), fit: BoxFit.cover)
                      : null,
                ),
                child: cover.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(7),
                          child: Text(
                            title,
                            maxLines: 4,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: NmbColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
