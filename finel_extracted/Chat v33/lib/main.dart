// t============================================================
// Jordan Audio Forum — main.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/app_provider.dart';
import 'theme/app_theme.dart';
import 'navigation/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // تعطيل Firebase مؤقتاً لاختبار التطبيق على الويب
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
  } catch (e) {
    print('Firebase error: $e');
  }
  runApp(const JordanAudioForumApp());
}

class JordanAudioForumApp extends StatefulWidget {
  const JordanAudioForumApp({super.key});
  @override
  State<JordanAudioForumApp> createState() => _JordanAudioForumAppState();
}

class _JordanAudioForumAppState extends State<JordanAudioForumApp> {
  // ✅ FIX: Providers and Router created ONCE — never recreated on rebuild
  late final AppProvider _appProvider;
  late final AuthProvider _authProvider;
  late final AppRouterConfig _routerConfig;

  @override
  void initState() {
    super.initState();
    _appProvider = AppProvider();
    _authProvider = AuthProvider();
    _routerConfig = AppRouterConfig(_appProvider, _authProvider);
  }

  @override
  void dispose() {
    _appProvider.dispose();
    _authProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _appProvider),
        ChangeNotifierProvider.value(value: _authProvider),
      ],
      child: MaterialApp.router(
        title: 'Jordan Audio Forum',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.classic,
        routerConfig: _routerConfig.router,
      ),
    );
  }
}
