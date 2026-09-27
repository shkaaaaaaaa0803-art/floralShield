import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../models/scan_history_model.dart';
import '../providers/scan_provider.dart';
import '../theme/app_theme.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  bool _reminderEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadReminderState();
  }

  Future<void> _loadReminderState() async {
    final box = await Hive.openBox('app_settings');
    if (!mounted) return;
    setState(() {
      _reminderEnabled = box.get('daily_reminder_enabled', defaultValue: false);
    });
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.day}/${time.month}/${time.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundGradient,
        child: SafeArea(
          child: Consumer<ScanProvider>(
            builder: (context, provider, _) {
              final alerts = provider.history.where((h) => !h.isHealthy).toList()
                ..sort((a, b) => b.scannedAt.compareTo(a.scannedAt));

              return Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildReminderCard(),
                          const SizedBox(height: 20),
                          Text('Scan Alerts', style: AppTextStyles.heading(size: 15)),
                          const SizedBox(height: 4),
                          Text(
                            'Disease detections from your scan history',
                            style: AppTextStyles.body(size: 11, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 12),
                          if (alerts.isEmpty)
                            _buildEmptyState()
                          else
                            ...alerts.take(15).map((item) => _alertTile(item)),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          Text('Notifications', style: AppTextStyles.heading(size: 18)),
        ],
      ),
    );
  }

  Widget _buildReminderCard() {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      ).then((_) => _loadReminderState()),
      child: GlassCard(
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (_reminderEnabled ? AppColors.neonGreen : AppColors.textSecondary).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.notifications_active_outlined,
                color: _reminderEnabled ? AppColors.neonGreen : AppColors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Daily Care Reminder', style: AppTextStyles.body(size: 13, weight: FontWeight.w600)),
                  Text(
                    _reminderEnabled ? 'On — manage in Settings' : 'Off — tap to enable in Settings',
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
  }

  Widget _buildEmptyState() {
    return GlassCard(
      child: Column(
        children: [
          const Icon(Icons.notifications_none_rounded, color: AppColors.textSecondary, size: 36),
          const SizedBox(height: 12),
          Text('No alerts yet', style: AppTextStyles.heading(size: 14)),
          const SizedBox(height: 4),
          Text(
            'Disease detections from your scans will show up here.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body(size: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _alertTile(ScanHistoryModel item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const HistoryScreen()),
        ),
        child: GlassCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.neonRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bug_report_outlined, color: AppColors.neonRed, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.diseaseName} detected',
                      style: AppTextStyles.body(size: 13, weight: FontWeight.w600),
                    ),
                    Text(
                      '${item.plantName} · ${_timeAgo(item.scannedAt)}',
                      style: AppTextStyles.body(size: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 16, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}