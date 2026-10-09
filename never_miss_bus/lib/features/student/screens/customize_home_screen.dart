import 'package:flutter/material.dart';

import '../../../core/constants/app_language.dart';
import '../../../core/constants/home_widgets.dart';
import '../../../core/theme/nmb_colors.dart';
import '../../../core/theme/nmb_typography.dart';

/// CUSTOMIZE HOME — widgets on/off + drag to reorder. Unique feature!
class CustomizeHomeScreen extends StatefulWidget {
  const CustomizeHomeScreen({super.key});

  @override
  State<CustomizeHomeScreen> createState() => _CustomizeHomeScreenState();
}

class _CustomizeHomeScreenState extends State<CustomizeHomeScreen> {
  late List<String> _enabled;
  late List<String> _disabled;

  @override
  void initState() {
    super.initState();
    _enabled = List<String>.from(HomeWidgetsConfig.config.value);
    _disabled = HomeWidgetsConfig.allWidgets
        .where((String w) => !_enabled.contains(w))
        .toList();
  }

  Future<void> _save() async {
    await HomeWidgetsConfig.save(_enabled);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1E8E3E),
          content: Text(
            tr('Home layout saved ✓', 'होम लेआउट सेव ✓'),
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Customize Home', 'होम कस्टमाइज़')),
        actions: <Widget>[
          TextButton(
            onPressed: _save,
            child: Text(tr('Save', 'सेव')),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: NmbColors.infoSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              tr(
                'Drag ≡ to reorder. Toggle off to hide a widget.',
                '≡ ko drag karke order badlo. Band karne ke liye toggle off.',
              ),
              style: NmbTypography.caption.copyWith(color: NmbColors.info),
            ),
          ),
          const SizedBox(height: 14),
          Text(tr('Shown on Home', 'होम पर दिखेंगे'),
              style: NmbTypography.sectionTitle,),
          const SizedBox(height: 8),
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onReorder: (int oldIndex, int newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final String item = _enabled.removeAt(oldIndex);
                _enabled.insert(newIndex, item);
              });
            },
            children: <Widget>[
              for (final String w in _enabled)
                Container(
                  key: ValueKey<String>(w),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: NmbColors.divider),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.drag_indicator_rounded,
                        color: NmbColors.textTertiary,),
                    title: Text(HomeWidgetsConfig.labelOf(w)),
                    trailing: Switch(
                      value: true,
                      onChanged: (_) => setState(() {
                        _enabled.remove(w);
                        _disabled.add(w);
                      }),
                    ),
                  ),
                ),
            ],
          ),
          if (_disabled.isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            Text(tr('Hidden', 'छुपे हुए'),
                style: NmbTypography.sectionTitle,),
            const SizedBox(height: 8),
            for (final String w in _disabled)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: NmbColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: NmbColors.divider),
                ),
                child: ListTile(
                  leading: const Icon(Icons.visibility_off_outlined,
                      color: NmbColors.textTertiary,),
                  title: Text(
                    HomeWidgetsConfig.labelOf(w),
                    style: const TextStyle(color: NmbColors.textTertiary),
                  ),
                  trailing: Switch(
                    value: false,
                    onChanged: (_) => setState(() {
                      _disabled.remove(w);
                      _enabled.add(w);
                    }),
                  ),
                ),
              ),
          ],
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
