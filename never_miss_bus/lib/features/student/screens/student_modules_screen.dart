import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_language.dart';
import '../../../core/theme/nmb_colors.dart';
import '../../../core/theme/nmb_typography.dart';
import '../../../core/widgets/nmb_card.dart';
import '../../../core/widgets/responsive_scaffold_body.dart';

class StudentModulesScreen extends StatefulWidget {
  const StudentModulesScreen({super.key});

  @override
  State<StudentModulesScreen> createState() => _StudentModulesScreenState();
}

class _StudentModulesScreenState extends State<StudentModulesScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  static const List<_ModuleGroup> _groups = <_ModuleGroup>[
    _ModuleGroup('Academic', Icons.school_rounded, <_ModuleItem>[
      _ModuleItem('Parent dashboard', 'Attendance, fees and updates',
          Icons.dashboard_rounded, '/student/home/parent-dashboard'),
      _ModuleItem('Homework', 'Daily class work', Icons.menu_book_rounded,
          '/student/home/homework'),
      _ModuleItem('Attendance', 'View your attendance',
          Icons.fact_check_rounded, '/student/home/attendance'),
      _ModuleItem('Daily diary', 'Teacher diary and notes',
          Icons.edit_note_rounded, '/student/home/homework'),
      _ModuleItem('Class remarks', 'Homework and achievement notes',
          Icons.star_rounded, '/student/profile'),
    ]),
    _ModuleGroup('Bus & safety', Icons.directions_bus_rounded, <_ModuleItem>[
      _ModuleItem('Track my bus', 'Live location and ETA', Icons.map_rounded,
          '/student/map'),
      _ModuleItem('My stop', 'Route and stop details', Icons.pin_drop_rounded,
          '/student/home/stops'),
      _ModuleItem('Bus schedule', 'Stops and timings', Icons.schedule_rounded,
          '/student/home/bus'),
      _ModuleItem('School contacts', 'Call or email the school',
          Icons.contacts_rounded, '/student/profile'),
    ]),
    _ModuleGroup('Communication', Icons.forum_rounded, <_ModuleItem>[
      _ModuleItem('Notifications', 'Announcements and alerts',
          Icons.notifications_rounded, '/student/alerts'),
      _ModuleItem('Leave application', 'Apply and track leave',
          Icons.event_available_rounded, '/student/home/leave'),
      _ModuleItem('My profile', 'Personal and parent details',
          Icons.person_rounded, '/student/profile'),
      _ModuleItem('Customize home', 'Show, hide and reorder cards',
          Icons.tune_rounded, '/student/home/customize'),
    ]),
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String q = _query.trim().toLowerCase();
    final List<_ModuleGroup> visible = _groups
        .map((_ModuleGroup group) => _ModuleGroup(
              group.title,
              group.icon,
              group.items
                  .where((_ModuleItem item) =>
                      q.isEmpty ||
                      item.title.toLowerCase().contains(q) ||
                      item.subtitle.toLowerCase().contains(q))
                  .toList(),
            ))
        .where((_ModuleGroup group) => group.items.isNotEmpty)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Modules', 'मॉड्यूल्स')),
        actions: <Widget>[
          IconButton(
            tooltip: tr('Customize home', 'होम कस्टमाइज़'),
            onPressed: () => context.go('/student/home/customize'),
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: ResponsiveBody(
        scrollable: false,
        child: ListView(
          children: <Widget>[
            Text(
              tr('Everything for your school day', 'स्कूल के सभी ज़रूरी फीचर'),
              style: NmbTypography.screenTitle,
            ),
            const SizedBox(height: 4),
            Text(
              tr('Search a feature or choose a category below.',
                  'फीचर खोजें या नीचे category चुनें।'),
              style: NmbTypography.bodySecondary,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _search,
              onChanged: (String value) => setState(() => _query = value),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: tr('Search modules', 'मॉड्यूल खोजें'),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.clear_rounded),
                      ),
              ),
            ),
            const SizedBox(height: 18),
            for (final _ModuleGroup group in visible) ...<Widget>[
              Row(
                children: <Widget>[
                  Icon(group.icon, color: NmbColors.primary),
                  const SizedBox(width: 8),
                  Text(group.title, style: NmbTypography.sectionTitle),
                ],
              ),
              const SizedBox(height: 10),
              NmbCard(
                padding: const EdgeInsets.all(12),
                child: GridView.builder(
                  itemCount: group.items.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.45,
                  ),
                  itemBuilder: (BuildContext _, int index) {
                    final _ModuleItem item = group.items[index];
                    return InkWell(
                      onTap: () => context.go(item.path),
                      borderRadius: BorderRadius.circular(16),
                      child: Ink(
                        decoration: BoxDecoration(
                          color: NmbColors.background,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: NmbColors.divider),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Icon(item.icon,
                                color: NmbColors.accentDark, size: 28),
                            const Spacer(),
                            Text(item.title, style: NmbTypography.cardTitle),
                            Text(item.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: NmbTypography.caption),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (visible.isEmpty)
              NmbCard(
                child: Center(
                  child: Text(tr('No module found', 'कोई मॉड्यूल नहीं मिला')),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ModuleGroup {
  const _ModuleGroup(this.title, this.icon, this.items);
  final String title;
  final IconData icon;
  final List<_ModuleItem> items;
}

class _ModuleItem {
  const _ModuleItem(this.title, this.subtitle, this.icon, this.path);
  final String title;
  final String subtitle;
  final IconData icon;
  final String path;
}
