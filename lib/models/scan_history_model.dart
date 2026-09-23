import 'package:hive/hive.dart';

part 'scan_history_model.g.dart';

@HiveType(typeId: 0)
class ScanHistoryModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String imagePath;

  @HiveField(2)
  final String plantName;

  @HiveField(3)
  final bool isHealthy;

  @HiveField(4)
  final String diseaseName;

  @HiveField(5)
  final String confidence;

  @HiveField(6)
  final List<String> symptoms;

  @HiveField(7)
  final List<String> treatment;

  @HiveField(8)
  final List<String> prevention;

  @HiveField(9)
  final DateTime scannedAt;

  @HiveField(10)
  bool isFavorite;

  ScanHistoryModel({
    required this.id,
    required this.imagePath,
    required this.plantName,
    required this.isHealthy,
    required this.diseaseName,
    required this.confidence,
    required this.symptoms,
    required this.treatment,
    required this.prevention,
    required this.scannedAt,
    this.isFavorite = false,
  });
}