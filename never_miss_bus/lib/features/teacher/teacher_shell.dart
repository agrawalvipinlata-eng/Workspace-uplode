import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_language.dart';
import '../../core/widgets/state_views.dart';
import '../../providers/app_providers.dart';

/// TEACHER PANEL — bilkul alag, simple 3-tab shell (admin drawer NAHI):
/// My Class · Attendance · Profile. Teacher ko sirf apni class ka kaam.
class TeacherShell extends ConsumerWidget {
  const TeacherShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  void _handleBack(BuildContext context) {
    final GoRouter router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }
    if (shell.currentIndex != 0) {
      shell.goBranch(0);
      return;
    }
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool online = ref.watch(isOnlineProvider).valueOrNull ?? true;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) _handleBack(context);
      },
      child: Scaffold(
        body: Column(
          children: <Widget>[
            if (!online) const OfflineBanner(),
            Expanded(child: shell),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (int index) => shell.goBranch(
            index,
            initialLocation: index == shell.currentIndex,
          ),
          destinations: <Widget>[
            NavigationDestination(
              icon: const Icon(Icons.groups_outlined),
              selectedIcon: const Icon(Icons.groups_rounded),
              label: tr('My Class', 'मेरी क्लास'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.fact_check_outlined),
              selectedIcon: const Icon(Icons.fact_check_rounded),
              label: tr('Attendance', 'हाज़िरी'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.mark_email_unread_outlined),
              selectedIcon: const Icon(Icons.mark_email_unread_rounded),
              label: tr('Applications', 'अर्ज़ियाँ'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline_rounded),
              selectedIcon: const Icon(Icons.person_rounded),
              label: tr('Profile', 'प्रोफ़ाइल'),
            ),
          ],
        ),
      ),
    );
  }
}
