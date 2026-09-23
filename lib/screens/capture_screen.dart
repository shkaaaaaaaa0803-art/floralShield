import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/scan_provider.dart';
import '../theme/app_theme.dart';
import 'results_screen.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<File> _additionalImages = [];

  Future<void> _addAngle() async {
    if (_additionalImages.length >= 2) return;
    final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (picked == null) return;
    setState(() => _additionalImages.add(File(picked.path)));
  }

  void _removeAngle(int index) {
    setState(() => _additionalImages.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.backgroundGradient,
        child: SafeArea(
          child: Consumer<ScanProvider>(
            builder: (context, provider, _) {
              return Column(
                children: [
                  // Top bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                        ),
                        const SizedBox(width: 14),
                        Text('Camera', style: AppTextStyles.heading(size: 18)),
                      ],
                    ),
                  ),

                  // Image preview area with targeting reticle overlay
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Container(
                              color: Colors.white.withOpacity(0.05),
                              child: provider.selectedImage != null
                                  ? Image.file(provider.selectedImage!, fit: BoxFit.cover)
                                  : const Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  size: 64,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),

                            // Corner reticle frame (visual only, matches reference design)
                            if (provider.status != ScanStatus.analyzing)
                              const _ReticleOverlay(),

                            // Analyzing overlay
                            if (provider.status == ScanStatus.analyzing)
                              Container(
                                color: Colors.black.withOpacity(0.55),
                                child: Center(
                                  child: GlassCard(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 14,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.neonGreen,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text('Analyzing...', style: AppTextStyles.body(size: 13)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Additional angle photos (optional, improves accuracy)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      children: [
                        Text('Add more angles (optional)', style: AppTextStyles.body(size: 11, color: AppColors.textSecondary)),
                        const SizedBox(width: 6),
                        Text('${_additionalImages.length}/2', style: AppTextStyles.label(size: 10)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 64,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      children: [
                        ..._additionalImages.asMap().entries.map((entry) {
                          final index = entry.key;
                          final file = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(file, width: 64, height: 64, fit: BoxFit.cover),
                                ),
                                Positioned(
                                  top: -4,
                                  right: -4,
                                  child: GestureDetector(
                                    onTap: () => _removeAngle(index),
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: const BoxDecoration(
                                        color: AppColors.neonRed,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, size: 12, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        if (_additionalImages.length < 2)
                          GestureDetector(
                            onTap: _addAngle,
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.glassBorder, style: BorderStyle.solid),
                              ),
                              child: const Icon(Icons.add, color: AppColors.textSecondary, size: 22),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Camera / Gallery / Analyze controls
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: OutlinedButton.icon(
                                  onPressed: () => provider.pickImage(ImageSource.camera),
                                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                                  label: const Text('Camera'),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: OutlinedButton.icon(
                                  onPressed: () => provider.pickImage(ImageSource.gallery),
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
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: provider.selectedImage == null ||
                                provider.status == ScanStatus.analyzing
                                ? null
                                : () async {
                              await provider.analyzeSelectedImage(
                                additionalImages: _additionalImages.isNotEmpty ? _additionalImages : null,
                              );
                              if (provider.status == ScanStatus.success &&
                                  context.mounted) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const ResultsScreen(),
                                  ),
                                );
                              } else if (provider.status == ScanStatus.error &&
                                  context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      provider.errorMessage ?? 'Something went wrong',
                                    ),
                                    backgroundColor: AppColors.neonRed,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.search, size: 20),
                            label: Text(
                              provider.status == ScanStatus.analyzing
                                  ? 'Analyzing...'
                                  : 'Analyze Plant',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Visual-only corner reticle overlay, matching the "Live Leaf Analyzer"
/// targeting frame from the reference design.
class _ReticleOverlay extends StatelessWidget {
  const _ReticleOverlay();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: CustomPaint(
        painter: _CornerPainter(color: AppColors.neonGreen),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  _CornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.85)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 26.0;

    // Top-left
    canvas.drawLine(const Offset(0, 0), const Offset(len, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, len), paint);
    // Top-right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - len, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, len), paint);
    // Bottom-left
    canvas.drawLine(Offset(0, size.height), Offset(len, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - len), paint);
    // Bottom-right
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - len, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - len), paint);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) => false;
}