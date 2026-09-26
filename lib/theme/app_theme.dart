import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// "PlantIQ" premium dark glassmorphic design system.
/// A deep emerald/aurora palette with soft neon glows, frosted glass
/// surfaces and gradient-lit accents.
class AppColors {
  static const Color bgDark = Color(0xFF050B08); // deepest background
  static const Color bgDark2 = Color(0xFF0A2E1F); // gradient end
  static const Color bgDark3 = Color(0xFF0F3D2A); // gradient mid stop (adds depth)

  static const Color glassFill = Color(0x22D8FFEF); // translucent card fill, mint-tinted
  static const Color glassBorder = Color(0x3DBFFFDD); // translucent border

  static const Color neonGreen = Color(0xFF2EE6A6); // primary accent
  static const Color neonGreenBright = Color(0xFF8FFFD1); // highlight for glows/gradients
  static const Color neonAmber = Color(0xFFFFC15E); // warning/risk accent
  static const Color neonRed = Color(0xFFFF6673); // severe/danger accent
  static const Color accentTeal = Color(0xFF2DD4E8); // secondary aurora accent

  static const Color textPrimary = Color(0xFFF7FBF9); // near-white
  static const Color textSecondary = Color(0xFFA7C4B3); // muted green-grey
}

class AppTextStyles {
  static TextStyle heading({double size = 22, Color? color, FontWeight? weight}) {
    return GoogleFonts.spaceGrotesk(
      fontSize: size,
      fontWeight: weight ?? FontWeight.bold,
      letterSpacing: -0.3,
      height: 1.15,
      color: color ?? AppColors.textPrimary,
    );
  }

  static TextStyle body({double size = 14, Color? color, FontWeight? weight}) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight ?? FontWeight.normal,
      height: 1.4,
      color: color ?? AppColors.textPrimary,
    );
  }

  static TextStyle label({double size = 11, Color? color}) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.1,
      color: color ?? AppColors.textSecondary,
    );
  }
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bgDark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.neonGreen,
        brightness: Brightness.dark,
        primary: AppColors.neonGreen,
        secondary: AppColors.neonAmber,
        error: AppColors.neonRed,
        surface: AppColors.bgDark2,
      ),
      textTheme: TextTheme(
        headlineLarge: AppTextStyles.heading(size: 28),
        headlineMedium: AppTextStyles.heading(size: 22),
        titleLarge: AppTextStyles.heading(size: 18),
        bodyLarge: AppTextStyles.body(size: 16),
        bodyMedium: AppTextStyles.body(size: 14),
        labelSmall: AppTextStyles.label(),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.heading(size: 18),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.neonGreen,
          foregroundColor: AppColors.bgDark,
          textStyle: AppTextStyles.body(size: 16, weight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          elevation: 8,
          shadowColor: AppColors.neonGreen.withOpacity(0.45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          backgroundColor: Colors.white.withOpacity(0.03),
          side: BorderSide(color: AppColors.glassBorder.withOpacity(0.9), width: 1.3),
          textStyle: AppTextStyles.body(size: 16, weight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  /// The signature dark aurora-emerald gradient background used behind
  /// every screen — three stops on a soft diagonal for extra depth,
  /// instead of the old flat top-to-bottom two-tone.
  static BoxDecoration get backgroundGradient => const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.bgDark, AppColors.bgDark3, AppColors.bgDark2],
      stops: [0.0, 0.55, 1.0],
    ),
  );
}

/// A frosted-glass card with a soft ambient glow — the signature
/// container style for this app. Backdrop blur + a faint gradient fill,
/// a light mint-tinted border, and a subtle drop shadow for lift.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(18);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppColors.neonGreen.withOpacity(0.05),
            blurRadius: 30,
            spreadRadius: -6,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            width: double.infinity,
            padding: padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.06),
                  AppColors.glassFill,
                ],
              ),
              borderRadius: radius,
              border: Border.all(color: AppColors.glassBorder, width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A neon status pill (e.g. "SEVERE", "HIGH FUNGAL RISK", "Demo Mode")
/// with a soft gradient fill and a matching glow.
class NeonPill extends StatelessWidget {
  final String text;
  final Color color;

  const NeonPill({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.30), color.withOpacity(0.12)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.65), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.30),
            blurRadius: 12,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: Text(
        text.toUpperCase(),
        style: AppTextStyles.label(size: 10, color: color),
      ),
    );
  }
}

/// Reusable circular gauge (used for confidence score, risk score, etc.)
/// with a glowing arc instead of a flat one.
class CircularGauge extends StatelessWidget {
  final double fraction; // 0.0 - 1.0
  final Color color;
  final double size;
  final String? centerText;

  const CircularGauge({
    super.key,
    required this.fraction,
    required this.color,
    this.size = 70,
    this.centerText,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GaugePainter(fraction: fraction, color: color),
        child: Center(
          child: Text(
            centerText ?? '${(fraction * 100).toInt()}%',
            style: TextStyle(
              color: color,
              fontSize: size * 0.22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double fraction;
  final Color color;

  _GaugePainter({required this.fraction, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = color.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    const startAngle = -3.14159 * 0.75;
    const sweepAngle = 3.14159 * 1.5;
    final valueSweep = sweepAngle * fraction;

    canvas.drawArc(rect, startAngle, sweepAngle, false, trackPaint);
    if (fraction > 0) {
      canvas.drawArc(rect, startAngle, valueSweep, false, glowPaint);
      canvas.drawArc(rect, startAngle, valueSweep, false, valuePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.fraction != fraction || oldDelegate.color != color;
}