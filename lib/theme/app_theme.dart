import 'package:flutter/material.dart';

class AppColors {
  // ── Modo oscuro — colores del main.dart original ──────────────────
  static const bg          = Color(0xFF1A1A2E);   // fondo original
  static const surface     = Color(0xFF12121F);   // surface original
  static const surfaceHigh = Color(0xFF1F1F38);
  static const border      = Color(0xFF2A2A4A);
  static const accent      = Color(0xFF00E5CC);   // teal como principal (igual que main.dart)
  static const teal        = Color(0xFF00E5CC);
  static const warn        = Color(0xFFFF5C5C);
  static const gold        = Color(0xFFFFB347);
  static const blue        = Color(0xFF0066FF);   // azul del gradiente del botón TTS
  static const purple      = Color(0xFFBB86FC);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textMid     = Color(0xB3FFFFFF); // white70
  static const textDim     = Color(0xFF9090B0);

  // ── Modo claro — mismos acentos, fondos invertidos ────────────────
  static const bgLight          = Color(0xFFF0F4FF);
  static const surfaceLight     = Color(0xFFFFFFFF);
  static const surfaceHighLight = Color(0xFFE8EEF8);
  static const borderLight      = Color(0xFFCCDDEE);
  static const accentLight      = Color(0xFF00B8A3);  // teal más oscuro para fondo claro
  static const tealLight        = Color(0xFF00B8A3);
  static const warnLight        = Color(0xFFD32F2F);
  static const goldLight        = Color(0xFFE07B00);
  static const blueLight        = Color(0xFF0044CC);
  static const purpleLight      = Color(0xFF7B3FD4);
  static const textPrimaryLight = Color(0xFF1A1A2E);  // invertido del bg oscuro
  static const textMidLight     = Color(0xFF3A3A5C);
  static const textDimLight     = Color(0xFF7070A0);

  // ── Helper: color de categoría ────────────────────────────────────
  static Color catColor(String cat, {bool light = false}) {
    switch (cat) {
      case 'Urgente':     return light ? warnLight   : warn;
      case 'Saludos':     return light ? tealLight   : teal;
      case 'Necesidades': return light ? goldLight   : gold;
      case 'Respuestas':  return light ? blueLight   : blue;
      default:            return light ? purpleLight : purple;
    }
  }

  static Color adaptive(BuildContext context, Color dark, Color light) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }
}

class AppTheme {
  // ── MODO OSCURO ───────────────────────────────────────────────────
  static ThemeData get dark => ThemeData.dark().copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary:   AppColors.teal,
      secondary: AppColors.blue,
      surface:   AppColors.surface,
      error:     AppColors.warn,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: AppColors.teal),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor:   AppColors.teal,
      unselectedItemColor: Color(0x61FFFFFF), // white38
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle:   TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 11),
    ),
    cardColor: AppColors.surface,
    dividerColor: Color(0x1AFFFFFF), // white10
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.surface,
      contentTextStyle: TextStyle(color: AppColors.textPrimary),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.teal, width: 1.8),
        foregroundColor: AppColors.teal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.teal : AppColors.textDim,
      ),
      trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
            ? Color(0x6600E5CC)
            : AppColors.border,
      ),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor:   AppColors.teal,
      inactiveTrackColor: Color(0x1FFFFFFF), // white12
      thumbColor:         AppColors.teal,
      overlayColor:       Color(0x2600E5CC),
      trackHeight: 3,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.teal,
      foregroundColor: AppColors.bg,
    ),
    textTheme: const TextTheme(
      bodyLarge:  TextStyle(color: AppColors.textPrimary),
      bodyMedium: TextStyle(color: AppColors.textPrimary),
      bodySmall:  TextStyle(color: Color(0xB3FFFFFF)), // white70
      labelSmall: TextStyle(color: AppColors.textDim),
    ),
  );

  // ── MODO CLARO ────────────────────────────────────────────────────
  static ThemeData get light => ThemeData.light().copyWith(
    scaffoldBackgroundColor: AppColors.bgLight,
    colorScheme: const ColorScheme.light(
      primary:   AppColors.tealLight,
      secondary: AppColors.blueLight,
      surface:   AppColors.surfaceLight,
      error:     AppColors.warnLight,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bgLight,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimaryLight,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: AppColors.tealLight),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceLight,
      selectedItemColor:   AppColors.tealLight,
      unselectedItemColor: AppColors.textDimLight,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle:   TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 11),
    ),
    cardColor: AppColors.surfaceLight,
    dividerColor: AppColors.borderLight,
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.surfaceLight,
      contentTextStyle: TextStyle(color: AppColors.textPrimaryLight),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.tealLight, width: 1.8),
        foregroundColor: AppColors.tealLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.tealLight : AppColors.textDimLight,
      ),
      trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
            ? Color(0x6600B8A3)
            : AppColors.borderLight,
      ),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor:   AppColors.tealLight,
      inactiveTrackColor: AppColors.borderLight,
      thumbColor:         AppColors.tealLight,
      overlayColor:       Color(0x2600B8A3),
      trackHeight: 3,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.tealLight,
      foregroundColor: AppColors.bgLight,
    ),
    textTheme: const TextTheme(
      bodyLarge:  TextStyle(color: AppColors.textPrimaryLight),
      bodyMedium: TextStyle(color: AppColors.textPrimaryLight),
      bodySmall:  TextStyle(color: AppColors.textMidLight),
      labelSmall: TextStyle(color: AppColors.textDimLight),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// THEME PROVIDER
// ─────────────────────────────────────────────────────────────────────────────
class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.dark;

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  void toggle() {
    _mode = isDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void setDark()  { _mode = ThemeMode.dark;   notifyListeners(); }
  void setLight() { _mode = ThemeMode.light;  notifyListeners(); }
}

// ── Adaptive colors — use as: AppColors.of(context).bg etc. ──────
class AdaptiveColors {
  final bool _d;
  const AdaptiveColors(this._d);
  Color get bg          => _d ? AppColors.bg          : AppColors.bgLight;
  Color get surface     => _d ? AppColors.surface      : AppColors.surfaceLight;
  Color get surfaceHigh => _d ? AppColors.surfaceHigh  : AppColors.surfaceHighLight;
  Color get border      => _d ? AppColors.border       : AppColors.borderLight;
  Color get accent      => _d ? AppColors.accent       : AppColors.accentLight;
  Color get teal        => _d ? AppColors.teal         : AppColors.tealLight;
  Color get warn        => _d ? AppColors.warn         : AppColors.warnLight;
  Color get gold        => _d ? AppColors.gold         : AppColors.goldLight;
  Color get blue        => _d ? AppColors.blue         : AppColors.blueLight;
  Color get purple      => _d ? AppColors.purple       : AppColors.purpleLight;
  Color get textPrimary => _d ? AppColors.textPrimary  : AppColors.textPrimaryLight;
  Color get textMid     => _d ? AppColors.textMid      : AppColors.textMidLight;
  Color get textDim     => _d ? AppColors.textDim      : AppColors.textDimLight;
  static AdaptiveColors of(BuildContext context) =>
      AdaptiveColors(Theme.of(context).brightness == Brightness.dark);
}