import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DosageCalculatorScreen extends StatefulWidget {
  final String diseaseName;
  final bool isHealthy;

  const DosageCalculatorScreen({
    super.key,
    required this.diseaseName,
    required this.isHealthy,
  });

  @override
  State<DosageCalculatorScreen> createState() => _DosageCalculatorScreenState();
}

class _DosageCalculatorScreenState extends State<DosageCalculatorScreen> {
  final TextEditingController _acreController = TextEditingController(text: '1');
  double _acres = 1.0;

  // Simple reference dosage rates (per acre) for common fungicide/pesticide
  // categories. This is a general-purpose estimate, not a substitute for
  // product label instructions or expert advice.
  final Map<String, _DosageInfo> _dosageTable = {
    'fungal': _DosageInfo(
      productName: 'Copper Oxychloride (Fungicide)',
      mlPerAcre: 600,
      waterLitersPerAcre: 200,
    ),
    'bacterial': _DosageInfo(
      productName: 'Streptomycin Sulphate (Bactericide)',
      mlPerAcre: 200,
      waterLitersPerAcre: 200,
    ),
    'pest': _DosageInfo(
      productName: 'Neem Oil / Imidacloprid (Pesticide)',
      mlPerAcre: 400,
      waterLitersPerAcre: 200,
    ),
    'default': _DosageInfo(
      productName: 'General Purpose Fungicide',
      mlPerAcre: 500,
      waterLitersPerAcre: 200,
    ),
  };

  _DosageInfo get _selectedDosage {
    final name = widget.diseaseName.toLowerCase();
    if (name.contains('blight') || name.contains('mold') || name.contains('mildew') || name.contains('rot')) {
      return _dosageTable['fungal']!;
    } else if (name.contains('bacterial') || name.contains('wilt')) {
      return _dosageTable['bacterial']!;
    } else if (name.contains('pest') || name.contains('insect') || name.contains('aphid')) {
      return _dosageTable['pest']!;
    }
    return _dosageTable['default']!;
  }

  void _updateAcres(String value) {
    setState(() {
      _acres = double.tryParse(value) ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dosage = _selectedDosage;
    final totalMl = dosage.mlPerAcre * _acres;
    final totalWater = dosage.waterLitersPerAcre * _acres;

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
                    Text('Dosage Calculator', style: AppTextStyles.heading(size: 18)),
                  ],
                ),
                const SizedBox(height: 20),

                if (widget.isHealthy)
                  GlassCard(
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.neonGreen),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This plant is healthy — no treatment dosage needed. Showing a general-purpose reference calculation.',
                            style: AppTextStyles.body(size: 13, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  GlassCard(
                    child: Row(
                      children: [
                        const Icon(Icons.bug_report_outlined, color: AppColors.neonAmber),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Diagnosed condition', style: AppTextStyles.body(size: 11, color: AppColors.textSecondary)),
                              const SizedBox(height: 2),
                              Text(widget.diseaseName, style: AppTextStyles.heading(size: 15)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                // Field size input
                Text('Field Size (acres)', style: AppTextStyles.body(size: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextField(
                    controller: _acreController,
                    onChanged: _updateAcres,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: AppTextStyles.heading(size: 20),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'e.g. 1.5',
                      suffixText: 'acres',
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text('Recommended Application', style: AppTextStyles.heading(size: 15)),
                const SizedBox(height: 12),

                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dosage.productName, style: AppTextStyles.heading(size: 15)),
                      const SizedBox(height: 16),
                      _resultRow('Product quantity', '${totalMl.toStringAsFixed(0)} ml', AppColors.neonGreen),
                      const SizedBox(height: 10),
                      _resultRow('Water quantity', '${totalWater.toStringAsFixed(0)} liters', AppColors.textPrimary),
                      const SizedBox(height: 10),
                      _resultRow('Per acre rate', '${dosage.mlPerAcre} ml / ${dosage.waterLitersPerAcre} L', AppColors.textSecondary),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                GlassCard(
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.neonAmber, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'This is a general reference estimate. Always confirm exact dosage with the product label or a local agriculture expert before application.',
                          style: AppTextStyles.body(size: 11, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _resultRow(String label, String value, Color valueColor) {
    return Row(
      children: [
        Expanded(child: Text(label, style: AppTextStyles.body(size: 13, color: AppColors.textSecondary))),
        Text(value, style: AppTextStyles.body(size: 15, weight: FontWeight.w700, color: valueColor)),
      ],
    );
  }
}

class _DosageInfo {
  final String productName;
  final double mlPerAcre;
  final double waterLitersPerAcre;

  _DosageInfo({
    required this.productName,
    required this.mlPerAcre,
    required this.waterLitersPerAcre,
  });
}