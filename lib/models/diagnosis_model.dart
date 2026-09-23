class DiagnosisModel {
  final String plantName;
  final bool isHealthy;
  final String diseaseName;
  final String confidence; // e.g. "High", "Medium", "Low"
  final int confidencePercent; // e.g. 94
  final int severityPercent; // e.g. 22 - percent of leaf/plant area affected
  final List<String> symptoms;
  final List<String> treatment;
  final List<String> prevention;
  final bool isPlant; // true if the image shows a plant/vegetable/flower
  final bool isSupportedCrop; // true if it belongs to supported target crops
  final double regionX; // 0.0-1.0, normalized center X of affected area
  final double regionY; // 0.0-1.0, normalized center Y of affected area
  final double regionRadius; // 0.0-1.0, normalized radius of affected area
  final String rawResponse; // fallback in case JSON parsing fails

  DiagnosisModel({
    required this.plantName,
    required this.isHealthy,
    required this.diseaseName,
    required this.confidence,
    required this.confidencePercent,
    required this.severityPercent,
    required this.symptoms,
    required this.treatment,
    required this.prevention,
    this.isPlant = true,
    this.isSupportedCrop = true,
    this.regionX = 0.5,
    this.regionY = 0.5,
    this.regionRadius = 0.3,
    this.rawResponse = '',
  });

  factory DiagnosisModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic v, double fallback) {
      if (v == null) return fallback;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? fallback;
    }

    int parseInt(dynamic v, int fallback) {
      if (v == null) return fallback;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? double.tryParse(v.toString())?.toInt() ?? fallback;
    }

    List<String> parseList(dynamic v) {
      if (v == null) return [];
      if (v is List) return v.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
      if (v is String && v.isNotEmpty) return [v];
      return [];
    }

    final region = json['affected_region'] as Map<String, dynamic>?;

    return DiagnosisModel(
      plantName: json['plant_name']?.toString() ?? 'Unknown',
      isHealthy: json['is_healthy'] is bool ? json['is_healthy'] : (json['is_healthy']?.toString().toLowerCase() == 'true'),
      diseaseName: json['disease_name']?.toString() ?? 'Not identified',
      confidence: json['confidence']?.toString() ?? 'Low',
      confidencePercent: parseInt(json['confidence_percent'], 0),
      severityPercent: parseInt(json['severity_percent'], 0),
      symptoms: parseList(json['symptoms']),
      treatment: parseList(json['treatment']),
      prevention: parseList(json['prevention']),
      isPlant: json['is_plant'] is bool ? json['is_plant'] : (json['is_plant']?.toString().toLowerCase() != 'false'),
      isSupportedCrop: json['is_supported_crop'] is bool ? json['is_supported_crop'] : (json['is_supported_crop']?.toString().toLowerCase() != 'false'),
      regionX: parseDouble(region?['x'], 0.5),
      regionY: parseDouble(region?['y'], 0.5),
      regionRadius: parseDouble(region?['radius'], 0.3),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'plant_name': plantName,
      'is_healthy': isHealthy,
      'disease_name': diseaseName,
      'confidence': confidence,
      'confidence_percent': confidencePercent,
      'severity_percent': severityPercent,
      'symptoms': symptoms,
      'treatment': treatment,
      'prevention': prevention,
      'is_plant': isPlant,
      'is_supported_crop': isSupportedCrop,
      'affected_region': {'x': regionX, 'y': regionY, 'radius': regionRadius},
    };
  }

  // Fallback factory when Gemini doesn't return clean JSON
  factory DiagnosisModel.fallback(String rawText) {
    return DiagnosisModel(
      plantName: 'Unknown',
      isHealthy: false,
      diseaseName: 'Could not parse structured result',
      confidence: 'Low',
      confidencePercent: 0,
      severityPercent: 0,
      symptoms: [],
      treatment: [],
      prevention: [],
      isPlant: true,
      isSupportedCrop: false,
      rawResponse: rawText,
    );
  }
}
