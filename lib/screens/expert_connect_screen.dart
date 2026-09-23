import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/expert_data.dart';
import '../services/expert_service.dart';
import '../theme/app_theme.dart';

class ExpertConnectScreen extends StatefulWidget {
  const ExpertConnectScreen({super.key});

  @override
  State<ExpertConnectScreen> createState() => _ExpertConnectScreenState();
}

class _ExpertConnectScreenState extends State<ExpertConnectScreen> {
  final ExpertService _expertService = ExpertService();

  LatLng? _userLocation;
  List<ExpertLocation> _experts = [];
  bool _loading = true;
  bool _usingSampleData = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEverything();
  }

  Future<void> _loadEverything() async {
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

      // Try fetching real nearby locations from OpenStreetMap
      final realResults = await _expertService.fetchNearby(userLocation);

      setState(() {
        _userLocation = userLocation;
        if (realResults.isNotEmpty) {
          _experts = realResults;
          _usingSampleData = false;
        } else {
          // Fallback: no real data found nearby (common in areas with
          // sparse OpenStreetMap coverage)
          _experts = ExpertData.sampleLocations(userLocation);
          _usingSampleData = true;
        }
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _callExpert(String phone) async {
    if (phone == 'Not listed') return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
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
                    Text('Expert Connect', style: AppTextStyles.heading(size: 18)),
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
                  initialZoom: 12,
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
                      ..._experts.map((expert) {
                        return Marker(
                          point: LatLng(expert.lat, expert.lng),
                          width: 36,
                          height: 36,
                          child: const Icon(Icons.location_on, color: AppColors.neonRed, size: 32),
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
              Icon(
                _usingSampleData ? Icons.info_outline : Icons.verified_outlined,
                size: 12,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                _usingSampleData
                    ? 'No mapped locations found nearby — showing sample data'
                    : 'Live data from OpenStreetMap',
                style: AppTextStyles.body(size: 10, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 18),

          Text('Nearby Experts', style: AppTextStyles.heading(size: 15)),
          const SizedBox(height: 12),

          ..._experts.map((expert) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.neonGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.support_agent, color: AppColors.neonGreen),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(expert.name, style: AppTextStyles.heading(size: 14)),
                        const SizedBox(height: 2),
                        Text(expert.type, style: AppTextStyles.body(size: 11, color: AppColors.textSecondary)),
                        const SizedBox(height: 2),
                        Text('${expert.distanceKm} km away', style: AppTextStyles.body(size: 11, color: AppColors.neonGreen)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _callExpert(expert.phone),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: expert.phone == 'Not listed'
                            ? Colors.white.withOpacity(0.08)
                            : AppColors.neonGreen,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.call,
                        color: expert.phone == 'Not listed' ? AppColors.textSecondary : AppColors.bgDark,
                        size: 18,
                      ),
                    ),
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