import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/state_views.dart';
import '../../../models/app_user.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';

class HomeworkScreen extends ConsumerWidget {
  const HomeworkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppUser? me = ref.watch(myProfileProvider).valueOrNull;
    if (me?.classSection == null) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.menu_book_outlined,
          title: 'No class assigned',
          message: 'Homework will appear after the school assigns your class.',
        ),
      );
    }
    final stream = ref.watch(schoolworkServiceProvider)
        .watchHomework(me!.classSection!);
    return Scaffold(
      appBar: AppBar(title: const Text('Homework')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: stream,
        builder: (BuildContext context,
            AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.hasError) {
            return const ErrorView(message: 'Could not load homework.');
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final List<Map<String, dynamic>> items = snapshot.data!;
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.menu_book_outlined,
              title: 'No homework yet',
              message: 'Your class homework will appear here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (BuildContext context, int index) {
              final Map<String, dynamic> item = items[index];
              return Card(
                child: ListTile(
                  isThreeLine: true,
                  leading: const CircleAvatar(
                    child: Icon(Icons.assignment_outlined),
                  ),
                  title: Text('${item['subject'] ?? 'Homework'}'),
                  subtitle: Text(
                    '${item['description'] ?? ''}\nDate: ${item['date'] ?? '-'}',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
