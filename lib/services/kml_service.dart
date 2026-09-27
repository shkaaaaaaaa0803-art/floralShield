import 'dart:math';

class KmlWaypoint {
  final double lat;
  final double lng;
  const KmlWaypoint(this.lat, this.lng);
}

/// Generates a simple drone coverage flight path and exports it as KML.
///
/// IMPORTANT HONESTY NOTE: this app has no field-boundary mapping feature,
/// so there's no real surveyed field shape to fly. What this actually
/// generates is a straightforward rectangular "lawnmower" (boustrophedon)
/// coverage pattern - parallel passes spaced `swathMeters` apart - centered
/// on a given GPS point, sized by width/length you provide. It's a real,
/// valid, usable flight path; it just isn't derived from a true field
/// boundary. The UI that calls this should make that clear.
class KmlService {
  static const double _metersPerDegreeLat = 111320.0;

  static List<KmlWaypoint> generateCoveragePath({
    required double centerLat,
    required double centerLng,
    required double widthMeters,
    required double lengthMeters,
    required double swathMeters,
  }) {
    final safeSwath = swathMeters <= 0 ? 1.0 : swathMeters;
    final passCount = (widthMeters / safeSwath).ceil().clamp(1, 200);
    final metersPerDegreeLng = _metersPerDegreeLat * cos(centerLat * pi / 180);

    final waypoints = <KmlWaypoint>[];
    for (int i = 0; i < passCount; i++) {
      final xOffset = -widthMeters / 2 + (i + 0.5) * safeSwath;
      final lng = centerLng + (xOffset / metersPerDegreeLng);

      final goingNorth = i.isEven;
      final startLat = centerLat + (goingNorth ? -lengthMeters / 2 : lengthMeters / 2) / _metersPerDegreeLat;
      final endLat = centerLat + (goingNorth ? lengthMeters / 2 : -lengthMeters / 2) / _metersPerDegreeLat;

      waypoints.add(KmlWaypoint(startLat, lng));
      waypoints.add(KmlWaypoint(endLat, lng));
    }
    return waypoints;
  }

  static String buildKml({
    required List<KmlWaypoint> waypoints,
    required String name,
  }) {
    final coordinates = waypoints
        .map((w) => '${w.lng.toStringAsFixed(7)},${w.lat.toStringAsFixed(7)},0')
        .join(' ');

    final placemarks = waypoints.asMap().entries.map((entry) {
      final i = entry.key;
      final w = entry.value;
      return '''
    <Placemark>
      <name>WP${i + 1}</name>
      <Point><coordinates>${w.lng.toStringAsFixed(7)},${w.lat.toStringAsFixed(7)},0</coordinates></Point>
    </Placemark>''';
    }).join('\n');

    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>$name</name>
    <Style id="flightPath">
      <LineStyle><color>ff0000ff</color><width>3</width></LineStyle>
    </Style>
    <Placemark>
      <name>Coverage Flight Path</name>
      <styleUrl>#flightPath</styleUrl>
      <LineString>
        <tessellate>1</tessellate>
        <coordinates>$coordinates</coordinates>
      </LineString>
    </Placemark>
$placemarks
  </Document>
</kml>''';
  }
}