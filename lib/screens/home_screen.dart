import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/scan_provider.dart';
import '../providers/weather_provider.dart';
import '../models/weather_model.dart';
import '../data/demo_samples.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WeatherProvider>().loadWeather();
    });
  }

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature — coming soon'),
        backgroundColor: AppColors.bgDark2,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ScanProvider>(
      builder: (context, provider, _) {
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
                    _buildHeader(provider),
                    const SizedBox(height: 18),
                    _buildClimateCard(),
                    const SizedBox(height: 16),
                    _buildActionGrid(context, provider),
                    const SizedBox(height: 16),
                    _buildOutbreakCard(),
                    const SizedBox(height: 20),
                    Text('Home & Kitchen Tools', style: AppTextStyles.heading(size: 15)),
                    const SizedBox(height: 2),
                    Text(
                      'Quick checks for everyday plant & produce care',
                      style: AppTextStyles.body(size: 11, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    _buildToolsGrid(context),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: _buildBottomNav(context),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: FloatingActionButton(
              backgroundColor: AppColors.neonGreen,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const VoiceAssistantScreen()),
              ),
              child: const Icon(Icons.mic, color: AppColors.bgDark),
            ),
          ),
        );
      },
    );
  }

  Widget _buildToolsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.7,
      children: [
        _toolTile(
          context,
          icon: Icons.eco_outlined,
          color: AppColors.neonGreen,
          label: 'Freshness\nScanner',
          mode: QuickCheckMode.freshness,
        ),
        _toolTile(
          context,
          icon: Icons.pets_outlined,
          color: AppColors.neonAmber,
          label: 'Pet Toxicity\nChecker',
          mode: QuickCheckMode.petToxicity,
        ),
        _toolTile(
          context,
          icon: Icons.terrain_outlined,
          color: AppColors.accentTeal,
          label: 'Soil Texture\nAnalysis',
          mode: QuickCheckMode.soilTexture,
        ),
        _toolTile(
          context,
          icon: Icons.local_florist_outlined,
          color: AppColors.neonGreenBright,
          label: 'Plant\nIdentifier',
          mode: QuickCheckMode.plantId,
        ),
      ],
    );
  }

  Widget _toolTile(
      BuildContext context, {
        required IconData icon,
        required Color color,
        required String label,
        required QuickCheckMode mode,
      }) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => QuickCheckScreen(mode: mode)),
      ),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(label, style: AppTextStyles.body(size: 12, weight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ScanProvider provider) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.neonGreen.withOpacity(0.28), AppColors.neonGreen.withOpacity(0.08)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.neonGreen.withOpacity(0.5)),
          ),
          child: const Icon(Icons.shield_outlined, color: AppColors.neonGreen, size: 19),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('PlantIQ', style: AppTextStyles.heading(size: 19)),
            Text('AI plant & produce care', style: AppTextStyles.body(size: 10, color: AppColors.textSecondary)),
          ],
        ),
        const Spacer(),
        Text('Demo Mode', style: AppTextStyles.body(size: 12, color: AppColors.textSecondary)),
        const SizedBox(width: 6),
        Switch(
          value: provider.isDemoMode,
          onChanged: (v) => provider.toggleDemoMode(v),
          activeColor: AppColors.neonGreen,
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
          child: const Icon(Icons.settings_outlined, color: AppColors.textSecondary, size: 20),
        ),
      ],
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
                          color: Colors.white.withOpacity(0.05),
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
                      child: Row(
                        children: [
                          Icon(Icons.refresh, size: 14, color: AppColors.neonAmber),
                          const SizedBox(width: 4),
                          Text('Retry', style: AppTextStyles.body(size: 12, color: AppColors.neonAmber)),
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
        color: Colors.white.withOpacity(0.05),
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
        color: Colors.white.withOpacity(0.05),
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

  Widget _buildActionGrid(BuildContext context, ScanProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildScanHero(context, provider),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.95,
          children: [
            _actionButtonCompact(
              icon: Icons.local_fire_department_outlined,
              label: 'Risk Heatmap',
              color: AppColors.neonAmber,
              onTap: () => _comingSoon('Risk Heatmap'),
            ),
            _actionButtonCompact(
              icon: Icons.calculate_outlined,
              label: 'Dosage Calc',
              color: AppColors.accentTeal,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const DosageCalculatorScreen(
                    diseaseName: 'General fungal treatment',
                    isHealthy: false,
                  ),
                ),
              ),
            ),
            _actionButtonCompact(
              icon: Icons.chat_bubble_outline,
              label: 'Expert Q&A',
              color: AppColors.textPrimary,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ExpertConnectScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Prominent hero card for the primary "scan a leaf" action — this is
  /// the app's main entry point, so it gets its own gradient-badged card
  /// instead of sitting flat in the grid with the secondary actions.
  Widget _buildScanHero(BuildContext context, ScanProvider provider) {
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
      child: GlassCard(
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.neonGreen, AppColors.neonGreenBright],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: AppColors.neonGreen.withOpacity(0.4), blurRadius: 16, spreadRadius: 1),
                ],
              ),
              child: const Icon(Icons.eco, color: AppColors.bgDark, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Scan Leaf AI', style: AppTextStyles.heading(size: 16)),
                  const SizedBox(height: 2),
                  Text(
                    'Diagnose disease from a photo in seconds',
                    style: AppTextStyles.body(size: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.neonGreen.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward, color: AppColors.neonGreen, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButtonCompact({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.body(size: 11, weight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutbreakCard() {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const OutbreakMapScreen()),
      ),
      child: GlassCard(
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.neonRed.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.map_outlined, color: AppColors.neonRed),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Disease Outbreak Map', style: AppTextStyles.heading(size: 14)),
                  const SizedBox(height: 2),
                  Text('12 cases reported near you', style: AppTextStyles.body(size: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
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
                    child: const Icon(Icons.camera_alt, color: AppColors.bgDark),
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

/// Simple sparkline/line-chart painter for the forecast row.
class _SparklinePainter extends CustomPainter {
  final List<double> values; // each 0.0 - 1.0
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