import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/scan_provider.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';
  bool _reminderEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _loadReminderState();
  }

  Future<void> _loadReminderState() async {
    final box = await Hive.openBox('app_settings');
    setState(() {
      _reminderEnabled = box.get('daily_reminder_enabled', defaultValue: false);
    });
  }

  Future<void> _toggleReminder(bool value) async {
    if (value) {
      final granted = await NotificationService.requestPermission();
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notification permission denied', style: TextStyle(color: Colors.white)),
            backgroundColor: AppColors.textPrimary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      await NotificationService.enableDailyReminder();
    } else {
      await NotificationService.disableDailyReminder();
    }

    final box = await Hive.openBox('app_settings');
    await box.put('daily_reminder_enabled', value);
    setState(() => _reminderEnabled = value);
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      setState(() => _version = '${info.version} (${info.buildNumber})');
    } catch (e) {
      setState(() => _version = '1.0.0');
    }
  }

  void _confirmClearHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgDark,
        title: Text('Clear all scan history?', style: AppTextStyles.heading(size: 16)),
        content: Text(
          'This will permanently delete all your saved scans. This action cannot be undone.',
          style: AppTextStyles.body(size: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: AppTextStyles.body(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              await context.read<ScanProvider>().clearHistory();
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('History cleared', style: TextStyle(color: Colors.white)),
                    backgroundColor: AppColors.textPrimary,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text('Clear', style: AppTextStyles.body(color: AppColors.neonRed)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundGradient,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: 14),
                    Text('Settings', style: AppTextStyles.heading(size: 18)),
                  ],
                ),
                const SizedBox(height: 24),

                Text('ACCOUNT', style: AppTextStyles.label(size: 11)),
                const SizedBox(height: 10),
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    if (auth.isLoggedIn) {
                      return GlassCard(
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.neonGreen.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.person_outline, color: AppColors.neonGreen, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Signed in — syncing scans', style: AppTextStyles.body(size: 14, weight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text(
                                    auth.email ?? '',
                                    style: AppTextStyles.body(size: 11, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                await auth.signOut();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Signed out'), behavior: SnackBarBehavior.floating),
                                  );
                                }
                              },
                              child: Text('Sign Out', style: AppTextStyles.body(size: 12, color: AppColors.neonRed, weight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      );
                    }
                    return GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      ),
                      child: GlassCard(
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.accentTeal.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.login, color: AppColors.accentTeal, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Sign In / Create Account', style: AppTextStyles.body(size: 14, weight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Sync your scan history across devices',
                                    style: AppTextStyles.body(size: 11, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                Text('PREFERENCES', style: AppTextStyles.label(size: 11)),
                const SizedBox(height: 10),
                GlassCard(
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.neonGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.notifications_outlined, color: AppColors.neonGreen, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Daily Plant Care Reminder', style: AppTextStyles.body(size: 14, weight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text('Get a daily reminder to check your plants', style: AppTextStyles.body(size: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Switch(
                        value: _reminderEnabled,
                        onChanged: _toggleReminder,
                        activeColor: AppColors.neonGreen,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text('DATA', style: AppTextStyles.label(size: 11)),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _confirmClearHistory(context),
                  child: GlassCard(
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.neonRed.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.delete_sweep_outlined, color: AppColors.neonRed, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Clear Scan History', style: AppTextStyles.body(size: 14, weight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text('Permanently delete all saved scans', style: AppTextStyles.body(size: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text('ABOUT', style: AppTextStyles.label(size: 11)),
                const SizedBox(height: 10),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow('App Name', 'FloraShield AI'),
                      const SizedBox(height: 12),
                      _infoRow('Version', _version.isEmpty ? 'Loading...' : _version),
                      const SizedBox(height: 12),
                      _infoRow('Powered By', 'Google Gemini AI'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text('DISCLAIMER', style: AppTextStyles.label(size: 11)),
                const SizedBox(height: 10),
                GlassCard(
                  child: Text(
                    'Diagnoses and recommendations are AI-generated estimates and should not replace advice from a certified agricultural expert. Always confirm treatment dosages with product labels or local experts before application.',
                    style: AppTextStyles.body(size: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: AppTextStyles.body(size: 13, color: AppColors.textSecondary)),
        ),
        Text(value, style: AppTextStyles.body(size: 13, weight: FontWeight.w600)),
      ],
    );
  }
}