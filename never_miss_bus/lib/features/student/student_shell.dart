import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_language.dart';
import '../../core/widgets/state_views.dart';
import '../../models/app_user.dart';
import '../../providers/app_providers.dart';
import '../../providers/data_providers.dart';
import 'screens/change_password_screen.dart';

/// SRBS student shell — Dashboard · Modules · Track · Notifications · Account.
class StudentShell extends ConsumerWidget {
  const StudentShell({super.key, required this.shell});

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
    final int unread = ref.watch(unreadCountProvider);

    // FIRST-LOGIN GATE: jab tak student apna password nahi badalta,
    // poori app lock — sirf password screen (OTP ka free alternate).
    final AppUser? me = ref.watch(myProfileProvider).valueOrNull;
    if (me != null && me.mustChangePassword) {
      return const ChangePasswordScreen(forced: true);
    }

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
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (int index) => shell.goBranch(
            index,
            initialLocation: index == shell.currentIndex,
          ),
          destinations: <Widget>[
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_rounded),
              label: tr('Home', 'होम'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.grid_view_outlined),
              selectedIcon: const Icon(Icons.grid_view_rounded),
              label: tr('Modules', 'मॉड्यूल्स'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.map_outlined),
              selectedIcon: const Icon(Icons.map_rounded),
              label: tr('Track', 'ट्रैक'),
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: unread > 0,
                label: Text('$unread'),
                child: const Icon(Icons.notifications_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: unread > 0,
                label: Text('$unread'),
                child: const Icon(Icons.notifications_rounded),
              ),
              label: tr('Notifications', 'सूचनाएं'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline_rounded),
              selectedIcon: const Icon(Icons.person_rounded),
              label: tr('Account', 'अकाउंट'),
            ),
          ],
        ),
      ),
    );
  }
}
