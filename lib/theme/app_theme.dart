import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppThemeStyle { classic, minimal, warm }

class AppTheme {
  static const Color gold = Color(0xFFC9A84C);
  static const Color goldDeep = Color(0xFFA67C32);
  static const Color goldSoft = Color(0xFFFFF8E7);
  static const Color ink = Color(0xFF1A1A1A);
  static const Color inkOnLight = Color(0xFF1A1A1A);
  static const Color inkSoft = Color(0xFF666666);
  static const Color inkFaint = Color(0xFF999999);
  static const Color border = Color(0xFFE5E5E5);
  static const Color bg = Color(0xFFFFFDF5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color tajweedMadd = Color(0xFFC2410C);
  static const Color tajweedQalqala = Color(0xFF1D4ED8);
  static const Color tajweedGunna = Color(0xFF15803D);
  static const Color tajweedIdgham = Color(0xFF7C3AED);

  static const String uiFont = 'System';
  static const String arabicFont = 'Amiri';
  static const String titleFont = 'Cormorant Garamond';

  static const Duration motionFast = Duration(milliseconds: 150);
  static const Duration motion = Duration(milliseconds: 180);
  static const Curve motionCurve = Curves.easeOut;

  static ThemeData theme([AppThemeStyle style = AppThemeStyle.classic]) {
    return getTheme(style.name, 1);
  }

  static AppPalette palette(BuildContext context) {
    return Theme.of(context).extension<AppPalette>() ??
        const AppPalette(
          primary: gold,
          primaryDeep: goldDeep,
          primarySoft: goldSoft,
          background: bg,
          surface: surface,
          ink: ink,
          inkSoft: inkSoft,
          inkFaint: inkFaint,
          border: border,
        );
  }

  static ThemeData getTheme(
    String style,
    double goldIntensity, {
    String headingFont = titleFont,
    bool isDarkMode = false,
  }) {
    final palette = _paletteForName(style, goldIntensity);
    final effectiveBackground = isDarkMode
        ? const Color(0xFF121212)
        : palette.background;
    final effectiveSurface = isDarkMode
        ? const Color(0xFF1E1E1E)
        : palette.surface;
    final effectiveInk = isDarkMode ? const Color(0xFFF5F5F5) : ink;
    final effectiveInkSoft = isDarkMode ? const Color(0xFFB0B0B0) : inkSoft;
    final effectiveInkFaint = isDarkMode ? const Color(0xFF707070) : inkFaint;
    final effectiveBorder = isDarkMode ? const Color(0xFF2A2A2A) : border;

    final colorScheme = isDarkMode
        ? ColorScheme.dark(
            primary: palette.primary,
            onPrimary: Colors.white,
            secondary: palette.primaryDeep,
            onSecondary: Colors.white,
            surface: effectiveSurface,
            onSurface: effectiveInk,
            error: const Color(0xFFFFB4AB),
            onError: const Color(0xFF690005),
          )
        : ColorScheme.light(
            primary: palette.primary,
            onPrimary: Colors.white,
            secondary: palette.primaryDeep,
            onSecondary: Colors.white,
            surface: effectiveSurface,
            onSurface: effectiveInk,
            error: const Color(0xFFB3261E),
            onError: Colors.white,
          );

    final base = ThemeData(
      useMaterial3: true,
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: effectiveBackground,
      fontFamily: null,
    );

    final headingLarge = _headingStyle(
      headingFont,
      TextStyle(
        fontSize: 46,
        height: 1.02,
        fontWeight: FontWeight.w600,
        color: effectiveInk,
      ),
    );
    final headingMedium = _headingStyle(
      headingFont,
      TextStyle(
        fontSize: 34,
        height: 1.08,
        fontWeight: FontWeight.w600,
        color: effectiveInk,
      ),
    );
    final headingSmall = _headingStyle(
      headingFont,
      TextStyle(
        fontSize: 28,
        height: 1.12,
        fontWeight: FontWeight.w600,
        color: effectiveInk,
      ),
    );

    final textTheme = base.textTheme.copyWith(
      displayLarge: headingLarge,
      headlineLarge: headingMedium,
      headlineMedium: headingSmall,
      titleLarge: TextStyle(
        fontSize: 22,
        height: 1.2,
        fontWeight: FontWeight.w700,
        color: effectiveInk,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        height: 1.25,
        fontWeight: FontWeight.w700,
        color: effectiveInk,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: effectiveInk,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.4,
        fontWeight: FontWeight.w400,
        color: effectiveInkSoft,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 1.35,
        fontWeight: FontWeight.w400,
        color: effectiveInkSoft,
      ),
      labelLarge: TextStyle(
        fontSize: 15,
        height: 1.2,
        fontWeight: FontWeight.w700,
        color: effectiveInk,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        height: 1.2,
        fontWeight: FontWeight.w700,
        color: effectiveInkSoft,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        height: 1.2,
        fontWeight: FontWeight.w700,
        color: effectiveInkFaint,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: effectiveInk,
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        backgroundColor: effectiveSurface,
        selectedItemColor: palette.primary,
        unselectedItemColor: effectiveInkFaint,
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: effectiveSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(44, 44),
          tapTargetSize: MaterialTapTargetSize.padded,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.primaryDeep,
          minimumSize: const Size(44, 44),
          tapTargetSize: MaterialTapTargetSize.padded,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      extensions: <ThemeExtension<dynamic>>[
        AppPalette(
          primary: palette.primary,
          primaryDeep: palette.primaryDeep,
          primarySoft: palette.primarySoft,
          background: effectiveBackground,
          surface: effectiveSurface,
          ink: effectiveInk,
          inkSoft: effectiveInkSoft,
          inkFaint: effectiveInkFaint,
          border: effectiveBorder,
        ),
      ],
    );
  }

  static TextStyle arabicText({
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.w400,
    Color color = ink,
    double height = 1.7,
  }) {
    return GoogleFonts.amiri(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  static TextStyle _headingStyle(String headingFont, TextStyle style) {
    return GoogleFonts.getFont(
      headingFont,
      fontSize: style.fontSize,
      height: style.height,
      fontWeight: style.fontWeight,
      color: style.color,
    );
  }

  static _ThemePalette _paletteForName(String style, double goldIntensity) {
    final intensity = goldIntensity.clamp(0.0, 1.0);
    switch (style) {
      case 'minimal':
        return _effectivePalette(
          goldBase: const Color(0xFFB8960C),
          goldDeepBase: const Color(0xFF8E6E28),
          goldSoftBase: const Color(0xFFF7F3E8),
          background: surface,
          surfaceColor: const Color(0xFFF9F9F9),
          intensity: intensity,
        );
      case 'warm':
        return _effectivePalette(
          goldBase: gold,
          goldDeepBase: goldDeep,
          goldSoftBase: const Color(0xFFFFF3DB),
          background: const Color(0xFFFAF6F0),
          surfaceColor: const Color(0xFFFFF8EE),
          intensity: intensity,
        );
      case 'classic':
      default:
        return _effectivePalette(
          goldBase: gold,
          goldDeepBase: goldDeep,
          goldSoftBase: goldSoft,
          background: bg,
          surfaceColor: surface,
          intensity: intensity,
        );
    }
  }

  static _ThemePalette _effectivePalette({
    required Color goldBase,
    required Color goldDeepBase,
    required Color goldSoftBase,
    required Color background,
    required Color surfaceColor,
    required double intensity,
  }) {
    final effectiveGold = goldBase.withValues(alpha: 0.4 + intensity * 0.6);
    return _ThemePalette(
      primary: effectiveGold,
      primaryDeep: Color.lerp(goldDeepBase, effectiveGold, 0.2)!,
      primarySoft: Color.lerp(surfaceColor, goldSoftBase, intensity)!,
      background: background,
      surface: surfaceColor,
    );
  }
}

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.primary,
    required this.primaryDeep,
    required this.primarySoft,
    required this.background,
    required this.surface,
    required this.ink,
    required this.inkSoft,
    required this.inkFaint,
    required this.border,
  });

  final Color primary;
  final Color primaryDeep;
  final Color primarySoft;
  final Color background;
  final Color surface;
  final Color ink;
  final Color inkSoft;
  final Color inkFaint;
  final Color border;

  @override
  AppPalette copyWith({
    Color? primary,
    Color? primaryDeep,
    Color? primarySoft,
    Color? background,
    Color? surface,
    Color? ink,
    Color? inkSoft,
    Color? inkFaint,
    Color? border,
  }) {
    return AppPalette(
      primary: primary ?? this.primary,
      primaryDeep: primaryDeep ?? this.primaryDeep,
      primarySoft: primarySoft ?? this.primarySoft,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      ink: ink ?? this.ink,
      inkSoft: inkSoft ?? this.inkSoft,
      inkFaint: inkFaint ?? this.inkFaint,
      border: border ?? this.border,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) {
      return this;
    }

    return AppPalette(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDeep: Color.lerp(primaryDeep, other.primaryDeep, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkSoft: Color.lerp(inkSoft, other.inkSoft, t)!,
      inkFaint: Color.lerp(inkFaint, other.inkFaint, t)!,
      border: Color.lerp(border, other.border, t)!,
    );
  }
}

class _ThemePalette {
  const _ThemePalette({
    required this.primary,
    required this.primaryDeep,
    required this.primarySoft,
    required this.background,
    required this.surface,
  });

  final Color primary;
  final Color primaryDeep;
  final Color primarySoft;
  final Color background;
  final Color surface;
}
