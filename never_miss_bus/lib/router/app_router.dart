import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/enums.dart';
import '../features/admin/admin_shell.dart';
import '../features/admin/screens/admin_audit_logs_screen.dart';
import '../features/admin/screens/admin_error_reports_screen.dart';
import '../features/admin/screens/admin_buses_screen.dart';
import '../features/admin/screens/admin_dashboard_screen.dart';
import '../features/admin/screens/admin_documents_screen.dart';
import '../features/admin/screens/admin_results_screen.dart';
import '../features/admin/screens/admin_timetable_screen.dart';
import '../features/admin/screens/admin_notice_board_screen.dart';
import '../features/admin/screens/admin_drivers_screen.dart';
import '../features/admin/screens/admin_monitoring_screen.dart';
import '../features/admin/screens/admin_notifications_screen.dart';
import '../features/admin/screens/admin_routes_stops_screen.dart';
import '../features/admin/screens/admin_settings_screen.dart';
import '../features/admin/screens/admin_students_screen.dart';
import '../features/admin/screens/admin_teachers_screen.dart';
import '../features/admin/screens/teacher_attendance_screen.dart';
import '../features/admin/screens/admin_trip_history_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/splash_screen.dart';
import '../features/driver/driver_shell.dart';
import '../features/driver/screens/driver_home_screen.dart';
import '../features/driver/screens/driver_profile_screen.dart';
import '../features/driver/screens/driver_route_screen.dart';
import '../features/student/student_shell.dart';
import '../features/teacher/teacher_shell.dart';
import '../features/teacher/screens/teacher_class_screen.dart';
import '../features/teacher/screens/teacher_applications_screen.dart';
import '../features/teacher/screens/teacher_profile_screen.dart';
import '../features/teacher/screens/teacher_schoolwork_screen.dart';
import '../features/student/screens/homework_screen.dart';
import '../features/student/screens/student_alerts_screen.dart';
import '../features/student/screens/student_bus_details_screen.dart';
import '../features/student/screens/student_home_screen.dart';
import '../features/student/screens/student_map_screen.dart';
import '../features/student/screens/student_modules_screen.dart';
import '../features/student/screens/parent_dashboard_screen.dart';
import '../features/student/screens/student_results_screen.dart';
import '../features/student/screens/student_timetable_screen.dart';
import '../features/student/screens/student_notice_board_screen.dart';
import '../features/student/screens/student_fee_receipt_screen.dart';
import '../features/student/screens/student_profile_screen.dart';
import '../features/shared/privacy_policy_screen.dart';
import '../features/student/screens/change_password_screen.dart';
import '../features/student/screens/customize_home_screen.dart';
import '../features/student/screens/leave_application_screen.dart';
import '../features/student/screens/my_attendance_screen.dart';
import '../features/student/screens/student_settings_screen.dart';
import '../features/student/screens/student_stops_screen.dart';
import '../providers/app_providers.dart';
import '../services/auth_service.dart';

