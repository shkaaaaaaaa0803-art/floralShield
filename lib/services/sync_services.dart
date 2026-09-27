import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/scan_history_model.dart';

/// Syncs ScanHistoryModel records to/from Firestore under
/// users/{uid}/scans/{scanId}. Local Hive storage remains the source of
/// truth on-device (works fully offline); this service is only consulted
/// when the user is signed in, to mirror their history to the cloud so it
/// can be pulled down on another device.
///
/// Note: only the diagnosis text data is synced, not the actual photo --
/// `imagePath` is a local file path and won't resolve on another device.
/// History screens already fall back gracefully when an image file is
/// missing, so a scan synced from another device just shows that
/// fallback instead of a photo.
class SyncService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _scansRef(String uid) {
    return _db.collection('users').doc(uid).collection('scans');
  }

  Map<String, dynamic> _toMap(ScanHistoryModel item) {
    return {
      'id': item.id,
      'imagePath': item.imagePath,
      'plantName': item.plantName,
      'isHealthy': item.isHealthy,
      'diseaseName': item.diseaseName,
      'confidence': item.confidence,
      'symptoms': item.symptoms,
      'treatment': item.treatment,
      'prevention': item.prevention,
      'scannedAt': Timestamp.fromDate(item.scannedAt),
      'isFavorite': item.isFavorite,
    };
  }

  ScanHistoryModel _fromMap(Map<String, dynamic> data) {
    return ScanHistoryModel(
      id: data['id'] as String,
      imagePath: data['imagePath'] as String? ?? '',
      plantName: data['plantName'] as String? ?? 'Unknown',
      isHealthy: data['isHealthy'] as bool? ?? true,
      diseaseName: data['diseaseName'] as String? ?? '',
      confidence: data['confidence'] as String? ?? '',
      symptoms: List<String>.from(data['symptoms'] ?? []),
      treatment: List<String>.from(data['treatment'] ?? []),
      prevention: List<String>.from(data['prevention'] ?? []),
      scannedAt: (data['scannedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isFavorite: data['isFavorite'] as bool? ?? false,
    );
  }

  /// Uploads (or overwrites) a single scan.
  Future<void> pushScan(String uid, ScanHistoryModel item) async {
    await _scansRef(uid).doc(item.id).set(_toMap(item));
  }

  /// One-time bulk upload -- used right after sign-up/sign-in to push any
  /// scans that were made locally before the user had an account.
  Future<void> pushAll(String uid, List<ScanHistoryModel> items) async {
    if (items.isEmpty) return;
    final batch = _db.batch();
    for (final item in items) {
      batch.set(_scansRef(uid).doc(item.id), _toMap(item));
    }
    await batch.commit();
  }

  Future<List<ScanHistoryModel>> pullAllScans(String uid) async {
    final snapshot = await _scansRef(uid).orderBy('scannedAt', descending: true).get();
    return snapshot.docs.map((doc) => _fromMap(doc.data())).toList();
  }

  Future<void> deleteScan(String uid, String id) async {
    await _scansRef(uid).doc(id).delete();
  }

  Future<void> clearAll(String uid) async {
    final snapshot = await _scansRef(uid).get();
    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}