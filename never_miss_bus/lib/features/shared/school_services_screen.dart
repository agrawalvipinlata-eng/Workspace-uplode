import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_language.dart';
import '../../core/theme/nmb_colors.dart';
import '../../core/theme/nmb_typography.dart';
import '../../core/widgets/nmb_card.dart';
import '../../core/widgets/responsive_scaffold_body.dart';
import '../../models/app_user.dart';
import '../../providers/app_providers.dart';
import '../../providers/data_providers.dart';
import '../../services/auth_service.dart';
import '../../services/school_services_service.dart';

class SchoolServicesScreen extends ConsumerStatefulWidget {
  const SchoolServicesScreen({super.key});

  @override
  ConsumerState<SchoolServicesScreen> createState() =>
      _SchoolServicesScreenState();
}

class _SchoolServicesScreenState extends ConsumerState<SchoolServicesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final TextEditingController _feedback = TextEditingController();
  String _category = 'General';
  int _rating = 5;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _feedback.dispose();
    super.dispose();
  }

  void _message(String text, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      backgroundColor: error ? NmbColors.danger : NmbColors.success,
    ));
  }

  Future<void> _sendFeedback() async {
    final AppUser? user = ref.read(myProfileProvider).valueOrNull;
    final AuthSession? session = ref.read(currentSessionProvider);
    final String message = _feedback.text.trim();
    if (message.isEmpty || user == null || session == null) {
      _message('Please write feedback first.', error: true);
      return;
    }
    setState(() => _sending = true);
    try {
      await ref.read(schoolServicesServiceProvider).submitFeedback(
            uid: session.uid,
            name: user.fullName,
            message: message,
            rating: _rating,
            category: _category,
          );
      _feedback.clear();
      _message('Feedback sent to the school. Thank you!');
    } catch (error) {
      _message('Feedback could not be sent: $error', error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _openLink(String url) async {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      _message('This school link is not configured yet.', error: true);
      return;
    }
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _message('Could not open this link.', error: true);
    }
  }

  Future<void> _order(Map<String, dynamic> item) async {
    final AppUser? user = ref.read(myProfileProvider).valueOrNull;
    final AuthSession? session = ref.read(currentSessionProvider);
    if (user == null || session == null) return;
    final List<String> sizes = (item['sizes'] is List)
        ? (item['sizes'] as List).whereType<String>().toList()
        : <String>['Standard'];
    String size = sizes.first;
    int quantity = 1;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) =>
            AlertDialog(
          title: Text('Order ${item['name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              DropdownButtonFormField<String>(
                value: size,
                decoration: const InputDecoration(labelText: 'Size'),
                items: sizes
                    .map((String value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        ))
                    .toList(),
                onChanged: (String? value) =>
                    setDialogState(() => size = value ?? size),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text('Quantity'),
                  Row(children: <Widget>[
                    IconButton(
                      onPressed: quantity > 1
                          ? () => setDialogState(() => quantity--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text('$quantity'),
                    IconButton(
                      onPressed: () => setDialogState(() => quantity++),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ]),
                ],
              ),
              Text('Total: ₹${((item['price'] as num?) ?? 0) * quantity}'),
              const SizedBox(height: 8),
              const Text(
                'This sends an order request to the school. Payment and final confirmation will be handled by the school.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Request Order'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(schoolServicesServiceProvider).placeDressOrder(
            uid: session.uid,
            name: user.fullName,
            itemId: '${item['id']}',
            itemName: '${item['name']}',
            size: size,
            quantity: quantity,
            unitPrice: ((item['price'] as num?) ?? 0).toDouble(),
            classSection: user.classSection,
          );
      _message('Order request sent to the school.');
    } catch (error) {
      _message('Order request failed: $error', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final SchoolServicesService service =
        ref.read(schoolServicesServiceProvider);
    return Scaffold(
      appBar: AppBar(title: Text(tr('School Services', 'स्कूल सेवाएँ'))),
      body: ResponsiveBody(
        scrollable: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('Connect with your school', style: NmbTypography.screenTitle),
            const SizedBox(height: 4),
            Text('Feedback, official links and uniform shop',
                style: NmbTypography.bodySecondary),
            const SizedBox(height: 14),
            TabBar(
              controller: _tabs,
              isScrollable: true,
              tabs: const <Widget>[
                Tab(icon: Icon(Icons.feedback_rounded), text: 'Feedback'),
                Tab(icon: Icon(Icons.public_rounded), text: 'Social Links'),
                Tab(icon: Icon(Icons.shopping_bag_rounded), text: 'Dress Shop'),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: <Widget>[
                  _feedbackTab(),
                  _socialTab(service),
                  _shopTab(service),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _feedbackTab() => ListView(
        children: <Widget>[
          NmbCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text('How was your school experience?',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: const <String>[
                    'General',
                    'Teaching',
                    'Transport',
                    'Library',
                    'App'
                  ]
                      .map((String value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          ))
                      .toList(),
                  onChanged: (String? value) =>
                      setState(() => _category = value ?? 'General'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _feedback,
                  minLines: 4,
                  maxLines: 7,
                  decoration: const InputDecoration(
                    labelText: 'Your feedback',
                    hintText: 'Tell the school what can be improved…',
                  ),
                ),
                const SizedBox(height: 12),
                Row(children: <Widget>[
                  const Text('Rating'),
                  const SizedBox(width: 8),
                  for (int i = 1; i <= 5; i++)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() => _rating = i),
                      icon: Icon(i <= _rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded),
                      color: Colors.amber.shade700,
                    ),
                ]),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _sending ? null : _sendFeedback,
                  icon: const Icon(Icons.send_rounded),
                  label: Text(_sending ? 'Sending…' : 'Send Feedback'),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _socialTab(SchoolServicesService service) =>
      StreamBuilder<List<Map<String, dynamic>>>(
        stream: service.watchSocialLinks(),
        builder: (BuildContext context,
            AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          final List<Map<String, dynamic>> links = snapshot.hasError ||
                  (snapshot.connectionState == ConnectionState.active &&
                      (snapshot.data?.isEmpty ?? true))
              ? SchoolServicesService.demoSocialLinks
              : (snapshot.data ?? SchoolServicesService.demoSocialLinks);
          return ListView(
            children: <Widget>[
              NmbCard(
                child: Text(
                  'Tap an official school link to open it. Links are managed by the school.',
                  style: NmbTypography.bodySecondary,
                ),
              ),
              const SizedBox(height: 10),
              for (final Map<String, dynamic> link in links)
                _serviceTile(
                  icon: _socialIcon('${link['platform']}'),
                  title: '${link['title']}',
                  subtitle: '${link['url']}'.isEmpty
                      ? 'School link will appear here'
                      : '${link['url']}',
                  enabled: '${link['url']}'.isNotEmpty,
                  onTap: () => _openLink('${link['url']}'),
                ),
            ],
          );
        },
      );

  Widget _shopTab(SchoolServicesService service) =>
      StreamBuilder<List<Map<String, dynamic>>>(
        stream: service.watchDressItems(),
        builder: (BuildContext context,
            AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          final List<Map<String, dynamic>> items = snapshot.hasError ||
                  (snapshot.connectionState == ConnectionState.active &&
                      (snapshot.data?.isEmpty ?? true))
              ? SchoolServicesService.demoDressItems
              : (snapshot.data ?? SchoolServicesService.demoDressItems);
          return ListView(
            children: <Widget>[
              NmbCard(
                child: Row(children: <Widget>[
                  Icon(Icons.info_outline_rounded, color: NmbColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'View official prices and request your uniform. Final availability and payment are confirmed by the school.',
                      style: NmbTypography.bodySecondary,
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 10),
              for (final Map<String, dynamic> item in items)
                NmbCard(
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: NmbColors.primarySoft,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.checkroom_rounded,
                            color: NmbColors.primary, size: 30),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('${item['name']}',
                                style: NmbTypography.cardTitle),
                            Text('${item['description'] ?? ''}',
                                style: NmbTypography.bodySecondary),
                            const SizedBox(height: 4),
                            Text('₹${item['price'] ?? 0}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 16)),
                          ],
                        ),
                      ),
                      FilledButton(
                        onPressed: (item['stock'] as num? ?? 0) > 0
                            ? () => _order(item)
                            : null,
                        child: const Text('Order'),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      );

  Widget _serviceTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool enabled,
    required VoidCallback onTap,
  }) =>
      NmbCard(
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: NmbColors.primarySoft,
            child: Icon(icon, color: NmbColors.primary),
          ),
          title: Text(title, style: NmbTypography.cardTitle),
          subtitle:
              Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing:
              Icon(enabled ? Icons.open_in_new_rounded : Icons.lock_outline),
          onTap: enabled ? onTap : null,
        ),
      );

  IconData _socialIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return Icons.camera_alt_rounded;
      case 'facebook':
        return Icons.facebook_rounded;
      case 'youtube':
        return Icons.play_circle_fill_rounded;
      default:
        return Icons.language_rounded;
    }
  }
}
