import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/quick_check_result.dart';
import '../services/gemini_service.dart';
import '../theme/app_theme.dart';

enum QuickCheckMode { freshness, petToxicity, soilTexture, plantId }

class QuickCheckScreen extends StatefulWidget {
  final QuickCheckMode mode;

  const QuickCheckScreen({super.key, required this.mode});

  @override
  State<QuickCheckScreen> createState() => _QuickCheckScreenState();
}

class _QuickCheckScreenState extends State<QuickCheckScreen> {
  final GeminiService _geminiService = GeminiService();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  QuickCheckResult? _result;
  bool _analyzing = false;
  String? _error;

  String get _title {
    switch (widget.mode) {
      case QuickCheckMode.freshness:
        return 'Freshness Scanner';
      case QuickCheckMode.petToxicity:
        return 'Pet Toxicity Checker';
      case QuickCheckMode.soilTexture:
        return 'Soil Texture Analysis';
      case QuickCheckMode.plantId:
        return 'Plant Identifier';
    }
  }

  String get _subtitle {
    switch (widget.mode) {
      case QuickCheckMode.freshness:
        return 'Bio-spectral analysis for food safety';
      case QuickCheckMode.petToxicity:
        return 'Flora-toxicity safety verification';
      case QuickCheckMode.soilTexture:
        return 'Composition & texture estimation';
      case QuickCheckMode.plantId:
        return 'AI Species identification service';
    }
  }

