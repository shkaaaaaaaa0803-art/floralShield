import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../data/outbreak_data.dart';
import '../theme/app_theme.dart';

class OutbreakMapScreen extends StatefulWidget {
  const OutbreakMapScreen({super.key});

  @override
  State<OutbreakMapScreen> createState() => _OutbreakMapScreenState();
}

class _OutbreakMapScreenState extends State<OutbreakMapScreen> {
  LatLng? _userLocation;
  List<OutbreakZone> _zones = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services disabled');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      final userLocation = LatLng(position.latitude, position.longitude);

      setState(() {
        _userLocation = userLocation;
        _zones = OutbreakData.sampleZones(userLocation);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Color _severityColor(OutbreakSeverity s) {
    switch (s) {
      case OutbreakSeverity.high:
        return AppColors.neonRed;
      case OutbreakSeverity.moderate:
        return AppColors.neonAmber;
      case OutbreakSeverity.low:
        return AppColors.neonGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundGradient,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildBody()),
            ],
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Alerts & Monitoring', style: AppTextStyles.heading(size: 18)),
              Text('Real-time agricultural risk map', style: AppTextStyles.body(size: 11, color: AppColors.textSecondary)),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.layers_outlined, color: AppColors.textPrimary, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.neonGreen, strokeWidth: 2),
      );
    }

    if (_error != null || _userLocation == null) {
      return Padding(
        padding: const EdgeInsets.all(18),
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_off_outlined, color: AppColors.textSecondary, size: 48),
              const SizedBox(height: 16),
              Text(
                'Location Access Required',
                style: AppTextStyles.heading(size: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'To view nearby outbreaks and field stats, please enable location permissions.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body(size: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _load(),
                  child: const Text('RETRY ACCESS'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Red Alert Banner (Mockup #4)
          _buildAlertBanner(),
          const SizedBox(height: 16),

          // 2. Map Widget
          _buildMapCard(),
          const SizedBox(height: 16),

          // 3. Field Stats Row
          _buildFieldStats(),
          const SizedBox(height: 16),

          // 4. Canopy Vigor Trend (Chart)
          _buildCanopyVigorChart(),
          const SizedBox(height: 16),

          // 5. Bio-Agronomy Remediation Tip
          _buildRemediationTip(),
          const SizedBox(height: 24),

          // 6. Sensor Cluster List
          Text('Active Sensor Clusters', style: AppTextStyles.heading(size: 15)),
          const SizedBox(height: 12),
          _buildSensorList(),
        ],
      ),
    );
  }

  Widget _buildAlertBanner() {
    final highSeverity = _zones.where((z) => z.severity == OutbreakSeverity.high).toList();
    if (highSeverity.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.neonRed,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonRed.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '10KM RADIUS ALERT',
                  style: AppTextStyles.label(size: 10, color: Colors.white.withValues(alpha: 0.8)),
                ),
                const SizedBox(height: 2),
                Text(
                  '${highSeverity.first.diseaseName} Detected',
                  style: AppTextStyles.heading(size: 15, color: Colors.white),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white, size: 20),
        ],
      ),
    );
  }

  Widget _buildMapCard() {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: SizedBox(
              height: 180,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: _userLocation!,
                  initialZoom: 12,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.plant_disease_detector',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _userLocation!,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.my_location, color: AppColors.neonGreen, size: 28),
                      ),
                      ..._zones.map((zone) {
                        final color = _severityColor(zone.severity);
                        return Marker(
                          point: LatLng(zone.lat, zone.lng),
                          width: 40,
                          height: 40,
                          child: Icon(Icons.warning_rounded, color: color, size: 24),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.satellite_alt_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text('SATELLITE NDVI OVERLAY ACTIVE', style: AppTextStyles.label(size: 9)),
                const Spacer(),
                const Icon(Icons.refresh, size: 14, color: AppColors.neonGreen),
                const SizedBox(width: 4),
                Text('LIVE', style: AppTextStyles.label(size: 9, color: AppColors.neonGreen)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldStats() {
    return Row(
      children: [
        Expanded(child: _statItem('Affected Zone', '12.4%', Icons.area_chart_outlined, AppColors.neonRed)),
        const SizedBox(width: 12),
        Expanded(child: _statItem('Avg Humidity', '68%', Icons.water_drop_outlined, AppColors.accentTeal)),
        const SizedBox(width: 12),
        Expanded(child: _statItem('Spread Risk', 'High', Icons.trending_up, AppColors.neonAmber)),
      ],
    );
  }

  Widget _statItem(String label, String value, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.heading(size: 16)),
          Text(label, style: AppTextStyles.body(size: 9, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildCanopyVigorChart() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('14-Day Canopy Vigor Trend', style: AppTextStyles.heading(size: 14)),
              Text('NDVI Index', style: AppTextStyles.label(size: 9)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 60,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(14, (i) {
                final double height = [40.0, 45.0, 42.0, 38.0, 30.0, 25.0, 22.0, 24.0, 28.0, 35.0, 42.0, 50.0, 55.0, 52.0][i];
                final bool isWarning = i >= 4 && i <= 7;
                return Container(
                  width: 14,
                  height: height,
                  decoration: BoxDecoration(
                    color: isWarning ? AppColors.neonRed.withValues(alpha: 0.6) : AppColors.neonGreen.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sep 01', style: AppTextStyles.body(size: 9, color: AppColors.textSecondary)),
              Text('Outbreak Peak', style: AppTextStyles.body(size: 9, color: AppColors.neonRed, weight: FontWeight.w600)),
              Text('Today', style: AppTextStyles.body(size: 9, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRemediationTip() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentTeal.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accentTeal.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, color: AppColors.accentTeal, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bio-Agronomy Tip', style: AppTextStyles.heading(size: 14, color: AppColors.accentTeal)),
                const SizedBox(height: 4),
                Text(
                  'High humidity expected tonight. Apply prophylactic copper-based fungicide to prevents spore germination in the lower canopy.',
                  style: AppTextStyles.body(size: 12, color: AppColors.textPrimary.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorList() {
    return Column(
      children: [
        _sensorItem('Cluster Alpha-7', 'Online', '0.4km', true),
        const SizedBox(height: 8),
        _sensorItem('Cluster Beta-2', 'Offline', '1.2km', false),
        const SizedBox(height: 8),
        _sensorItem('Irrigation Node 4', 'Online', '2.1km', true),
      ],
    );
  }

  Widget _sensorItem(String name, String status, String dist, bool online) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: online ? AppColors.neonGreen : AppColors.textSecondary.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(name, style: AppTextStyles.body(size: 13, weight: FontWeight.w600)),
          ),
          Text(dist, style: AppTextStyles.body(size: 12, color: AppColors.textSecondary)),
          const SizedBox(width: 12),
          const Icon(Icons.chevron_right, size: 16, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}