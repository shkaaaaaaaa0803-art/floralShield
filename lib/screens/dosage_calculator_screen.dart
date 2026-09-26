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
  final TextEditingController _acreController = TextEditingController(text: '1.0');
  double _acres = 1.0;

  final Map<String, _DosageInfo> _dosageTable = {
    'fungal': _DosageInfo(
      productName: 'Copper Oxychloride 50% WP',
      mlPerAcre: 600,
      waterLitersPerAcre: 200,
      activeIngredient: 'Copper Oxychloride',
    ),
    'bacterial': _DosageInfo(
      productName: 'Streptomycin Sulphate 9% SP',
      mlPerAcre: 200,
      waterLitersPerAcre: 200,
      activeIngredient: 'Streptomycin',
    ),
    'pest': _DosageInfo(
      productName: 'Neem Oil / Azadirachtin 1500ppm',
      mlPerAcre: 400,
      waterLitersPerAcre: 200,
      activeIngredient: 'Azadirachtin',
    ),
    'default': _DosageInfo(
      productName: 'Broad-Spectrum Bio-Fungicide',
      mlPerAcre: 500,
      waterLitersPerAcre: 200,
      activeIngredient: 'Bacillus subtilis',
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
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Tank-Mix Recipe Card (Mockup #6)
                      _buildRecipeCard(dosage),
                      const SizedBox(height: 16),

                      // 2. Dosage Math Grid
                      _buildMathGrid(dosage, totalMl, totalWater),
                      const SizedBox(height: 20),

                      // 3. Tank-Mixing SOP Checklist
                      _buildSOPChecklist(),
                      const SizedBox(height: 20),

                      // 4. UAV Mission Planner / Drone Flight Card
                      _buildUAVMissionCard(),
                      const SizedBox(height: 20),

                      // 5. Compliance & PPE info
                      _buildComplianceFooter(),
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
              Text('Spray Mission Planner', style: AppTextStyles.heading(size: 18)),
              Text('Professional precision calculations', style: AppTextStyles.body(size: 11, color: AppColors.textSecondary)),
            ],
          ),
          const Spacer(),
          const Icon(Icons.share_outlined, color: AppColors.textPrimary, size: 22),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(_DosageInfo dosage) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.neonGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.science_outlined, color: AppColors.neonGreen, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tank-Mix Component', style: AppTextStyles.label(size: 10)),
                    Text(dosage.productName, style: AppTextStyles.heading(size: 16)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _recipeMeta('Active ingredient', dosage.activeIngredient),
              _recipeMeta('Target', widget.isHealthy ? 'Maintenance' : widget.diseaseName),
            ],
          ),
        ],
      ),
    );
  }

  Widget _recipeMeta(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.body(size: 10, color: AppColors.textSecondary)),
        Text(value, style: AppTextStyles.body(size: 13, weight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildMathGrid(_DosageInfo dosage, double totalMl, double totalWater) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dosage Math Parameters', style: AppTextStyles.heading(size: 15)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.8,
          children: [
            _mathTile('Coverage Area', '${_acres.toStringAsFixed(1)} ac', Icons.grid_view_outlined, AppColors.accentTeal, isEditable: true),
            _mathTile('Carrier Volume', '${dosage.waterLitersPerAcre} L/ac', Icons.opacity_outlined, AppColors.accentTeal),
            _mathTile('Total Water', '${totalWater.toStringAsFixed(0)} Liters', Icons.water_drop_outlined, AppColors.neonGreen),
            _mathTile('Active Chemical', '${totalMl.toStringAsFixed(0)} ml', Icons.biotech_outlined, AppColors.neonAmber),
          ],
        ),
      ],
    );
  }

  Widget _mathTile(String label, String value, IconData icon, Color color, {bool isEditable = false}) {
    return GestureDetector(
      onTap: isEditable ? _showAreaInput : null,
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Text(label, style: AppTextStyles.label(size: 9)),
                if (isEditable) const Icon(Icons.edit, size: 10, color: AppColors.neonGreen),
              ],
            ),
            const Spacer(),
            Text(value, style: AppTextStyles.heading(size: 16, color: color)),
          ],
        ),
      ),
    );
  }

  void _showAreaInput() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Edit Coverage Area', style: AppTextStyles.heading(size: 16)),
        content: TextField(
          controller: _acreController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: 'Acres'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              _updateAcres(_acreController.text);
              Navigator.pop(ctx);
            },
            child: const Text('UPDATE'),
          ),
        ],
      ),
    );
  }

  Widget _buildSOPChecklist() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tank-Mixing SOP Checklist', style: AppTextStyles.heading(size: 14)),
          const SizedBox(height: 12),
          _checkItem('Half-fill spray tank with clean water.', true),
          _checkItem('Add prescribed chemical while agitating.', true),
          _checkItem('Top up with water to final volume.', false),
          _checkItem('Verify pH levels (optimal: 5.5 - 6.5).', false),
        ],
      ),
    );
  }

  Widget _checkItem(String text, bool done) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, 
               size: 18, color: done ? AppColors.neonGreen : AppColors.border),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppTextStyles.body(size: 12))),
        ],
      ),
    );
  }

  Widget _buildUAVMissionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.textPrimary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flight_takeoff, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text('UAV Mission Parameters', style: AppTextStyles.heading(size: 14, color: Colors.white)),
              const Spacer(),
              const Icon(Icons.info_outline, color: Colors.white54, size: 16),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _uavStat('FLIGHT HEIGHT', '3.5m'),
              _uavStat('SWATH WIDTH', '4.2m'),
              _uavStat('SPEED', '5.0 m/s'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white24),
              ),
              child: const Text('EXPORT MISSION (KML)'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _uavStat(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label(size: 8, color: Colors.white54)),
        const SizedBox(height: 2),
        Text(val, style: AppTextStyles.body(size: 14, color: Colors.white, weight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildComplianceFooter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Regulatory & PPE Compliance', style: AppTextStyles.heading(size: 14)),
        const SizedBox(height: 10),
        Row(
          children: [
            _ppeIcon(Icons.masks_outlined, 'Respirator'),
            _ppeIcon(Icons.pan_tool_outlined, 'Gloves'),
            _ppeIcon(Icons.visibility_outlined, 'Eyewear'),
            _ppeIcon(Icons.checkroom_outlined, 'Coveralls'),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'EPA Reg No: 45002-12. Follow all label directions. Wash thoroughly after handling.',
          style: AppTextStyles.body(size: 10, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _ppeIcon(IconData icon, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 24, color: AppColors.textPrimary),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.label(size: 7)),
        ],
      ),
    );
  }
}

class _DosageInfo {
  final String productName;
  final String activeIngredient;
  final double mlPerAcre;
  final double waterLitersPerAcre;

  _DosageInfo({
    required this.productName,
    required this.activeIngredient,
    required this.mlPerAcre,
    required this.waterLitersPerAcre,
  });
}
