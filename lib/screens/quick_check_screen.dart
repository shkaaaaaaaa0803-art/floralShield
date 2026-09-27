import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
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

    if (widget.mode == QuickCheckMode.petToxicity) {
      return _buildPetToxicityResults(_result!);
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

        // 2. 3-Stat Metric Row -- driven by the AI's stat_labels/stat_values,
        // with a safe fallback if the model didn't return any.
        if (result.statLabels.isNotEmpty)
          Row(
            children: List.generate(result.statLabels.length.clamp(0, 3), (i) {
              final label = result.statLabels[i];
              final value = i < result.statValues.length ? result.statValues[i] : '--';
              final icons = [Icons.science_outlined, Icons.layers_outlined, Icons.timer_outlined];
              final colors = [AppColors.neonGreen, AppColors.accentTeal, AppColors.neonAmber];
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 2 ? 10 : 0),
                  child: _miniStat(label, value, icons[i % icons.length], colors[i % colors.length]),
                ),
              );
            }),
          )
        else
          Row(
            children: [
              Expanded(child: _miniStat('Confidence', '${result.scorePercent}%', Icons.verified_outlined, statusColor)),
            ],
          ),
        const SizedBox(height: 16),

        // 3. Freshness Observations -- real visual observations from the
        // AI, not fabricated lab-precision numbers.
        if (result.details.isNotEmpty)
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Freshness Observations', style: AppTextStyles.heading(size: 14)),
                const SizedBox(height: 12),
                ...result.details.map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 5),
                        child: Icon(Icons.circle, size: 5, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(d, style: AppTextStyles.body(size: 13))),
                    ],
                  ),
                )),
              ],
            ),
          ),
        const SizedBox(height: 16),

        // 4. Pet Safety Alert -- real per-food verdict, not a blanket
        // "safe in moderation" claim. Some produce (grapes, onions, garlic,
        // unripe tomatoes, etc.) is genuinely toxic to dogs/cats.
        if (result.petSafetyNote.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (result.petSafe ? AppColors.neonGreen : AppColors.neonRed).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: (result.petSafe ? AppColors.neonGreen : AppColors.neonRed).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  result.petSafe ? Icons.pets : Icons.warning_amber_rounded,
                  color: result.petSafe ? AppColors.neonGreen : AppColors.neonRed,
                  size: 24,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.petSafe ? 'Safe for Pets' : 'Toxic to Pets',
                        style: AppTextStyles.heading(
                          size: 14,
                          color: result.petSafe ? AppColors.neonGreen : AppColors.neonRed,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(result.petSafetyNote, style: AppTextStyles.body(size: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),

        // 5. Kitchen Wash Protocol -- real, item-specific steps from the AI.
        if (result.tips.isNotEmpty)
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kitchen Prep Protocol', style: AppTextStyles.heading(size: 14)),
                const SizedBox(height: 12),
                ...result.tips.asMap().entries.map(
                      (entry) => _stepItem(entry.key + 1, entry.value),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        _buildResetButton(),
      ],
    );
  }

  Future<void> _callVet() async {
    final uri = Uri.parse('tel:');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _buildPetToxicityResults(QuickCheckResult result) {
    final bool isToxic = !result.statusGood;
    final Color statusColor = isToxic ? AppColors.neonRed : AppColors.neonGreen;

    // First `details` entry (when toxic) is the toxic principle per our
    // prompt; the rest are symptoms. When safe, all details are shown as
    // general notes.
    final List<String> toxicPrinciple =
    isToxic && result.details.isNotEmpty ? [result.details.first] : [];
    final List<String> symptoms =
    isToxic && result.details.length > 1 ? result.details.sublist(1) : result.details;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Big toxic/safe verdict banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: statusColor.withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                isToxic ? Icons.warning_amber_rounded : Icons.pets,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.subjectName,
                      style: AppTextStyles.body(size: 12, color: Colors.white.withValues(alpha: 0.85)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      result.statusLabel,
                      style: AppTextStyles.heading(size: 18, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. Confidence + affected species row
        Row(
          children: [
            Expanded(
              child: GlassCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    CircularGauge(fraction: result.scorePercent / 100, color: statusColor, size: 54),
                    const SizedBox(height: 8),
                    Text('AI Confidence', style: AppTextStyles.body(size: 9, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GlassCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Icon(Icons.pets, size: 22, color: AppColors.textPrimary),
                    const SizedBox(height: 8),
                    Text('Dogs & Cats', style: AppTextStyles.body(size: 11, weight: FontWeight.w600)),
                    Text('species checked', style: AppTextStyles.body(size: 9, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 3. Toxic principle (only when toxic)
        if (toxicPrinciple.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.neonRed.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.neonRed.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.science_outlined, color: AppColors.neonRed, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Toxic Principle', style: AppTextStyles.label(size: 10, color: AppColors.neonRed)),
                      const SizedBox(height: 4),
                      Text(toxicPrinciple.first, style: AppTextStyles.body(size: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 4. Symptoms / notes
        if (symptoms.isNotEmpty)
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isToxic ? 'Symptoms If Ingested' : 'Safety Notes',
                  style: AppTextStyles.heading(size: 14),
                ),
                const SizedBox(height: 12),
                ...symptoms.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isToxic ? Icons.circle : Icons.check_circle_outline,
                        size: isToxic ? 6 : 14,
                        color: isToxic ? AppColors.neonRed : AppColors.neonGreen,
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(s, style: AppTextStyles.body(size: 13))),
                    ],
                  ),
                )),
              ],
            ),
          ),
        const SizedBox(height: 16),

        // 5. What to do -- urgent styling if toxic, calm styling if safe
        if (result.tips.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isToxic ? AppColors.neonRed.withValues(alpha: 0.08) : AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isToxic ? AppColors.neonRed.withValues(alpha: 0.25) : AppColors.border,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isToxic ? 'If Your Pet Ingests This' : 'General Precautions',
                  style: AppTextStyles.heading(size: 14, color: isToxic ? AppColors.neonRed : AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                ...result.tips.asMap().entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.key + 1}.',
                        style: AppTextStyles.heading(size: 13, color: isToxic ? AppColors.neonRed : AppColors.neonGreen),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(entry.value, style: AppTextStyles.body(size: 13))),
                    ],
                  ),
                )),
                if (isToxic) ...[
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _callVet,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonRed),
                      icon: const Icon(Icons.call, size: 18),
                      label: const Text('CALL YOUR VET NOW'),
                    ),
                  ),
                ],
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