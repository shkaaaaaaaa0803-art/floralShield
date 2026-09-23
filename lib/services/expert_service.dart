import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../data/expert_data.dart';

class ExpertService {
  static const String _overpassUrl = 'https://overpass-api.de/api/interpreter';

  /// Fetches real nearby agriculture-related shops/offices from
  /// OpenStreetMap within [radiusMeters] of [location]. Returns an
  /// empty list if none are found or the request fails (caller should
  /// fall back to sample data in that case).
  Future<List<ExpertLocation>> fetchNearby(
      LatLng location, {
        int radiusMeters = 15000,
      }) async {
    final query = '''
[out:json][timeout:15];
(
  node["shop"="agrarian"](around:$radiusMeters,${location.latitude},${location.longitude});
  node["shop"="farm"](around:$radiusMeters,${location.latitude},${location.longitude});
  node["shop"="garden_centre"](around:$radiusMeters,${location.latitude},${location.longitude});
  node["office"="agriculture"](around:$radiusMeters,${location.latitude},${location.longitude});
);
out center 10;
''';

    try {
      final response = await http
          .post(Uri.parse(_overpassUrl), body: {'data': query})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body);
      final List<dynamic> elements = data['elements'] ?? [];

      final results = <ExpertLocation>[];
      for (final el in elements) {
        final tags = el['tags'] ?? {};
        final lat = (el['lat'] as num?)?.toDouble();
        final lng = (el['lon'] as num?)?.toDouble();
        if (lat == null || lng == null) continue;

        final name = tags['name'] ?? 'Agricultural Shop';
        final shopType = tags['shop'] ?? tags['office'] ?? 'agrarian';
        final phone = tags['phone'] ?? tags['contact:phone'] ?? 'Not listed';

        final distanceMeters = Geolocator.distanceBetween(
          location.latitude,
          location.longitude,
          lat,
          lng,
        );

        results.add(ExpertLocation(
          name: name,
          type: _friendlyType(shopType),
          phone: phone,
          lat: lat,
          lng: lng,
          distanceKm: double.parse((distanceMeters / 1000).toStringAsFixed(1)),
          isSample: false,
        ));
      }

      // Sort by distance, closest first
      results.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      return results.take(8).toList();
    } catch (e) {
      return [];
    }
  }

  String _friendlyType(String rawTag) {
    switch (rawTag) {
      case 'agrarian':
        return 'Agricultural Supplies Store';
      case 'farm':
        return 'Farm Shop';
      case 'garden_centre':
        return 'Garden Centre';
      case 'agriculture':
        return 'Agricultural Office';
      default:
        return 'Agricultural Store';
    }
  }
}