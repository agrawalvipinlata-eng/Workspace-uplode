import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_language.dart';
import '../../../core/widgets/nmb_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/app_user.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';

class StudentNoticeBoardScreen extends ConsumerWidget {
  const StudentNoticeBoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppUser? me = ref.watch(myProfileProvider).valueOrNull;
    final String? klass = me?.classSection;
    if (klass == null) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.campaign_outlined,
          title: 'No class assigned',
          message: 'Notices will appear after your class is assigned.',
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(tr('Notice Board', 'नोटिस बोर्ड'))),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: ref.read(noticeBoardServiceProvider).watchForClass(klass),
        builder: (BuildContext context,
            AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final List<Map<String, dynamic>> notices = snapshot.data!;
          if (notices.isEmpty) {
            return const EmptyState(
              icon: Icons.campaign_outlined,
              title: 'No notices yet',
              message: 'School announcements will appear here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notices.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (BuildContext context, int index) {
              final Map<String, dynamic> notice = notices[index];
              return NmbCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      const CircleAvatar(child: Icon(Icons.campaign_rounded)),
                  title: Text('${notice['title'] ?? 'Notice'}'),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('${notice['body'] ?? ''}'),
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
