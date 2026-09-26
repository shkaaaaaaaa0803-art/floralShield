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
    buffer.writeln('🌿 Plant Diagnosis - FloraShield AI');
    buffer.writeln();
    buffer.writeln('Plant: ${diagnosis.plantName}');

    if (diagnosis.isHealthy) {
      buffer.writeln('Status: Healthy ✅');
    } else {
      buffer.writeln('Disease: ${diagnosis.diseaseName}');
      buffer.writeln('AI Match: ${diagnosis.confidencePercent}%');
      buffer.writeln('Severity: ${diagnosis.severityPercent}%');

      if (diagnosis.symptoms.isNotEmpty) {
        buffer.writeln();
        buffer.writeln('Symptoms:');
        for (final s in diagnosis.symptoms) {
          buffer.writeln('• $s');
        }
      }

      final treatment = diagnosis.treatmentFor(_audience);
      if (treatment.isNotEmpty) {
        buffer.writeln();
        buffer.writeln('Remediation (${_audience == AudienceMode.farmer ? "Agri Pro" : "Home & Kitchen"}):');
        for (final t in treatment) {
          buffer.writeln('• $t');
        }
      }
    }

    buffer.writeln();
    buffer.writeln('Verified via FloraShield AI Intelligence');

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
    if (percent >= 40) return 'CRITICAL';
    if (percent >= 15) return 'MODERATE';
    if (percent > 0) return 'MILD';
    return 'OPTIMAL';
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

    final severityColor = _severityColor(diagnosis.severityPercent);

    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundGradient,
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(diagnosis, provider),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Pathogen ID Header Card
                      _buildPathogenCard(diagnosis, severityColor),
                      const SizedBox(height: 16),

                      // 2. AI Match & Severity Gauges (Side-by-side)
                      _buildMetricsRow(diagnosis, severityColor),
                      const SizedBox(height: 16),

                      // 3. Grad-CAM Heatmap Viewer
                      _buildHeatmapSection(provider, diagnosis),
                      const SizedBox(height: 20),

                      // 4. Tabbed Remediation Panel
                      _buildRemediationPanel(diagnosis),
                      const SizedBox(height: 24),

                      // 5. Action Buttons
                      _buildFooterActions(diagnosis, provider),
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

  Widget _buildTopBar(DiagnosisModel diagnosis, ScanProvider provider) {
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Diagnosis Detail', style: AppTextStyles.heading(size: 18)),
                Text('ID: FS-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}', 
                  style: AppTextStyles.body(size: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          _buildLanguageToggle(provider),
          const SizedBox(width: 10),
          _buildSpeakButton(diagnosis, provider.currentLanguage),
        ],
      ),
    );
  }

  Widget _buildPathogenCard(DiagnosisModel diagnosis, Color severityColor) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      diagnosis.isHealthy ? 'SPECIMEN HEALTHY' : 'PATHOGEN DETECTED',
                      style: AppTextStyles.label(size: 10, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      diagnosis.isHealthy ? diagnosis.plantName : diagnosis.diseaseName,
                      style: AppTextStyles.heading(size: 22),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.neonGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_user_outlined, color: AppColors.neonGreen, size: 12),
                        const SizedBox(width: 4),
                        Text('VALIDATED', style: AppTextStyles.label(size: 9, color: AppColors.neonGreen)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  NeonPill(
                    text: _severityLabel(diagnosis.severityPercent),
                    color: severityColor,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _tagChip(diagnosis.plantName, Icons.eco_outlined),
              if (!diagnosis.isHealthy) ...[
                _tagChip('Fungal Spore Cluster', Icons.bug_report_outlined),
                _tagChip('Necrotic Tissue', Icons.grain_outlined),
              ] else
                _tagChip('Optimal Vigor', Icons.auto_awesome_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tagChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.body(size: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(DiagnosisModel diagnosis, Color severityColor) {
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                CircularGauge(
                  fraction: diagnosis.confidencePercent / 100,
                  color: AppColors.neonGreen,
                  size: 64,
                ),
                const SizedBox(height: 10),
                Text('AI MATCH', style: AppTextStyles.label(size: 10, color: AppColors.textSecondary)),
                Text('${diagnosis.confidencePercent}%', style: AppTextStyles.heading(size: 18)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                CircularGauge(
                  fraction: diagnosis.severityPercent / 100,
                  color: severityColor,
                  size: 64,
                ),
                const SizedBox(height: 10),
                Text('SEVERITY', style: AppTextStyles.label(size: 10, color: AppColors.textSecondary)),
                Text('${diagnosis.severityPercent}%', style: AppTextStyles.heading(size: 18)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeatmapSection(ScanProvider provider, DiagnosisModel diagnosis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Optical Scan Viewer', style: AppTextStyles.heading(size: 15)),
            Row(
              children: [
                _viewToggleChip('Original', !_showHeatmap, () => setState(() => _showHeatmap = false)),
                const SizedBox(width: 8),
                _viewToggleChip('Heatmap', _showHeatmap, () => setState(() => _showHeatmap = true)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (provider.selectedImage != null)
                  Image.file(provider.selectedImage!, fit: BoxFit.cover)
                else
                  Container(color: Colors.black),
                if (_showHeatmap && !diagnosis.isHealthy)
                  HeatmapOverlay(
                    regionX: diagnosis.regionX,
                    regionY: diagnosis.regionY,
                    regionRadius: diagnosis.regionRadius,
                  ),
                // Corner reticles
                Positioned(top: 20, left: 20, child: _reticleCorner(0)),
                Positioned(top: 20, right: 20, child: _reticleCorner(1)),
                Positioned(bottom: 20, left: 20, child: _reticleCorner(3)),
                Positioned(bottom: 20, right: 20, child: _reticleCorner(2)),
              ],
            ),
          ),
        ),
        if (_showHeatmap) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              _legendItem('Affected', AppColors.neonRed),
              const SizedBox(width: 16),
              _legendItem('Risk Zone', AppColors.neonAmber),
              const SizedBox(width: 16),
              _legendItem('Healthy', AppColors.neonGreen),
            ],
          ),
        ],
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.body(size: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _reticleCorner(int quarterTurns) {
    return RotatedBox(
      quarterTurns: quarterTurns,
      child: Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: AppColors.neonGreen, width: 3),
            top: BorderSide(color: AppColors.neonGreen, width: 3),
          ),
        ),
      ),
    );
  }

  Widget _buildRemediationPanel(DiagnosisModel diagnosis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Remediation Protocol', style: AppTextStyles.heading(size: 15)),
        const SizedBox(height: 12),
        _buildAudienceToggle(),
        const SizedBox(height: 16),
        if (diagnosis.isHealthy)
          GlassCard(
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.neonGreen, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No active pathogens detected. Maintain regular hydration and nitrogen monitoring.',
                    style: AppTextStyles.body(size: 13, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          )
        else ...[
          _infoCard(
            icon: Icons.visibility_outlined,
            iconColor: AppColors.neonAmber,
            title: 'Clinical Observations',
            items: diagnosis.symptoms,
          ),
          const SizedBox(height: 12),
          _infoCard(
            icon: Icons.healing_outlined,
            iconColor: AppColors.neonGreen,
            title: 'Prescribed Treatment',
            items: diagnosis.treatmentFor(_audience),
          ),
          const SizedBox(height: 12),
          _infoCard(
            icon: Icons.shield_outlined,
            iconColor: AppColors.accentTeal,
            title: 'Future Prevention',
            items: diagnosis.preventionFor(_audience),
          ),
        ],
      ],
    );
  }

  Widget _buildFooterActions(DiagnosisModel diagnosis, ScanProvider provider) {
    return Column(
      children: [
        if (!diagnosis.isHealthy) ...[
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DosageCalculatorScreen(
                    diseaseName: diagnosis.diseaseName,
                    isHealthy: diagnosis.isHealthy,
                  ),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.calculate_outlined, size: 20),
              label: const Text('GENERATE SPRAY RECIPE', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: _secondaryAction(
                label: 'EXPORT PDF',
                icon: Icons.picture_as_pdf_outlined,
                onTap: _isGeneratingPdf ? null : () => _exportPdf(diagnosis, provider.selectedImage),
                isLoading: _isGeneratingPdf,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _secondaryAction(
                label: 'SHARE REPORT',
                icon: Icons.share_outlined,
                onTap: () => _shareDiagnosis(diagnosis),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _secondaryAction(
                label: 'DRONE MISSION',
                icon: Icons.flight_takeoff_outlined,
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Drone Flight Waypoints — coming soon')),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _secondaryAction(
                label: 'INSURANCE CLAIM',
                icon: Icons.assignment_outlined,
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Insurance Export — coming soon')),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () {
              provider.reset();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            },
            child: Text('DISCARD & SCAN ANOTHER', 
              style: AppTextStyles.label(size: 11, color: AppColors.textSecondary)),
          ),
        ),
      ],
    );
  }

  Widget _secondaryAction({required String label, required IconData icon, required VoidCallback? onTap, bool isLoading = false}) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: AppColors.surface,
          padding: EdgeInsets.zero,
        ),
        child: isLoading 
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.neonGreen))
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: AppColors.textPrimary),
                const SizedBox(width: 8),
                Text(label, style: AppTextStyles.label(size: 11, color: AppColors.textPrimary)),
              ],
            ),
      ),
    );
  }

  Widget _buildLanguageToggle(ScanProvider provider) {
    if (provider.isTranslating) {
      return const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.neonGreen));
    }

    return PopupMenuButton<String>(
      color: AppColors.bgDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (language) => context.read<ScanProvider>().switchLanguage(language),
      itemBuilder: (context) => ['English', 'Hindi', 'Marathi', 'Tamil', 'Telugu', 'Punjabi', 'Bengali', 'Gujarati']
          .map((lang) => PopupMenuItem<String>(
                value: lang,
                child: Text(lang, style: AppTextStyles.body(size: 13)),
              ))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.translate, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 5),
            Text(provider.currentLanguage.substring(0, 3).toUpperCase(), style: AppTextStyles.label(size: 10)),
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
        final parts = [diagnosis.plantName, if (!diagnosis.isHealthy) diagnosis.diseaseName, ...diagnosis.treatmentFor(_audience)];
        setState(() => _isSpeaking = true);
        await _ttsService.speak(parts.join('. '), languageName: language);
        if (mounted) setState(() => _isSpeaking = false);
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _isSpeaking ? AppColors.neonGreen.withValues(alpha: 0.1) : AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: _isSpeaking ? AppColors.neonGreen : AppColors.border),
        ),
        child: Icon(
          _isSpeaking ? Icons.stop : Icons.volume_up_outlined,
          size: 18,
          color: _isSpeaking ? AppColors.neonGreen : AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _viewToggleChip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.neonGreen : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? AppColors.neonGreen : AppColors.border),
        ),
        child: Text(
          label,
          style: AppTextStyles.body(
            size: 11,
            weight: FontWeight.w600,
            color: active ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildAudienceToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(child: _audienceSegment('Home & Kitchen', Icons.home_outlined, AudienceMode.homeGardener)),
          const SizedBox(width: 4),
          Expanded(child: _audienceSegment('Agri Pro', Icons.agriculture_outlined, AudienceMode.farmer)),
        ],
      ),
    );
  }

  Widget _audienceSegment(String label, IconData icon, AudienceMode mode) {
    final bool active = _audience == mode;
    return GestureDetector(
      onTap: () => setState(() => _audience = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: active ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: active ? AppColors.neonGreen : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(label, style: AppTextStyles.body(size: 11, weight: active ? FontWeight.w700 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildNotAPlantCard(String detectedName) {
    return GlassCard(
      child: Column(
        children: [
          const Icon(Icons.info_outline, color: AppColors.neonAmber, size: 32),
          const SizedBox(height: 12),
          Text('Non-Biological Specimen', style: AppTextStyles.heading(size: 16)),
          const SizedBox(height: 6),
          Text('This looks like: $detectedName', style: AppTextStyles.body(size: 14, weight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('For a disease diagnosis, please photograph a crop leaf or plant part.', 
            textAlign: TextAlign.center, style: AppTextStyles.body(size: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _infoCard({required IconData icon, required Color iconColor, required String title, required List<String> items}) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 10),
              Text(title, style: AppTextStyles.heading(size: 14)),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(width: 4, height: 4, decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(item, style: AppTextStyles.body(size: 13, color: AppColors.textPrimary))),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
