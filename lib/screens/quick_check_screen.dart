import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/quick_check_result.dart';
import '../services/gemini_service.dart';
import '../theme/app_theme.dart';

enum QuickCheckMode { freshness, petToxicity, soilTexture }

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
    }
  }

  String get _subtitle {
    switch (widget.mode) {
      case QuickCheckMode.freshness:
        return 'Photograph a fruit or vegetable to check its freshness';
      case QuickCheckMode.petToxicity:
        return 'Photograph a plant to check if it\'s safe for your pets';
      case QuickCheckMode.soilTexture:
        return 'Photograph soil to estimate its texture and suitability';
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
      }

      setState(() {
        _result = result;
        _analyzing = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Something went wrong. Please try again.';
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: 14),
                    Text(_title, style: AppTextStyles.heading(size: 18)),
                  ],
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 34),
                  child: Text(_subtitle, style: AppTextStyles.body(size: 12, color: AppColors.textSecondary)),
                ),
                const SizedBox(height: 20),

                // Image preview area
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    height: 220,
                    width: double.infinity,
                    color: Colors.white.withOpacity(0.05),
                    child: _selectedImage != null
                        ? Image.file(_selectedImage!, fit: BoxFit.cover)
                        : Center(
                      child: Icon(_icon, size: 56, color: AppColors.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_outlined, size: 18),
                          label: const Text('Camera'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined, size: 18),
                          label: const Text('Gallery'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _selectedImage == null || _analyzing ? null : _analyze,
                    icon: _analyzing
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bgDark),
                    )
                        : const Icon(Icons.search, size: 20),
                    label: Text(_analyzing ? 'Analyzing...' : 'Analyze'),
                  ),
                ),

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

                if (_result != null) ...[
                  const SizedBox(height: 20),
                  _buildResultCard(_result!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _expectedSubjectText {
    switch (widget.mode) {
      case QuickCheckMode.freshness:
        return 'a fruit or vegetable';
      case QuickCheckMode.petToxicity:
        return 'a plant';
      case QuickCheckMode.soilTexture:
        return 'soil';
    }
  }

  Widget _buildResultCard(QuickCheckResult result) {
    if (!result.isValidSubject) {
      return GlassCard(
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.neonAmber),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'This looks like: ${result.subjectName}. Please try a photo of $_expectedSubjectText.',
                style: AppTextStyles.body(size: 13),
              ),
            ),
          ],
        ),
      );
    }

    final statusColor = result.statusGood ? AppColors.neonGreen : AppColors.neonRed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassCard(
          child: Row(
            children: [
              CircularGauge(
                fraction: result.scorePercent / 100,
                color: statusColor,
                size: 72,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(result.subjectName, style: AppTextStyles.heading(size: 16)),
                    const SizedBox(height: 6),
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
                      Text('•  ', style: AppTextStyles.body(size: 13, color: AppColors.textSecondary)),
                      Expanded(child: Text(d, style: AppTextStyles.body(size: 13, color: AppColors.textSecondary))),
                    ],
                  ),
                )),
              ],
            ),
          ),
        const SizedBox(height: 12),
        if (result.tips.isNotEmpty)
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.mode == QuickCheckMode.freshness
                      ? 'Storage Tips'
                      : widget.mode == QuickCheckMode.petToxicity
                      ? 'What To Do'
                      : 'Recommendations',
                  style: AppTextStyles.heading(size: 14),
                ),
                const SizedBox(height: 10),
                ...result.tips.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('•  ', style: AppTextStyles.body(size: 13, color: AppColors.textSecondary)),
                      Expanded(child: Text(t, style: AppTextStyles.body(size: 13, color: AppColors.textSecondary))),
                    ],
                  ),
                )),
              ],
            ),
          ),
      ],
    );
  }
}