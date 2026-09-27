import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum ApplicationMethod { drone, tractor }

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
  ApplicationMethod _method = ApplicationMethod.tractor;

  // A standard drone tank payload used only to estimate sorties/flight
  // time for the Mission Logistics card -- actual drone models vary.
  static const double _droneTankLiters = 20.0;
  static const double _avgSortieMinutes = 12.0; // per full tank, incl. turnaround

  // WALES tank-mixing order: Water, Adjuvant/wettable-powder pre-mix,
  // Little-by-little, Ensure agitation, Spray promptly.
  final List<bool> _checklist = List.filled(5, false);

  // Simple reference dosage rates (per acre) for common fungicide/pesticide
  // categories. This is a general-purpose estimate, not a substitute for
  // product label instructions or expert advice. `activeIngredientPercent`
  // reflects a typical commercial formulation strength so the "active
  // ingredient weight" figure is a real calculation, not an invented one --
  // still always verify against the actual product label.
  final Map<String, _DosageInfo> _dosageTable = {
    'fungal': _DosageInfo(
      productName: 'Copper Oxychloride (Fungicide)',
      fracGroup: 'FRAC M01',
      mlPerAcreTractor: 600,
      waterLitersPerAcreTractor: 200,
      waterLitersPerAcreDrone: 25,
      activeIngredientPercent: 50,
      phiDaysRange: '7-10 days',
      reiHours: '24 hours',
    ),
    'bacterial': _DosageInfo(
      productName: 'Streptomycin Sulphate (Bactericide)',
      fracGroup: 'FRAC 25',
      mlPerAcreTractor: 200,
      waterLitersPerAcreTractor: 200,
      waterLitersPerAcreDrone: 20,
      activeIngredientPercent: 90,
      phiDaysRange: '3-5 days',
      reiHours: '12 hours',
    ),
    'pest': _DosageInfo(
      productName: 'Imidacloprid (Insecticide)',
      fracGroup: 'IRAC 4A',
      mlPerAcreTractor: 400,
      waterLitersPerAcreTractor: 200,
      waterLitersPerAcreDrone: 20,
      activeIngredientPercent: 17.8,
      phiDaysRange: '5-7 days',
      reiHours: '12 hours',
    ),
    'default': _DosageInfo(
      productName: 'General Purpose Fungicide',
      fracGroup: 'FRAC M-group',
      mlPerAcreTractor: 500,
      waterLitersPerAcreTractor: 200,
      waterLitersPerAcreDrone: 25,
      activeIngredientPercent: 50,
      phiDaysRange: '7-10 days',
      reiHours: '24 hours',
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

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature — coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dosage = _selectedDosage;
    final bool isDrone = _method == ApplicationMethod.drone;

    final double waterPerAcre = isDrone ? dosage.waterLitersPerAcreDrone : dosage.waterLitersPerAcreTractor;
    final double totalMl = dosage.mlPerAcreTractor * _acres; // product volume doesn't change with carrier method
    final double totalWater = waterPerAcre * _acres;
    final double activeIngredientGrams = totalMl * (dosage.activeIngredientPercent / 100);

    final double sorties = isDrone && totalWater > 0 ? (totalWater / _droneTankLiters).ceilToDouble() : 0;
    final double flightMinutes = sorties * _avgSortieMinutes;

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
                    Text('Dosage & Spray Planner', style: AppTextStyles.heading(size: 18)),
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
                const SizedBox(height: 16),

                // Application method toggle
                Text('Application Platform', style: AppTextStyles.body(size: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _methodTile(
                        icon: Icons.airplanemode_active,
                        label: 'Drone (ULV)',
                        active: isDrone,
                        onTap: () => setState(() => _method = ApplicationMethod.drone),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _methodTile(
                        icon: Icons.agriculture,
                        label: 'Tractor / Knapsack',
                        active: !isDrone,
                        onTap: () => setState(() => _method = ApplicationMethod.tractor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Text('Recommended Application', style: AppTextStyles.heading(size: 15)),
                const SizedBox(height: 12),

                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(dosage.productName, style: AppTextStyles.heading(size: 15))),
                          NeonPill(text: dosage.fracGroup, color: AppColors.accentTeal),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _resultRow('Product quantity', '${totalMl.toStringAsFixed(0)} ml', AppColors.neonGreen),
                      const SizedBox(height: 10),
                      _resultRow('Water quantity', '${totalWater.toStringAsFixed(0)} liters', AppColors.textPrimary),
                      const SizedBox(height: 10),
                      _resultRow(
                        'Active ingredient (~${dosage.activeIngredientPercent}%)',
                        '${activeIngredientGrams.toStringAsFixed(1)} g',
                        AppColors.accentTeal,
                      ),
                      const SizedBox(height: 10),
                      _resultRow(
                        'Per acre rate',
                        '${dosage.mlPerAcreTractor.toStringAsFixed(0)} ml / ${waterPerAcre.toStringAsFixed(0)} L',
                        AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Mission logistics -- drone only
                if (isDrone && totalWater > 0)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.neonGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.flight_takeoff, color: AppColors.neonGreen, size: 26),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Mission Logistics', style: AppTextStyles.heading(size: 14, color: AppColors.neonGreen)),
                              const SizedBox(height: 2),
                              Text(
                                '${sorties.toStringAsFixed(0)} sortie${sorties == 1 ? '' : 's'} required '
                                    '(${_droneTankLiters.toStringAsFixed(0)}L tank) · '
                                    'Est. flight time ~${flightMinutes.toStringAsFixed(0)} min',
                                style: AppTextStyles.body(size: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                if (isDrone && totalWater > 0) const SizedBox(height: 16),

                // Tank-mixing safety checklist
                Text('Tank-Mixing Checklist (WALES Method)', style: AppTextStyles.heading(size: 15)),
                const SizedBox(height: 12),
                GlassCard(
                  child: Column(
                    children: [
                      _checklistItem(0, 'Water — fill tank to 50% with clean water, verify pH 6.0-6.5.'),
                      _checklistItem(1, 'Adjuvant / wettable-powder pre-mix in a bucket of water first.'),
                      _checklistItem(2, 'Little by little — add pre-mix slowly to the tank with agitation running.'),
                      _checklistItem(3, 'Ensure agitation continues while topping up to full volume.'),
                      _checklistItem(4, 'Spray promptly — apply within the SOP time window, don\'t let mix stand.'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // PPE & regulatory intervals -- explicitly framed as general
                // guidance, not exact per-product regulatory data.
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Safety Intervals & PPE', style: AppTextStyles.heading(size: 14)),
                      const SizedBox(height: 4),
                      Text(
                        'Typical range for this product category — always confirm the exact PHI/REI on your specific product label.',
                        style: AppTextStyles.body(size: 11, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _intervalStat('Pre-Harvest Interval', dosage.phiDaysRange, Icons.event_available_outlined)),
                          const SizedBox(width: 10),
                          Expanded(child: _intervalStat('Worker Re-Entry', dosage.reiHours, Icons.timer_outlined)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: const [
                          _PpeChip(icon: Icons.back_hand_outlined, label: 'Nitrile gloves'),
                          _PpeChip(icon: Icons.masks_outlined, label: 'Respirator mask'),
                          _PpeChip(icon: Icons.remove_red_eye_outlined, label: 'Safety goggles'),
                          _PpeChip(icon: Icons.checkroom_outlined, label: 'Full-sleeve coveralls'),
                        ],
                      ),
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
                          'This is a general reference estimate. Always confirm exact dosage, PHI/REI, and PPE with the product label or a local agriculture expert before application.',
                          style: AppTextStyles.body(size: 11, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _comingSoon('Drone flight path export (.KML)'),
                        icon: const Icon(Icons.route_outlined, size: 18),
                        label: const Text('Export Flight Path'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _comingSoon('Application record PDF'),
                        icon: const Icon(Icons.description_outlined, size: 18),
                        label: const Text('Save Record'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _methodTile({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? AppColors.neonGreen : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? AppColors.neonGreen : AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: active ? Colors.white : AppColors.textSecondary),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.body(
                size: 11,
                weight: FontWeight.w600,
                color: active ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _checklistItem(int index, String text) {
    final checked = _checklist[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: () => setState(() => _checklist[index] = !_checklist[index]),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              checked ? Icons.check_box : Icons.check_box_outline_blank,
              size: 20,
              color: checked ? AppColors.neonGreen : AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  text,
                  style: AppTextStyles.body(
                    size: 13,
                    color: checked ? AppColors.textSecondary : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _intervalStat(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.accentTeal),
          const SizedBox(height: 6),
          Text(value, style: AppTextStyles.heading(size: 13)),
          Text(label, style: AppTextStyles.body(size: 9, color: AppColors.textSecondary)),
        ],
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

class _PpeChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PpeChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.body(size: 11, weight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _DosageInfo {
  final String productName;
  final String fracGroup;
  final double mlPerAcreTractor;
  final double waterLitersPerAcreTractor;
  final double waterLitersPerAcreDrone;
  final double activeIngredientPercent;
  final String phiDaysRange;
  final String reiHours;

  _DosageInfo({
    required this.productName,
    required this.fracGroup,
    required this.mlPerAcreTractor,
    required this.waterLitersPerAcreTractor,
    required this.waterLitersPerAcreDrone,
    required this.activeIngredientPercent,
    required this.phiDaysRange,
    required this.reiHours,
  });
}