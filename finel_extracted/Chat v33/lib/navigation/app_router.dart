// ============================================================
// Jordan Audio Forum — App Router
// ✅ v24: 4-tab nav: الغرف | المفضلة | بحث | المزيد
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/app_provider.dart';
import '../screens/lock_screen.dart';
import '../screens/main_shell.dart';
import '../screens/home/home_screen.dart';
import '../screens/room/room_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/admin/admin_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/more/more_screen.dart';
import '../screens/favorites/favorites_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/settings/settings_screen.dart';

class AppRouterConfig {
  final AppProvider  _appProvider;
  final AuthProvider _authProvider;
  late final GoRouter router;

  AppRouterConfig(this._appProvider, this._authProvider) {
    router = GoRouter(
      initialLocation: '/loading',
      refreshListenable: Listenable.merge([_appProvider, _authProvider]),
      redirect: _redirect,
      routes: _routes,
    );
  }

  String? _redirect(BuildContext ctx, GoRouterState state) {
    final isReady    = _appProvider.isReady;
    final isLocked   = _appProvider.isLocked;
    final authStatus = _authProvider.status;
    final loc        = state.matchedLocation;

    if (!isReady || authStatus == AuthStatus.loading) {
      return loc == '/loading' ? null : '/loading';
    }
    if (isLocked) {
      return loc == '/locked' ? null : '/locked';
    }
    if (authStatus == AuthStatus.unauthenticated) {
      if (loc == '/login' || loc == '/register' || loc == '/settings') return null;
      return '/login';
    }
    if (authStatus == AuthStatus.authenticated) {
      if (loc == '/loading' || loc == '/locked') return '/';
      final isGuest = _authProvider.isGuest;
      if (!isGuest && (loc == '/login' || loc == '/register')) return '/';
      return null;
    }
    return loc == '/loading' ? null : '/loading';
  }

  List<RouteBase> get _routes => [
    GoRoute(path: '/loading', builder: (_, __) => const _LoadingScreen()),
    GoRoute(path: '/locked',  builder: (_, state) {
      final msg = (state.extra as String?) ?? '';
      return LockScreen(message: msg);
    }),

    // ── Auth screens ─────────────────────────────────────────
    GoRoute(path: '/login',    builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

    // ── Admin (outside shell) ─────────────────────────────────
    GoRoute(path: '/admin', builder: (_, __) => const AdminScreen()),

    // ── Main app shell (4-tab bottom nav) ───────────────
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/',          builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/favorites', builder: (_, __) => const FavoritesScreen()),
        GoRoute(path: '/search',    builder: (_, __) => const SearchScreen()),
        GoRoute(path: '/more',      builder: (_, __) => const MoreScreen()),
        GoRoute(path: '/profile',   builder: (_, __) => const ProfileScreen()),
      ],
    ),

    // ── Settings (accessible without login) ─────────────
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),

    // ── Room screen ──────────────────────────────────────────
    GoRoute(
      path: '/room/:roomId',
      builder: (context, state) => RoomScreen(
        roomId: state.pathParameters['roomId']!,
        isHost: state.extra == true,
      ),
    ),
  ];
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();
  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: Color(0xFFECECEC),
    body: Center(child: CircularProgressIndicator(color: Color(0xFFEB4C72))),
  );
}