/// Role-aware router. The redirect runs on EVERY navigation and every auth
/// change, so:
///  - signed-out users can only reach /login,
///  - each role is fenced into its own subtree (a student typing an /admin
///    URL is bounced home),
///  - expired/revoked sessions bounce to /login automatically.
/// This is UX-level fencing only — real enforcement lives in backend rules.
final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((Ref ref) {
  final ValueNotifier<int> refresh = ValueNotifier<int>(0);
  ref.listen(sessionProvider, (Object? _, Object? __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (BuildContext context, GoRouterState state) {
      final AsyncValue<AuthSession?> async = ref.read(sessionProvider);
      if (async.isLoading) {
        return state.matchedLocation == '/splash' ? null : '/splash';
      }
      final AuthSession? session = async.valueOrNull;
      final String loc = state.matchedLocation;
      final bool onAuthScreen = loc == '/login' || loc == '/splash';

      if (loc == '/splash') return null;
      if (session == null) return onAuthScreen ? null : '/login';

      final String home = switch (session.role) {
        UserRole.student => '/student/home',
        UserRole.driver => '/driver/home',
        UserRole.teacher => '/teacher/class', // teacher ka ALAG panel
        UserRole.admin => '/admin/dashboard',
      };
      if (onAuthScreen) return home;

      final String fence = '/${session.role.name}';
      if (!loc.startsWith(fence)) return home;
      return null;
    },
    routes: <RouteBase>[
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),

      // ── Student shell ────────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (_, __, StatefulNavigationShell shell) =>
            StudentShell(shell: shell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/student/home',
                builder: (_, __) => const StudentHomeScreen(),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'bus',
                    builder: (_, __) => const StudentBusDetailsScreen(),
                  ),
                  GoRoute(
                    path: 'stops',
                    builder: (_, __) => const StudentStopsScreen(),
                  ),
                  GoRoute(
                    path: 'customize',
                    builder: (_, __) => const CustomizeHomeScreen(),
                  ),
                  GoRoute(
                    path: 'leave',
                    builder: (_, __) => const LeaveApplicationScreen(),
                  ),
                  GoRoute(
                    path: 'attendance',
                    builder: (_, __) => const MyAttendanceScreen(),
                  ),
                  GoRoute(
                    path: 'homework',
                    builder: (_, __) => const HomeworkScreen(),
                  ),
                  GoRoute(
                    path: 'parent-dashboard',
                    builder: (_, __) => const ParentDashboardScreen(),
                  ),
                  GoRoute(
                    path: 'results',
                    builder: (_, __) => const StudentResultsScreen(),
                  ),
                  GoRoute(
                    path: 'timetable',
                    builder: (_, __) => const StudentTimetableScreen(),
                  ),
                  GoRoute(
                    path: 'notices',
                    builder: (_, __) => const StudentNoticeBoardScreen(),
                  ),
                  GoRoute(
                    path: 'fees',
                    builder: (_, __) => const StudentFeeReceiptScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/student/modules',
                builder: (_, __) => const StudentModulesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/student/map',
                builder: (_, __) => const StudentMapScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/student/alerts',
                builder: (_, __) => const StudentAlertsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/student/profile',
                builder: (_, __) => const StudentProfileScreen(),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'settings',
                    builder: (_, __) => const StudentSettingsScreen(),
                  ),
                  GoRoute(
                    path: 'privacy',
                    builder: (_, __) => const PrivacyPolicyScreen(),
                  ),
                  GoRoute(
                    path: 'password',
                    builder: (_, __) =>
                        const ChangePasswordScreen(forced: true),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // ── Teacher shell (ALAG panel — admin nahi) ──────────────────────
      StatefulShellRoute.indexedStack(
        builder: (_, __, StatefulNavigationShell shell) =>
            TeacherShell(shell: shell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/teacher/class',
                builder: (_, __) => const TeacherClassScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/teacher/attendance',
                builder: (_, __) => const TeacherAttendanceScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/teacher/applications',
                builder: (_, __) => const TeacherApplicationsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/teacher/profile',
                builder: (_, __) => const TeacherProfileScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/teacher/schoolwork',
                builder: (_, __) => const TeacherSchoolworkScreen(),
              ),
            ],
          ),
        ],
      ),

      // ── Driver shell ─────────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (_, __, StatefulNavigationShell shell) =>
            DriverShell(shell: shell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/driver/home',
                builder: (_, __) => const DriverHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/driver/route',
                builder: (_, __) => const DriverRouteScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/driver/profile',
                builder: (_, __) => const DriverProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // ── Admin shell ──────────────────────────────────────────────────
      ShellRoute(
        builder: (_, __, Widget child) => AdminShell(child: child),
        routes: <RouteBase>[
          GoRoute(
            path: '/admin/dashboard',
            builder: (_, __) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/students',
            builder: (_, __) => const AdminStudentsScreen(),
          ),
          GoRoute(
            path: '/admin/documents',
            builder: (_, __) => const AdminDocumentsScreen(),
          ),
          GoRoute(
            path: '/admin/results',
            builder: (_, __) => const AdminResultsScreen(),
          ),
          GoRoute(
            path: '/admin/timetable',
            builder: (_, __) => const AdminTimetableScreen(),
          ),
          GoRoute(
            path: '/admin/notices',
            builder: (_, __) => const AdminNoticeBoardScreen(),
          ),
          GoRoute(
            path: '/admin/attendance',
            builder: (_, __) => const TeacherAttendanceScreen(),
          ),
          GoRoute(
            path: '/admin/teachers',
            builder: (_, __) => const AdminTeachersScreen(),
          ),
          GoRoute(
            path: '/admin/drivers',
            builder: (_, __) => const AdminDriversScreen(),
          ),
          GoRoute(
            path: '/admin/buses',
            builder: (_, __) => const AdminBusesScreen(),
          ),
          GoRoute(
            path: '/admin/routes',
            builder: (_, __) => const AdminRoutesStopsScreen(),
          ),
          GoRoute(
            path: '/admin/monitoring',
            builder: (_, __) => const AdminMonitoringScreen(),
          ),
          GoRoute(
            path: '/admin/notifications',
            builder: (_, __) => const AdminNotificationsScreen(),
          ),
          GoRoute(
            path: '/admin/trips',
            builder: (_, __) => const AdminTripHistoryScreen(),
          ),
          GoRoute(
            path: '/admin/errors',
            builder: (_, __) => const AdminErrorReportsScreen(),
          ),
          GoRoute(
            path: '/admin/audit',
            builder: (_, __) => const AdminAuditLogsScreen(),
          ),
          GoRoute(
            path: '/admin/settings',
            builder: (_, __) => const AdminSettingsScreen(),
          ),
        ],
      ),
    ],
  );
});
