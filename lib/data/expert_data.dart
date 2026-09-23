import 'package:latlong2/latlong.dart';

class ExpertLocation {
  final String name;
  final String type;
  final String phone;
  final double lat;
  final double lng;
  final double distanceKm;
  final bool isSample; // true = fallback demo data, false = real OSM data

  const ExpertLocation({
    required this.name,
    required this.type,
    required this.phone,
    required this.lat,
    required this.lng,
    required this.distanceKm,
    this.isSample = false,
  });
}

/// Fallback sample data used when no real nearby locations are found
/// via OpenStreetMap (common in areas with sparse map coverage).
class ExpertData {
  static List<ExpertLocation> sampleLocations(LatLng userLocation) {
    const offsets = [
      {'lat': 0.018, 'lng': 0.012, 'dist': 2.4, 'name': 'Krishi Vigyan Kendra', 'type': 'Govt. Agricultural Extension Center', 'phone': '+91 522 2345678'},
      {'lat': -0.010, 'lng': 0.020, 'dist': 3.1, 'name': 'Green Field Agri Store', 'type': 'Pesticide & Fertilizer Store', 'phone': '+91 98765 43210'},
      {'lat': 0.025, 'lng': -0.015, 'dist': 4.6, 'name': 'District Agriculture Office', 'type': 'Govt. Agricultural Department', 'phone': '+91 522 2298765'},
      {'lat': -0.020, 'lng': -0.018, 'dist': 5.2, 'name': 'Kisan Seva Kendra', 'type': 'Farmer Support & Supplies', 'phone': '+91 91234 56789'},
    ];

    return offsets.map((o) {
      return ExpertLocation(
        name: o['name'] as String,
        type: o['type'] as String,
        phone: o['phone'] as String,
        lat: userLocation.latitude + (o['lat'] as double),
        lng: userLocation.longitude + (o['lng'] as double),
        distanceKm: o['dist'] as double,
        isSample: true,
      );
    }).toList();
  }
}