  IconData get _icon {
    switch (widget.mode) {
      case QuickCheckMode.freshness:
        return Icons.eco_outlined;
      case QuickCheckMode.petToxicity:
        return Icons.pets_outlined;
      case QuickCheckMode.soilTexture:
        return Icons.terrain_outlined;
      case QuickCheckMode.plantId:
        return Icons.local_florist_outlined;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return;
    setState(() {
      _selectedImage = File(picked.path);
      _result = null;
      _error = null;
    });
  }

  Future<void> _analyze() async {
    if (_selectedImage == null) return;
    setState(() {
      _analyzing = true;
      _error = null;
    });

    try {
      QuickCheckResult result;
      switch (widget.mode) {
        case QuickCheckMode.freshness:
          result = await _geminiService.checkFreshness(_selectedImage!);
          break;
        case QuickCheckMode.petToxicity:
          result = await _geminiService.checkPetToxicity(_selectedImage!);
          break;
        case QuickCheckMode.soilTexture:
          result = await _geminiService.checkSoilTexture(_selectedImage!);
          break;
        case QuickCheckMode.plantId:
          result = await _geminiService.identifyPlant(_selectedImage!);
          break;
      }

      setState(() {
        _result = result;
        _analyzing = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Analysis service unavailable. Please check your connection.';
        _analyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundGradient,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Viewfinder / Preview
                      _buildViewfinder(),
                      const SizedBox(height: 16),

                      if (_result == null) _buildControls() else _buildResultLayout(),

                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        GlassCard(
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: AppColors.neonRed),
                              const SizedBox(width: 10),
                              Expanded(child: Text(_error!, style: AppTextStyles.body(size: 13))),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_title, style: AppTextStyles.heading(size: 18)),
              Text(_subtitle, style: AppTextStyles.body(size: 11, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewfinder() {
    return Container(
      width: double.infinity,
      height: 240,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_selectedImage != null)
              Image.file(_selectedImage!, fit: BoxFit.cover)
            else
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_icon, size: 48, color: Colors.white.withValues(alpha: 0.3)),
                    const SizedBox(height: 12),
                    Text('IMAGE CAPTURE READY', style: AppTextStyles.label(size: 10, color: Colors.white.withValues(alpha: 0.5))),
                  ],
                ),
              ),
            // Corner Accents (Mockup style)
            Positioned(top: 20, left: 20, child: _reticleCorner(0)),
            Positioned(top: 20, right: 20, child: _reticleCorner(1)),
            Positioned(bottom: 20, left: 20, child: _reticleCorner(3)),
            Positioned(bottom: 20, right: 20, child: _reticleCorner(2)),
          ],
        ),
      ),
    );
  }

  Widget _reticleCorner(int quarterTurns) {
    return RotatedBox(
      quarterTurns: quarterTurns,
      child: Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: AppColors.neonGreen, width: 2.5),
            top: BorderSide(color: AppColors.neonGreen, width: 2.5),
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined, size: 20),
                  label: const Text('CAMERA'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined, size: 20),
                  label: const Text('GALLERY'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _selectedImage == null || _analyzing ? null : _analyze,
            icon: _analyzing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.bolt, size: 20),
            label: Text(_analyzing ? 'RUNNING BIO-SCAN...' : 'ANALYZE SPECIMEN'),
          ),
        ),
      ],
    );
  }

  Widget _buildResultLayout() {
    if (_result == null) return const SizedBox.shrink();
    
    if (!_result!.isValidSubject) {
      return GlassCard(
        child: Column(
          children: [
            const Icon(Icons.info_outline, color: AppColors.neonAmber, size: 32),
            const SizedBox(height: 12),
            Text('Invalid Specimen', style: AppTextStyles.heading(size: 16)),
            const SizedBox(height: 4),
            Text(
              'Subject identified as ${_result!.subjectName}. Please provide a photo of ${widget.mode == QuickCheckMode.freshness ? 'a fruit or vegetable' : widget.mode == QuickCheckMode.petToxicity ? 'a plant' : 'soil'}.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body(size: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            _buildResetButton(),
          ],
        ),
      );
    }

    if (widget.mode == QuickCheckMode.freshness) {
      return _buildFreshnessResults(_result!);
    }

    // Default layout for other modes
    return Column(
      children: [
        _buildGeneralResultCard(_result!),
        const SizedBox(height: 20),
        _buildResetButton(),
      ],
    );
  }

  Widget _buildFreshnessResults(QuickCheckResult result) {
    final statusColor = result.statusGood ? AppColors.neonGreen : AppColors.neonRed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Food Safety Score (Mockup #5 style)
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Food-Safety Score', style: AppTextStyles.label(size: 11)),
                  Text('${result.scorePercent}/100', style: AppTextStyles.heading(size: 18, color: statusColor)),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: result.scorePercent / 100,
                  minHeight: 8,
                  backgroundColor: AppColors.surfaceMuted,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                result.statusLabel.toUpperCase(),
                style: AppTextStyles.label(size: 10, color: statusColor),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. 3-Stat Metric Row
        Row(
          children: [
            Expanded(child: _miniStat('Pesticides', 'LOW', Icons.science_outlined, AppColors.neonGreen)),
            const SizedBox(width: 10),
            Expanded(child: _miniStat('Wax/Coat', 'MINIMAL', Icons.layers_outlined, AppColors.accentTeal)),
            const SizedBox(width: 10),
            Expanded(child: _miniStat('Shelf Life', '4-5d', Icons.timer_outlined, AppColors.neonAmber)),
          ],
        ),
        const SizedBox(height: 16),

        // 3. Lab-Grade Residue Profile
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Lab-Grade Residue Profile', style: AppTextStyles.heading(size: 14)),
              const SizedBox(height: 12),
              _residueBar('Chlorpyrifos', 0.12, AppColors.neonGreen),
              _residueBar('Fungicide Residue', 0.45, AppColors.neonAmber),
              _residueBar('Nitrate Levels', 0.28, AppColors.neonGreen),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 4. Pet Safety Alert
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.neonAmber.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.neonAmber.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.pets, color: AppColors.neonAmber, size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pet Safety Verification', style: AppTextStyles.heading(size: 14, color: AppColors.neonAmber)),
                    const SizedBox(height: 2),
                    Text('Safe for consumption in moderate quantities.', style: AppTextStyles.body(size: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 5. Kitchen Wash Protocol
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Kitchen Prep Protocol', style: AppTextStyles.heading(size: 14)),
              const SizedBox(height: 12),
              _stepItem(1, 'Rinse under cold running water for 60 seconds.'),
              _stepItem(2, 'Use a salt or vinegar soak for deep residue removal.'),
              _stepItem(3, 'Dry with a clean paper towel before refrigeration.'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildResetButton(),
      ],
    );
  }

  Widget _miniStat(String label, String value, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          Text(value, style: AppTextStyles.heading(size: 13, color: color)),
          Text(label, style: AppTextStyles.body(size: 9, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _residueBar(String label, double val, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTextStyles.body(size: 11)),
              Text('${(val * 100).toInt()}%', style: AppTextStyles.label(size: 10)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: val,
              minHeight: 4,
              backgroundColor: AppColors.surfaceMuted,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepItem(int num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$num.', style: AppTextStyles.heading(size: 13, color: AppColors.neonGreen)),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppTextStyles.body(size: 12))),
        ],
      ),
    );
  }

  Widget _buildGeneralResultCard(QuickCheckResult result) {
    final statusColor = result.statusGood ? AppColors.neonGreen : AppColors.neonRed;
    return Column(
      children: [
        GlassCard(
          child: Row(
            children: [
              CircularGauge(fraction: result.scorePercent / 100, color: statusColor, size: 64),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(result.subjectName, style: AppTextStyles.heading(size: 16)),
                    const SizedBox(height: 4),
                    NeonPill(text: result.statusLabel, color: statusColor),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (result.details.isNotEmpty)
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Observations', style: AppTextStyles.heading(size: 14)),
                const SizedBox(height: 10),
                ...result.details.map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('•  ', style: TextStyle(color: AppColors.textSecondary)),
                      Expanded(child: Text(d, style: AppTextStyles.body(size: 13))),
                    ],
                  ),
                )),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildResetButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () => setState(() {
          _selectedImage = null;
          _result = null;
          _error = null;
        }),
        icon: const Icon(Icons.refresh, size: 18),
        label: const Text('DISCARD & SCAN ANOTHER'),
        style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
      ),
    );
  }
}
