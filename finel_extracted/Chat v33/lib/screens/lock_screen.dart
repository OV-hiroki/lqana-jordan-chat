// ============================================================
// Jordan Audio Forum — LockScreen
// ============================================================

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';

class LockScreen extends StatelessWidget {
  final String message;
  const LockScreen({super.key, this.message = ''});

  @override
  Widget build(BuildContext context) {
    final msg = message.isNotEmpty ? message : AppConstants.killSwitchDefaultMsg;
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120, height: 120,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryMuted, shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock, size: 56, color: AppColors.primary),
                ),
                const SizedBox(height: 32),
                const Text('التطبيق غير متاح حالياً',
                  style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary, fontFamily: 'Cairo',
                  )),
                const SizedBox(height: 16),
                Text(msg, textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15, color: AppColors.textSecondary,
                    fontFamily: 'Cairo', height: 1.6,
                  )),
                const SizedBox(height: 32),
                Container(height: 1, width: 60, color: AppColors.borderDefault),
                const SizedBox(height: 24),
                const Text('للتواصل مع الدعم:',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontFamily: 'Cairo')),
                const SizedBox(height: 6),
                const Text(AppConstants.supportEmail,
                  style: TextStyle(color: AppColors.primary, fontSize: 14,
                    fontWeight: FontWeight.w600, fontFamily: 'Cairo')),
                const Spacer(),
                Text('${AppConstants.appName} v${AppConstants.appVersion}',
                  style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 12, fontFamily: 'Cairo')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
