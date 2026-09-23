import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// "PlantIQ" dark glassmorphic design system
class AppColors {
  static const Color bgDark = Color(0xFF0B1D14); // deepest background
  static const Color bgDark2 = Color(0xFF122A1D); // gradient end
  static const Color glassFill = Color(0x1AFFFFFF); // translucent card fill
  static const Color glassBorder = Color(0x33FFFFFF); // translucent border
  static const Color neonGreen = Color(0xFF3DDC84); // primary accent
  static const Color neonAmber = Color(0xFFFFB020); // warning/risk accent
  static const Color neonRed = Color(0xFFFF5A52); // severe/danger accent
  static const Color textPrimary = Color(0xFFF3F7F4); // near-white
  static const Color textSecondary = Color(0xFFA9BDB0); // muted green-grey
}

class AppTextStyles {
  static TextStyle heading({double size = 22, Color? color, FontWeight? weight}) {
    return GoogleFonts.spaceGrotesk(
      fontSize: size,
      fontWeight: weight ?? FontWeight.bold,
      color: color ?? AppColors.textPrimary,
    );
  }

  static TextStyle body({double size = 14, Color? color, FontWeight? weight}) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight ?? FontWeight.normal,
      color: color ?? AppColors.textPrimary,
    );
  }

  static TextStyle label({double size = 11, Color? color}) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.0,
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.glassBorder, width: 1.2),
          textStyle: AppTextStyles.body(size: 16, weight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  /// The signature dark green gradient background used behind every screen.
  static BoxDecoration get backgroundGradient => const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [AppColors.bgDark, AppColors.bgDark2],
    ),
  );
}

/// A frosted-glass card - the signature container style for this app.
/// Uses backdrop blur + translucent fill + thin light border.
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
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: AppColors.glassFill,
            borderRadius: radius,
            border: Border.all(color: AppColors.glassBorder, width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A neon status pill (e.g. "SEVERE", "HIGH FUNGAL RISK", "Demo Mode").
class NeonPill extends StatelessWidget {
  final String text;
  final Color color;

  const NeonPill({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.6), width: 1),
      ),
      child: Text(
        text.toUpperCase(),
        style: AppTextStyles.label(size: 10, color: color),
      ),
    );
  }
}

/// Reusable circular gauge (used for confidence score, risk score, etc.)
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

    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    const startAngle = -3.14159 * 0.75;
    const sweepAngle = 3.14159 * 1.5;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, trackPaint);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle * fraction, false, valuePaint);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) => oldDelegate.fraction != fraction;
}