import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// "FloraShield AI" design system - light, card-based, badge-heavy.
/// Matches the reference UI: a soft lavender-white canvas, crisp white
/// cards on a subtle shadow (not a dark glassmorphic blur), a deep forest
/// green as the primary accent, and flat colored badges instead of glow.
class AppColors {
  // The app's actual screen background (soft lavender-grey canvas).
  static const Color bgDark2 = Color(0xFFF3F4FA);
  // Kept for API compatibility; a touch deeper than bgDark2, unused by
  // default but available if a screen wants a secondary background tone.
  static const Color bgDark3 = Color(0xFFEDEFF8);

  // NOTE: bgDark is white, not literally "dark" - see the design note
  // above. It's the color drawn ON TOP of a solid accent fill (icons on
  // a green badge, text on a green button), which needs to be white
  // against this theme's dark, saturated green. Also doubles as a plain
  // card-surface white where needed. The name is kept only so every
  // screen that already references AppColors.bgDark keeps compiling.
  static const Color bgDark = Color(0xFFFFFFFF);

  // Surface and border tokens
  static const Color surface = Color(0xFFFFFFFF);       // white card/button surface
  static const Color surfaceMuted = Color(0xFFF1F6F3);  // light grey-green inner fill
  static const Color border = Color(0xFFE3ECE6);        // hairline border color

  static const Color glassFill = Color(0xFFFFFFFF); // card surface
  static const Color glassBorder = Color(0x14101815); // hairline card edge

  static const Color neonGreen = Color(0xFF0E6B45); // primary accent (deep forest green)
  static const Color neonGreenBright = Color(0xFF34A870); // lighter green for gradient accents
  static const Color neonAmber = Color(0xFFF59E0B); // moderate risk / warning accent
  static const Color neonRed = Color(0xFFDC2626); // high risk / danger accent
  static const Color accentTeal = Color(0xFF0891B2); // secondary accent for variety

  static const Color textPrimary = Color(0xFF182620); // near-black, headings
  static const Color textSecondary = Color(0xFF6E7D74); // muted sage-grey, secondary text
}

class AppTextStyles {
  static TextStyle heading({double size = 22, Color? color, FontWeight? weight}) {
    return GoogleFonts.spaceGrotesk(
      fontSize: size,
      fontWeight: weight ?? FontWeight.bold,
      letterSpacing: -0.2,
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
      letterSpacing: 1.0,
      color: color ?? AppColors.textSecondary,
    );
  }
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bgDark2,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.neonGreen,
        brightness: Brightness.light,
        primary: AppColors.neonGreen,
        secondary: AppColors.neonAmber,
        error: AppColors.neonRed,
        surface: AppColors.bgDark,
      ),
      textTheme: TextTheme(
        headlineLarge: AppTextStyles.heading(size: 28),
        headlineMedium: AppTextStyles.heading(size: 22),
        titleLarge: AppTextStyles.heading(size: 18),
        bodyLarge: AppTextStyles.body(size: 16),
        bodyMedium: AppTextStyles.body(size: 14),
        labelSmall: AppTextStyles.label(),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.neonGreen,
          foregroundColor: AppColors.bgDark,
          textStyle: AppTextStyles.body(size: 16, weight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          elevation: 1,
          shadowColor: Colors.black.withOpacity(0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0x1F101815), width: 1.3),
          textStyle: AppTextStyles.body(size: 16, weight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  /// The app's screen background - a flat, soft lavender-grey canvas that
  /// lets the white cards read clearly against it via shadow, matching
  /// the reference UI's flat light look (no dark gradient anymore).
  static BoxDecoration get backgroundGradient => const BoxDecoration(
    color: AppColors.bgDark2,
  );
}

/// A clean white elevated card - the signature container style for this
/// app. Solid white surface, a hairline border, and a soft ambient
/// shadow for lift (no backdrop blur - that was for the old dark
/// glassmorphic look; this theme uses plain flat cards instead).
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
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: radius,
        border: Border.all(color: AppColors.glassBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// A flat status pill (e.g. "SEVERE", "1 Active", "Sensor Fed") with a
/// light tinted fill and matching colored text - no glow, just a clean
/// flat badge.
class NeonPill extends StatelessWidget {
  final String text;
  final Color color;

  const NeonPill({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35), width: 1),
      ),
      child: Text(
        text.toUpperCase(),
        style: AppTextStyles.label(size: 10, color: color),
      ),
    );
  }
}

/// Reusable circular gauge (confidence score, risk score, etc.) - a
/// clean flat ring on a light grey track, matching the crisp gauge
/// style in the reference UI (no neon glow).
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
      ..color = Colors.black.withOpacity(0.07)
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
    final valueSweep = sweepAngle * fraction;

    canvas.drawArc(rect, startAngle, sweepAngle, false, trackPaint);
    if (fraction > 0) {
      canvas.drawArc(rect, startAngle, valueSweep, false, valuePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.fraction != fraction || oldDelegate.color != color;
}