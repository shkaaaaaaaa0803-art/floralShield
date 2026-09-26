import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../providers/scan_provider.dart';
import '../providers/weather_provider.dart';
import '../models/weather_model.dart';
import '../models/scan_history_model.dart';
import '../data/demo_samples.dart';
import '../data/outbreak_data.dart';
import '../theme/app_theme.dart';
import 'capture_screen.dart';
import 'dosage_calculator_screen.dart';
import 'expert_connect_screen.dart';
import 'history_screen.dart';
import 'outbreak_map_screen.dart';
import 'quick_check_screen.dart';
import 'results_screen.dart';
import 'settings_screen.dart';
import 'voice_assistant_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<OutbreakZone> _nearbyOutbreaks = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WeatherProvider>().loadWeather();
      context.read<ScanProvider>().loadHistory();
    });
    _loadNearbyOutbreaks();
  }

  Future<void> _loadNearbyOutbreaks() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );
      final zones = OutbreakData.sampleZones(LatLng(position.latitude, position.longitude));
      if (mounted) {
        setState(() => _nearbyOutbreaks = zones);
      }
    } catch (_) {
      // Silent - best-effort highlight
    }
  }

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature — coming soon', style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.textPrimary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Color _confidenceColor(String label) {
    switch (label.toLowerCase()) {
      case 'high':
        return AppColors.neonGreen;
      case 'medium':
        return AppColors.neonAmber;
      default:
        return AppColors.neonRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ScanProvider>(
      builder: (context, provider, _) {
        final alertBanner = _buildOutbreakAlertBanner(context);
        return Scaffold(
          extendBody: true,
          body: Container(
            decoration: AppTheme.backgroundGradient,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, provider),
                    const SizedBox(height: 18),
                    _buildKrishiSaathiCard(context),
                    const SizedBox(height: 16),
                    _buildClimateCard(),
                    if (alertBanner != null) ...[
                      const SizedBox(height: 16),
                      alertBanner,
                    ],
                    const SizedBox(height: 20),
                    Text('Diagnostic Tools & Modules', style: AppTextStyles.heading(size: 15)),
                    const SizedBox(height: 2),
                    const Text(
                      'Everything you need for plant, produce & farm health',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    _buildModulesGrid(context, provider),
                    const SizedBox(height: 20),
                    _buildRecentScans(context, provider),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: _buildBottomNav(context),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, ScanProvider provider) {
    final hasAlert = _nearbyOutbreaks.any((z) => z.severity == OutbreakSeverity.high);
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(color: AppColors.neonGreen, shape: BoxShape.circle),
          child: const Icon(Icons.shield_outlined, color: Colors.white, size: 19),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('FloraShield AI', style: AppTextStyles.heading(size: 18)),
            Text('Dashboard', style: AppTextStyles.body(size: 10, color: AppColors.textSecondary)),
          ],
        ),
        const Spacer(),
        Text('Demo', style: AppTextStyles.body(size: 11, color: AppColors.textSecondary)),
        const SizedBox(width: 4),
        Switch(
          value: provider.isDemoMode,
          onChanged: (v) => provider.toggleDemoMode(v),
          activeThumbColor: AppColors.neonGreen,
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const OutbreakMapScreen()),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined, color: AppColors.textSecondary, size: 22),
                if (hasAlert)
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: AppColors.neonRed, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
          child: const Icon(Icons.settings_outlined, color: AppColors.textSecondary, size: 20),
        ),
      ],
    );
  }

  Widget _buildKrishiSaathiCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const VoiceAssistantScreen()),
      ),
      child: GlassCard(
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(color: AppColors.neonGreen, shape: BoxShape.circle),
              child: const Icon(Icons.mic, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Krishi Saathi AI', style: AppTextStyles.heading(size: 15)),
                  const SizedBox(height: 2),
                  Text(
                    'Ask a farming question, by voice or text',
                    style: AppTextStyles.body(size: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: 14),
          ],
        ),
      ),
    );
  }

  Widget? _buildOutbreakAlertBanner(BuildContext context) {
    final highSeverity = _nearbyOutbreaks.where((z) => z.severity == OutbreakSeverity.high).toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    if (highSeverity.isEmpty) return null;
    final zone = highSeverity.first;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const OutbreakMapScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.neonRed.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.neonRed.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.neonRed, size: 18),
                const SizedBox(width: 8),
                Text('NEARBY OUTBREAK ALERT', style: AppTextStyles.label(size: 10, color: AppColors.neonRed)),
                const Spacer(),
                const Text('Sample data', style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${zone.diseaseName} reported ${zone.distanceKm.toStringAsFixed(1)}km away',
              style: AppTextStyles.heading(size: 15, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              '${zone.reportedCases} cases affecting ${zone.cropType} nearby. Tap to view the outbreak map.',
              style: AppTextStyles.body(size: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  void _showDemoSamplePicker(BuildContext context, ScanProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(18),
          child: GlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Choose a demo sample', style: AppTextStyles.heading(size: 15)),
                const SizedBox(height: 4),
                Text(
                  'No internet needed — pre-loaded results',
                  style: AppTextStyles.body(size: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                ...List.generate(DemoSamples.samples.length, (i) {
                  final sample = DemoSamples.samples[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx); // close sheet
                        provider.runDemoScan(i);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ResultsScreen()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              sample.isHealthy ? Icons.eco : Icons.bug_report_outlined,
                              color: sample.isHealthy ? AppColors.neonGreen : AppColors.neonRed,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(sample.plantName, style: AppTextStyles.body(size: 13, weight: FontWeight.w600)),
                                  Text(
                                    sample.isHealthy ? 'Healthy' : sample.diseaseName,
                                    style: AppTextStyles.body(size: 11, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildClimateCard() {
    return Consumer<WeatherProvider>(
      builder: (context, weatherProvider, _) {
        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Climate Intelligence', style: AppTextStyles.heading(size: 15)),
                  const Spacer(),
                  if (weatherProvider.status == WeatherStatus.error)
                    GestureDetector(
                      onTap: () => weatherProvider.loadWeather(),
                      child: const Row(
                        children: [
                          Icon(Icons.refresh, size: 14, color: AppColors.neonAmber),
                          const SizedBox(width: 4),
                          Text('Retry', style: TextStyle(fontSize: 12, color: AppColors.neonAmber)),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              if (weatherProvider.status == WeatherStatus.loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.neonGreen),
                    ),
                  ),
                )
              else if (weatherProvider.status == WeatherStatus.error)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.location_off_outlined, color: AppColors.textSecondary, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Location/weather unavailable. Check permissions and internet.',
                          style: AppTextStyles.body(size: 12, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                )
              else if (weatherProvider.weather != null) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: _buildWeatherWidget(weatherProvider.weather!)),
                      const SizedBox(width: 10),
                      Expanded(flex: 5, child: _buildRiskGauge(weatherProvider.weather!)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildForecastRow(weatherProvider.weather!),
                ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeatherWidget(WeatherModel weather) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cloud_outlined, color: AppColors.textPrimary, size: 20),
          const SizedBox(height: 6),
          Text('${weather.temperature.toStringAsFixed(0)}°C', style: AppTextStyles.heading(size: 20)),
          Text(weather.cityName, style: AppTextStyles.body(size: 10, color: AppColors.textSecondary)),
          Text('Humidity: ${weather.humidity.toStringAsFixed(0)}%', style: AppTextStyles.body(size: 10, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildRiskGauge(WeatherModel weather) {
    final riskColor = weather.riskFraction >= 0.75
        ? AppColors.neonRed
        : weather.riskFraction >= 0.45
        ? AppColors.neonAmber
        : AppColors.neonGreen;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text('AI Risk Score', style: AppTextStyles.body(size: 9, color: AppColors.textSecondary), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          CircularGauge(fraction: weather.riskFraction, color: riskColor, size: 56),
          const SizedBox(height: 6),
          Text(weather.riskLabel, textAlign: TextAlign.center, style: AppTextStyles.label(size: 8, color: riskColor)),
        ],
      ),
    );
  }

  Widget _buildForecastRow(WeatherModel weather) {
    if (weather.forecast.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Disease Risk Forecast', style: AppTextStyles.body(size: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: CustomPaint(
            size: const Size(double.infinity, 40),
            painter: _SparklinePainter(
              values: weather.forecast.map((d) => d.riskFraction).toList(),
              color: AppColors.neonAmber,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: weather.forecast
              .map((d) => Text(d.dayLabel, style: AppTextStyles.body(size: 9, color: AppColors.textSecondary)))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildModulesGrid(BuildContext context, ScanProvider provider) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.80,
      children: [
        _moduleTile(
          context,
          icon: Icons.camera_alt_outlined,
          iconColor: AppColors.neonGreen,
          title: 'Crop Disease Scan',
          description: 'Diagnose disease from a leaf photo',
          actionLabel: 'Launch Scan',
          onTap: () {
            if (provider.isDemoMode) {
              _showDemoSamplePicker(context, provider);
            } else {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CaptureScreen()));
            }
          },
        ),
        _moduleTile(
          context,
          icon: Icons.map_outlined,
          iconColor: AppColors.neonRed,
          title: 'Outbreak Map',
          description: 'Nearby disease reports on a map',
          actionLabel: 'Inspect Map',
          badge: 'Sample Data',
          badgeColor: AppColors.textSecondary,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OutbreakMapScreen())),
        ),
        _moduleTile(
          context,
          icon: Icons.terrain_outlined,
          iconColor: AppColors.accentTeal,
          title: 'Soil Texture',
          description: 'Estimate soil texture from a photo',
          actionLabel: 'Check Soil',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const QuickCheckScreen(mode: QuickCheckMode.soilTexture)),
          ),
        ),
        _moduleTile(
          context,
          icon: Icons.calculate_outlined,
          iconColor: AppColors.neonAmber,
          title: 'Dosage Calc',
          description: 'Tank volume & dilution math',
          actionLabel: 'Calculate',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const DosageCalculatorScreen(
                diseaseName: 'General fungal treatment',
                isHealthy: false,
              ),
            ),
          ),
        ),
        _moduleTile(
          context,
          icon: Icons.eco_outlined,
          iconColor: AppColors.neonGreen,
          title: 'Freshness Scanner',
          description: 'Check ripeness of produce',
          actionLabel: 'Scan Produce',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const QuickCheckScreen(mode: QuickCheckMode.freshness)),
          ),
        ),
        _moduleTile(
          context,
          icon: Icons.pets_outlined,
          iconColor: AppColors.neonAmber,
          title: 'Pet Toxicity',
          description: 'Is this plant safe for pets?',
          actionLabel: 'Check Plant',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const QuickCheckScreen(mode: QuickCheckMode.petToxicity)),
          ),
        ),
        _moduleTile(
          context,
          icon: Icons.local_florist_outlined,
          iconColor: AppColors.neonGreenBright,
          title: 'Plant Identifier',
          description: 'Identify any plant species',
          actionLabel: 'Identify',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const QuickCheckScreen(mode: QuickCheckMode.plantId)),
          ),
        ),
        _moduleTile(
          context,
          icon: Icons.chat_bubble_outline,
          iconColor: AppColors.accentTeal,
          title: 'Expert Q&A',
          description: 'Find agri experts near you',
          actionLabel: 'Find Expert',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ExpertConnectScreen())),
        ),
        _moduleTile(
          context,
          icon: Icons.airplanemode_active_outlined,
          iconColor: AppColors.textSecondary,
          title: 'Drone Waypoints',
          description: 'KML export for spray drones',
          actionLabel: 'Coming Soon',
          badge: 'Soon',
          badgeColor: AppColors.neonAmber,
          onTap: () => _comingSoon('Drone Flight Waypoints'),
        ),
        _moduleTile(
          context,
          icon: Icons.shield_outlined,
          iconColor: AppColors.textSecondary,
          title: 'Insurance Claim',
          description: 'Generate a geo-tagged loss PDF',
          actionLabel: 'Coming Soon',
          badge: 'Soon',
          badgeColor: AppColors.neonAmber,
          onTap: () => _comingSoon('Insurance Claim PDF'),
        ),
      ],
    );
  }

  Widget _moduleTile(
      BuildContext context, {
        required IconData icon,
        required Color iconColor,
        required String title,
        required String description,
        required String actionLabel,
        String? badge,
        Color? badgeColor,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const Spacer(),
                if (badge != null) NeonPill(text: badge, color: badgeColor ?? AppColors.textSecondary),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: AppTextStyles.body(size: 13, weight: FontWeight.w700),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              description,
              style: AppTextStyles.body(size: 10.5, color: AppColors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                Text(actionLabel, style: AppTextStyles.label(size: 10, color: iconColor)),
                const SizedBox(width: 3),
                Icon(Icons.arrow_forward, size: 11, color: iconColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentScans(BuildContext context, ScanProvider provider) {
    final recent = provider.history.take(2).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Recent Scans', style: AppTextStyles.heading(size: 15)),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HistoryScreen())),
              child: Text('View All', style: AppTextStyles.body(size: 12, color: AppColors.neonGreen, weight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (recent.isEmpty)
          GlassCard(
            child: Row(
              children: [
                const Icon(Icons.history, color: AppColors.textSecondary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No scans yet — try Crop Disease Scan above',
                    style: AppTextStyles.body(size: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          )
        else
          ...recent.map((scan) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _recentScanRow(scan),
          )),
      ],
    );
  }

  Widget _recentScanRow(ScanHistoryModel scan) {
    return GlassCard(
      child: Row(
        children: [
          Icon(
            scan.isHealthy ? Icons.eco : Icons.bug_report_outlined,
            color: scan.isHealthy ? AppColors.neonGreen : AppColors.neonRed,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scan.isHealthy ? scan.plantName : scan.diseaseName,
                  style: AppTextStyles.body(size: 13, weight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${scan.plantName} • ${_timeAgo(scan.scannedAt)}',
                  style: AppTextStyles.body(size: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          NeonPill(text: scan.confidence, color: _confidenceColor(scan.confidence)),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: GlassCard(
        borderRadius: BorderRadius.circular(28),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _navIcon(Icons.home_filled, 'Home', active: true, onTap: () {}),
            _navIcon(Icons.bar_chart_outlined, 'Reports', onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            }),
            Consumer<ScanProvider>(
              builder: (context, provider, _) {
                return GestureDetector(
                  onTap: () {
                    if (provider.isDemoMode) {
                      _showDemoSamplePicker(context, provider);
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CaptureScreen()),
                      );
                    }
                  },
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: AppColors.neonGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white),
                  ),
                );
              },
            ),
            _navIcon(Icons.map_outlined, 'Map', onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const OutbreakMapScreen()),
            )),
            _navIcon(Icons.groups_outlined, 'Community', onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ExpertConnectScreen()),
            )),
          ],
        ),
      ),
    );
  }

  Widget _navIcon(IconData icon, String label, {bool active = false, required VoidCallback onTap}) {
    final color = active ? AppColors.neonGreen : AppColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.body(size: 9, color: color)),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;

  _SparklinePainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()..color = color;

    final path = Path();
    final stepX = size.width / (values.length - 1);

    for (int i = 0; i < values.length; i++) {
      final x = i * stepX;
      final y = size.height - (values[i] * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    for (int i = 0; i < values.length; i++) {
      final x = i * stepX;
      final y = size.height - (values[i] * size.height);
      canvas.drawCircle(Offset(x, y), 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) => oldDelegate.values != values;
}
