import 'package:latlong2/latlong.dart';

enum OutbreakSeverity { low, moderate, high }

class OutbreakZone {
  final String diseaseName;
  final String cropType;
  final int reportedCases;
  final OutbreakSeverity severity;
  final double lat;
  final double lng;
  final double distanceKm;

  const OutbreakZone({
    required this.diseaseName,
    required this.cropType,
    required this.reportedCases,
    required this.severity,
    required this.lat,
    required this.lng,
    required this.distanceKm,
  });
}

/// Sample disease outbreak data for demo purposes. A production version
/// would need a real backend collecting crowd-sourced farmer reports
/// (e.g. from app users submitting confirmed diagnoses in their area).
class OutbreakData {
  static List<OutbreakZone> sampleZones(LatLng userLocation) {
    const raw = [
      {'lat': 0.045, 'lng': 0.03, 'dist': 6.2, 'disease': 'Early Blight', 'crop': 'Tomato', 'cases': 12, 'severity': OutbreakSeverity.high},
      {'lat': -0.03, 'lng': 0.05, 'dist': 7.8, 'disease': 'Black Spot', 'crop': 'Rose', 'cases': 5, 'severity': OutbreakSeverity.moderate},
      {'lat': 0.06, 'lng': -0.04, 'dist': 9.1, 'disease': 'Powdery Mildew', 'crop': 'Cucumber', 'cases': 8, 'severity': OutbreakSeverity.moderate},
      {'lat': -0.055, 'lng': -0.02, 'dist': 8.4, 'disease': 'Bacterial Wilt', 'crop': 'Potato', 'cases': 3, 'severity': OutbreakSeverity.low},
      {'lat': 0.02, 'lng': 0.07, 'dist': 8.9, 'disease': 'Leaf Curl Virus', 'crop': 'Chilli', 'cases': 15, 'severity': OutbreakSeverity.high},
    ];

    return raw.map((o) {
      return OutbreakZone(
        diseaseName: o['disease'] as String,
        cropType: o['crop'] as String,
        reportedCases: o['cases'] as int,
        severity: o['severity'] as OutbreakSeverity,
        lat: userLocation.latitude + (o['lat'] as double),
        lng: userLocation.longitude + (o['lng'] as double),
        distanceKm: o['dist'] as double,
      );
    }).toList();
  }
}