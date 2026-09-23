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
        desiredAccuracy: LocationAccuracy.medium,
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

  String _severityLabel(OutbreakSeverity s) {
    switch (s) {
      case OutbreakSeverity.high:
        return 'HIGH';
      case OutbreakSeverity.moderate:
        return 'MODERATE';
      case OutbreakSeverity.low:
        return 'LOW';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundGradient,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: 14),
                    Text('Outbreak Map', style: AppTextStyles.heading(size: 18)),
                  ],
                ),
              ),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
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
          child: Row(
            children: [
              const Icon(Icons.location_off_outlined, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Could not get your location. Check permissions and try again.',
                  style: AppTextStyles.body(size: 13, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              height: 220,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: _userLocation!,
                  initialZoom: 11,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.plant_disease_detector',
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
                          child: Icon(Icons.warning_rounded, color: color, size: 30),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.info_outline, size: 12, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Sample outbreak data for demonstration — not live crowd-sourced reports',
                  style: AppTextStyles.body(size: 10, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          Text('Nearby Reports', style: AppTextStyles.heading(size: 15)),
          const SizedBox(height: 12),

          ..._zones.map((zone) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _severityColor(zone.severity).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.warning_rounded, color: _severityColor(zone.severity)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(zone.diseaseName, style: AppTextStyles.heading(size: 14)),
                        const SizedBox(height: 2),
                        Text('${zone.cropType} — ${zone.reportedCases} cases reported',
                            style: AppTextStyles.body(size: 11, color: AppColors.textSecondary)),
                        const SizedBox(height: 2),
                        Text('${zone.distanceKm} km away',
                            style: AppTextStyles.body(size: 11, color: AppColors.neonGreen)),
                      ],
                    ),
                  ),
                  NeonPill(
                    text: _severityLabel(zone.severity),
                    color: _severityColor(zone.severity),
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }
}