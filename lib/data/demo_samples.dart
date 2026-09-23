import '../models/diagnosis_model.dart';

/// Hardcoded sample diagnoses for offline demo mode.
/// Used when internet is unavailable during a hackathon pitch, so the
/// app can still show a full, realistic result flow.
class DemoSamples {
  static final List<DiagnosisModel> samples = [
    DiagnosisModel(
      plantName: 'Tomato (Solanum lycopersicum)',
      isHealthy: false,
      diseaseName: 'Early Blight',
      confidence: 'High',
      confidencePercent: 94,
      severityPercent: 22,
      symptoms: [
        'Dark concentric rings on lower leaves',
        'Yellowing tissue surrounding spots',
        'Leaf curling and premature drop',
      ],
      treatment: [
        'Remove and destroy infected leaves',
        'Apply copper-based fungicide every 7-10 days',
        'Ensure adequate spacing for airflow',
      ],
      prevention: [
        'Rotate crops each season',
        'Avoid overhead watering',
        'Mulch to prevent soil splash onto leaves',
      ],
    ),
    DiagnosisModel(
      plantName: 'Rose (Rosa)',
      isHealthy: false,
      diseaseName: 'Black Spot',
      confidence: 'High',
      confidencePercent: 91,
      severityPercent: 35,
      symptoms: [
        'Circular black spots with fringed edges',
        'Yellow halo around spots',
        'Premature leaf drop on lower stems',
      ],
      treatment: [
        'Remove fallen and infected leaves promptly',
        'Apply sulfur or neem-based fungicide weekly',
        'Prune for better air circulation',
      ],
      prevention: [
        'Water at the base, not on foliage',
        'Choose disease-resistant rose varieties',
        'Space plants to reduce humidity buildup',
      ],
    ),
    DiagnosisModel(
      plantName: 'Basil (Ocimum basilicum)',
      isHealthy: true,
      diseaseName: 'None',
      confidence: 'High',
      confidencePercent: 97,
      severityPercent: 0,
      symptoms: [],
      treatment: [],
      prevention: [
        'Maintain consistent watering schedule',
        'Ensure 6+ hours of sunlight daily',
        'Harvest leaves regularly to promote growth',
      ],
    ),
  ];
}