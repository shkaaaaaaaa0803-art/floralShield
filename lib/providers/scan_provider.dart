import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/gemini_service.dart';
import '../services/history_service.dart';
import '../services/notification_service.dart';
import '../models/diagnosis_model.dart';
import '../models/scan_history_model.dart';
import '../data/demo_samples.dart';

enum ScanStatus { idle, imageSelected, analyzing, success, error }

class ScanProvider extends ChangeNotifier {
  final GeminiService _geminiService = GeminiService();
  final HistoryService _historyService = HistoryService();
  final ImagePicker _picker = ImagePicker();

  ScanStatus _status = ScanStatus.idle;
  File? _selectedImage;
  DiagnosisModel? _diagnosis;
  DiagnosisModel? _englishDiagnosis; // cached original, for switching back
  String _currentLanguage = 'English';
  bool _isTranslating = false;
  String? _errorMessage;
  List<ScanHistoryModel> _history = [];
  bool _isDemoMode = false;

  // Getters
  ScanStatus get status => _status;
  File? get selectedImage => _selectedImage;
  DiagnosisModel? get diagnosis => _diagnosis;
  String get currentLanguage => _currentLanguage;
  bool get isTranslating => _isTranslating;
  String? get errorMessage => _errorMessage;
  List<ScanHistoryModel> get history => _history;
  bool get isDemoMode => _isDemoMode;

  void toggleDemoMode(bool value) {
    _isDemoMode = value;
    notifyListeners();
  }

  /// Loads a pre-loaded sample diagnosis instantly, with no network call.
  /// Used for offline hackathon demo purposes.
  void runDemoScan(int sampleIndex) {
    final sample = DemoSamples.samples[sampleIndex];
    _selectedImage = null; // no real image file for demo samples
    _diagnosis = sample;
    _englishDiagnosis = sample;
    _currentLanguage = 'English';
    _status = ScanStatus.success;
    notifyListeners();
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80, // compress a bit before upload
      );

      if (pickedFile == null) return; // user cancelled

      _selectedImage = File(pickedFile.path);
      _status = ScanStatus.imageSelected;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _status = ScanStatus.error;
      _errorMessage = 'Could not pick image: $e';
      notifyListeners();
    }
  }

  Future<void> analyzeSelectedImage({List<File>? additionalImages}) async {
    if (_selectedImage == null) return;

    _status = ScanStatus.analyzing;
    notifyListeners();

    try {
      final result = await _geminiService.analyzeImage(
        _selectedImage!,
        additionalImages: additionalImages,
      );
      _diagnosis = result;
      _englishDiagnosis = result;
      _currentLanguage = 'English';
      _status = ScanStatus.success;

      // Save to history automatically after a successful scan
      // (only the primary image is stored, matching existing history behavior)
      await _historyService.saveScan(
        imagePath: _selectedImage!.path,
        diagnosis: result,
      );
      await loadHistory();

      if (!result.isHealthy) {
        // Fire-and-forget: don't let a notification failure (e.g. denied
        // permission) block showing the diagnosis to the user.
        unawaited(NotificationService.showInstant(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          title: '⚠️ ${result.diseaseName} detected',
          body: '${result.plantName} may need treatment — tap to view the full diagnosis.',
        ));
      }

      notifyListeners();
    } catch (e) {
      _status = ScanStatus.error;
      _errorMessage = 'Analysis failed: $e';
      notifyListeners();
    }
  }

  Future<void> switchLanguage(String languageName) async {
    if (_diagnosis == null || _englishDiagnosis == null) return;
    if (_currentLanguage == languageName) return;

    // Switching back to English is instant (already cached)
    if (languageName == 'English') {
      _diagnosis = _englishDiagnosis;
      _currentLanguage = 'English';
      notifyListeners();
      return;
    }

    _isTranslating = true;
    notifyListeners();

    try {
      final translated = await _geminiService.translateDiagnosis(
        _englishDiagnosis!,
        languageName,
      );
      _diagnosis = translated;
      _currentLanguage = languageName;
    } catch (e) {
      // Keep current diagnosis if translation fails
    } finally {
      _isTranslating = false;
      notifyListeners();
    }
  }

  Future<void> loadHistory() async {
    _history = await _historyService.getAllScans();
    notifyListeners();
  }

  Future<void> toggleFavorite(ScanHistoryModel item) async {
    item.isFavorite = !item.isFavorite;
    await item.save(); // HiveObject.save() persists the change directly
    notifyListeners();
  }

  Future<void> deleteHistoryItem(ScanHistoryModel item) async {
    await _historyService.deleteScan(item);
    await loadHistory();
  }

  Future<void> clearHistory() async {
    await _historyService.clearAll();
    await loadHistory();
  }

  void reset() {
    _selectedImage = null;
    _diagnosis = null;
    _englishDiagnosis = null;
    _currentLanguage = 'English';
    _errorMessage = null;
    _status = ScanStatus.idle;
    notifyListeners();
  }
}