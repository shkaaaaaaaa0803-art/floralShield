import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/scan_history_model.dart';
import '../models/diagnosis_model.dart';

class HistoryService {
  static const String boxName = 'scan_history';
  final _uuid = const Uuid();

  Future<Box<ScanHistoryModel>> _openBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox<ScanHistoryModel>(boxName);
    }
    return Hive.box<ScanHistoryModel>(boxName);
  }

  Future<ScanHistoryModel> saveScan({
    required String imagePath,
    required DiagnosisModel diagnosis,
  }) async {
    final box = await _openBox();

    final entry = ScanHistoryModel(
      id: _uuid.v4(),
      imagePath: imagePath,
      plantName: diagnosis.plantName,
      isHealthy: diagnosis.isHealthy,
      diseaseName: diagnosis.diseaseName,
      confidence: diagnosis.confidence,
      symptoms: diagnosis.symptoms,
      treatment: diagnosis.treatment,
      prevention: diagnosis.prevention,
      scannedAt: DateTime.now(),
    );

    await box.add(entry);
    return entry;
  }

  Future<List<ScanHistoryModel>> getAllScans() async {
    final box = await _openBox();
    final scans = box.values.toList();
    // Most recent first
    scans.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
    return scans;
  }

  /// Saves a scan that already has its own id - used when pulling a scan
  /// down from Firestore (saveScan() above always mints a fresh id, which
  /// is correct for brand-new local scans but wrong here: we want the
  /// cloud copy's id preserved so re-syncing doesn't create duplicates).
  /// Keyed by the scan's own id string, unlike saveScan()'s auto-increment
  /// key - Hive allows mixed key types in the same box, so this is safe
  /// alongside existing entries.
  Future<void> saveExistingScan(ScanHistoryModel scan) async {
    final box = await _openBox();
    await box.put(scan.id, scan);
  }

  Future<void> deleteScan(ScanHistoryModel scan) async {
    await scan.delete();
  }

  Future<void> clearAll() async {
    final box = await _openBox();
    await box.clear();
  }
}