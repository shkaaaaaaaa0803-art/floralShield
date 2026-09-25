import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/pdf_report_service.dart';
import '../providers/scan_provider.dart';
import '../models/diagnosis_model.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import '../widgets/heatmap_overlay.dart';
import 'dosage_calculator_screen.dart';
import 'expert_connect_screen.dart';
import 'home_screen.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final TtsService _ttsService = TtsService();
  bool _isSpeaking = false;
  bool _showHeatmap = false;
  bool _isGeneratingPdf = false;
  AudienceMode _audience = AudienceMode.homeGardener;

  void _shareDiagnosis(DiagnosisModel diagnosis) {
    final buffer = StringBuffer();
    buffer.writeln('🌿 Plant Diagnosis - Krishi Mitr AI');
    buffer.writeln();
    buffer.writeln('Plant: ${diagnosis.plantName}');

    if (!diagnosis.isSupportedCrop) {
      buffer.writeln('Status: Unsupported Agricultural Domain ⚠️');
      buffer.writeln('Note: ${diagnosis.symptoms.isNotEmpty ? diagnosis.symptoms.first : "Not an agricultural crop."}');
    } else if (diagnosis.isHealthy) {
      buffer.writeln('Status: Healthy ✅');
    } else {
      buffer.writeln('Disease: ${diagnosis.diseaseName}');
      buffer.writeln('Confidence: ${diagnosis.confidencePercent}%');
      buffer.writeln('Severity: ${diagnosis.severityPercent}%');

      if (diagnosis.symptoms.isNotEmpty) {
        buffer.writeln();
        buffer.writeln('Symptoms:');
        for (final s in diagnosis.symptoms) {
          buffer.writeln('• $s');
        }
      }

      if (diagnosis.treatment.isNotEmpty) {
        buffer.writeln();
        buffer.writeln('Treatment:');
        for (final t in diagnosis.treatment) {
          buffer.writeln('• $t');
        }
      }
    }

    buffer.writeln();
    buffer.writeln('Diagnosed using Krishi Mitr AI');

    Share.share(buffer.toString());
  }

  Future<void> _exportPdf(DiagnosisModel diagnosis, File? imageFile) async {
    setState(() => _isGeneratingPdf = true);
    try {
      await PdfReportService.generateAndShare(diagnosis: diagnosis, imageFile: imageFile);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not generate PDF report'),
            backgroundColor: AppColors.neonRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  Color _severityColor(int percent) {
    if (percent >= 40) return AppColors.neonRed;
    if (percent >= 15) return AppColors.neonAmber;
    return AppColors.neonGreen;
  }

  String _severityLabel(int percent) {
    if (percent >= 40) return 'SEVERE';
    if (percent >= 15) return 'MODERATE';
    if (percent > 0) return 'MILD';
    return 'HEALTHY';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScanProvider>();
    final diagnosis = provider.diagnosis;

    if (diagnosis == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Result')),
        body: const Center(child: Text('No diagnosis available')),
      );
    }

    final bool notAPlant = !diagnosis.isPlant;
    final bool unsupportedPlant = !diagnosis.isSupportedCrop;
    final severityColor = _severityColor(diagnosis.severityPercent);

    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundGradient,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Navigation Bar
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Text('Diagnosis Result', style: AppTextStyles.heading(size: 18))),
                    if (!notAPlant) ...[
                      _buildLanguageToggle(provider),
                      const SizedBox(width: 10),
                      _buildSpeakButton(diagnosis, provider.currentLanguage),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => _shareDiagnosis(diagnosis),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: const Icon(Icons.share_outlined, size: 16, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // Amber Warning Banner for Unsupported Non-Crop Objects
                if (!notAPlant && unsupportedPlant) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.neonAmber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.neonAmber),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppColors.neonAmber, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Scanned image identified as "${diagnosis.plantName}", which is not supported for agricultural crop disease diagnosis.',
                            style: AppTextStyles.body(size: 13, weight: FontWeight.w600, color: AppColors.neonAmber),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (notAPlant) ...[
                  _buildNotAPlantCard(diagnosis.plantName),
                ] else ...[
                  // Plant Title + Severity Pill Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          unsupportedPlant
                              ? diagnosis.plantName
                              : (diagnosis.isHealthy
                              ? diagnosis.plantName
                              : '${diagnosis.plantName}: ${diagnosis.diseaseName}'),
                          style: AppTextStyles.heading(size: 20),
                        ),
                      ),
                      if (!diagnosis.isHealthy && !unsupportedPlant)
                        NeonPill(
                          text: _severityLabel(diagnosis.severityPercent),
                          color: severityColor,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Confidence Meter + Metrics Card
                  GlassCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircularGauge(
                          fraction: diagnosis.confidencePercent / 100,
                          color: unsupportedPlant ? AppColors.neonAmber : AppColors.neonGreen,
                          size: 84,
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Confidence Score', style: AppTextStyles.body(size: 12, color: AppColors.textSecondary)),
                              const SizedBox(height: 8),
                              if (!unsupportedPlant) ...[
                                _severityMetricRow('Disease Severity', diagnosis.severityPercent, severityColor),
                                const SizedBox(height: 6),
                                _severityMetricRow(
                                  'Est. Leaf Area Affected',
                                  diagnosis.severityPercent,
                                  AppColors.textSecondary,
                                  showBar: false,
                                ),
                              ] else ...[
                                Text(
                                  'Non-Target Crop Domain',
                                  style: AppTextStyles.body(size: 13, weight: FontWeight.w600, color: AppColors.neonAmber),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Disease parameters omitted',
                                  style: AppTextStyles.body(size: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Scanned Image Display + Heatmap Option
                  if (provider.selectedImage != null) ...[
                    if (!diagnosis.isHealthy && !unsupportedPlant) ...[
                      Row(
                        children: [
                          _viewToggleChip('Original Leaf', !_showHeatmap, () {
                            setState(() => _showHeatmap = false);
                          }),
                          const SizedBox(width: 8),
                          _viewToggleChip('AI Heatmap', _showHeatmap, () {
                            setState(() => _showHeatmap = true);
                          }),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: SizedBox(
                        height: 200,
                        width: double.infinity,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(provider.selectedImage!, fit: BoxFit.cover),
                            if (_showHeatmap && !diagnosis.isHealthy && !unsupportedPlant)
                              HeatmapOverlay(
                                regionX: diagnosis.regionX,
                                regionY: diagnosis.regionY,
                                regionRadius: diagnosis.regionRadius,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Advice Cards
                  if (unsupportedPlant) ...[
                    _infoCard(
                      icon: Icons.info_outline,
                      iconColor: AppColors.neonAmber,
                      title: 'Horticultural Guidance',
                      items: diagnosis.treatment.isNotEmpty
                          ? diagnosis.treatment
                          : ['Please photograph an agricultural crop leaf (e.g., Tomato, Potato, Corn, Wheat, Rice) for automated disease analysis.'],
                    ),
                  ] else if (!diagnosis.isHealthy) ...[
                    if (diagnosis.symptoms.isNotEmpty)
                      _infoCard(
                        icon: Icons.visibility_outlined,
                        iconColor: AppColors.neonAmber,
                        title: 'Symptoms',
                        items: diagnosis.symptoms,
                      ),
                    const SizedBox(height: 16),

                    // Home Gardener / Farmer advice toggle -- Treatment and
                    // Prevention below are tailored to whichever is selected
                    // (low-chemical home advice vs. field-scale farmer
                    // advice with pesticide/fungicide classes).
                    Text('Tailor advice for:', style: AppTextStyles.body(size: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    _buildAudienceToggle(),
                    const SizedBox(height: 16),

                    if (diagnosis.treatmentFor(_audience).isNotEmpty)
                      _infoCard(
                        icon: Icons.healing_outlined,
                        iconColor: AppColors.neonGreen,
                        title: 'Treatment',
                        items: diagnosis.treatmentFor(_audience),
                      ),
                    const SizedBox(height: 12),
                    if (diagnosis.preventionFor(_audience).isNotEmpty)
                      _infoCard(
                        icon: Icons.shield_outlined,
                        iconColor: AppColors.textPrimary,
                        title: 'Prevention',
                        items: diagnosis.preventionFor(_audience),
                      ),
                    const SizedBox(height: 20),

                    Text('Actionable Remedies', style: AppTextStyles.heading(size: 14)),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ExpertConnectScreen()),
                        ),
                        icon: const Icon(Icons.support_agent, size: 18),
                        label: const Text('Connect to Nearby KVK Expert'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DosageCalculatorScreen(
                              diseaseName: diagnosis.diseaseName,
                              isHealthy: diagnosis.isHealthy,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.calculate_outlined, size: 18),
                        label: const Text('Calculate Precise Dosage'),
                      ),
                    ),
                  ] else ...[
                    GlassCard(
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: AppColors.neonGreen),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'This plant looks healthy! No disease detected.',
                              style: AppTextStyles.body(size: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],

                const SizedBox(height: 28),

                if (!notAPlant && !unsupportedPlant) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _isGeneratingPdf ? null : () => _exportPdf(diagnosis, provider.selectedImage),
                      icon: _isGeneratingPdf
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.neonGreen),
                      )
                          : const Icon(Icons.picture_as_pdf_outlined, size: 18),
                      label: Text(_isGeneratingPdf ? 'Generating...' : 'Export PDF Report'),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      provider.reset();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                            (route) => false,
                      );
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Scan Another Plant'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  static const _availableLanguages = [
    'English',
    'Hindi',
    'Marathi',
    'Tamil',
    'Telugu',
    'Punjabi',
    'Bengali',
    'Gujarati',
  ];

  Widget _buildLanguageToggle(ScanProvider provider) {
    if (provider.isTranslating) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.neonGreen),
      );
    }

    return PopupMenuButton<String>(
      color: AppColors.bgDark2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (language) {
        _ttsService.stop();
        setState(() => _isSpeaking = false);
        context.read<ScanProvider>().switchLanguage(language);
      },
      itemBuilder: (context) => _availableLanguages
          .map((lang) => PopupMenuItem<String>(
        value: lang,
        child: Row(
          children: [
            if (provider.currentLanguage == lang)
              const Icon(Icons.check, size: 14, color: AppColors.neonGreen)
            else
              const SizedBox(width: 14),
            const SizedBox(width: 8),
            Text(lang, style: AppTextStyles.body(size: 13)),
          ],
        ),
      ))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.translate, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 5),
            Text(
              provider.currentLanguage.length > 3
                  ? provider.currentLanguage.substring(0, 3).toUpperCase()
                  : provider.currentLanguage,
              style: AppTextStyles.label(size: 11),
            ),
            const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeakButton(DiagnosisModel diagnosis, String language) {
    return GestureDetector(
      onTap: () async {
        if (_isSpeaking) {
          await _ttsService.stop();
          setState(() => _isSpeaking = false);
          return;
        }

        final parts = <String>[
          diagnosis.plantName,
          if (!diagnosis.isHealthy && diagnosis.isSupportedCrop) diagnosis.diseaseName,
          ...diagnosis.treatmentFor(_audience),
        ];
        final speechText = parts.join('. ');

        setState(() => _isSpeaking = true);
        await _ttsService.speak(speechText, languageName: language);
        if (mounted) setState(() => _isSpeaking = false);
      },
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: _isSpeaking
              ? AppColors.neonGreen.withOpacity(0.2)
              : Colors.white.withOpacity(0.06),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Icon(
          _isSpeaking ? Icons.stop : Icons.volume_up_outlined,
          size: 16,
          color: _isSpeaking ? AppColors.neonGreen : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _viewToggleChip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.neonGreen.withOpacity(0.15) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.neonGreen : AppColors.glassBorder,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.body(
            size: 11,
            weight: FontWeight.w600,
            color: active ? AppColors.neonGreen : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildAudienceToggle() {
    return Row(
      children: [
        Expanded(
          child: _audienceSegment(
            label: 'Home Gardener',
            icon: Icons.home_outlined,
            mode: AudienceMode.homeGardener,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _audienceSegment(
            label: 'Farmer',
            icon: Icons.agriculture_outlined,
            mode: AudienceMode.farmer,
          ),
        ),
      ],
    );
  }

  Widget _audienceSegment({
    required String label,
    required IconData icon,
    required AudienceMode mode,
  }) {
    final bool active = _audience == mode;
    return GestureDetector(
      onTap: () => setState(() => _audience = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.neonGreen.withOpacity(0.15) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? AppColors.neonGreen : AppColors.glassBorder,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: active ? AppColors.neonGreen : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.body(
                size: 12,
                weight: FontWeight.w600,
                color: active ? AppColors.neonGreen : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _severityMetricRow(String label, int percent, Color color, {bool showBar = true}) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: AppTextStyles.body(size: 12, color: AppColors.textSecondary)),
        ),
        Text('$percent%', style: AppTextStyles.body(size: 13, weight: FontWeight.w700, color: color)),
      ],
    );
  }

  Widget _buildNotAPlantCard(String detectedName) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.neonAmber, size: 24),
              const SizedBox(width: 10),
              Text('Not a plant', style: AppTextStyles.heading(size: 15)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'This looks like: $detectedName',
            style: AppTextStyles.body(size: 14, weight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'For a disease diagnosis, please photograph a crop leaf, vegetable, or plant.',
            style: AppTextStyles.body(size: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<String> items,
  }) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.heading(size: 14)),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map(
                (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•  ', style: AppTextStyles.body(size: 13, color: AppColors.textSecondary)),
                  Expanded(
                    child: Text(item, style: AppTextStyles.body(size: 13, color: AppColors.textSecondary)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}