import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _appStyleKey = 'appStyle';
  static const _goldIntensityKey = 'goldIntensity';
  static const _showPatternKey = 'showPattern';
  static const _headingFontKey = 'headingFont';
  static const _showSplashKey = 'showSplash';
  static const _isDarkModeKey = 'isDarkMode';
  static const _notificationsEnabledKey = 'notificationsEnabled';

  String appStyle = 'classic';
  double goldIntensity = 1.0;
  bool showPattern = true;
  String headingFont = 'Cormorant Garamond';
  bool showSplash = true;
  bool isDarkMode = false;
  bool notificationsEnabled = true;

  ThemeProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    appStyle = prefs.getString(_appStyleKey) ?? appStyle;
    goldIntensity = prefs.getDouble(_goldIntensityKey) ?? goldIntensity;
    showPattern = prefs.getBool(_showPatternKey) ?? showPattern;
    headingFont = prefs.getString(_headingFontKey) ?? headingFont;
    showSplash = prefs.getBool(_showSplashKey) ?? showSplash;
    isDarkMode = prefs.getBool(_isDarkModeKey) ?? isDarkMode;
    notificationsEnabled =
        prefs.getBool(_notificationsEnabledKey) ?? notificationsEnabled;
    notifyListeners();
  }

  Future<void> setStyle(String style) async {
    if (appStyle == style) {
      return;
    }
    appStyle = style;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_appStyleKey, style);
  }

  Future<void> setGoldIntensity(double val) async {
    final value = val.clamp(0.0, 1.0);
    if (goldIntensity == value) {
      return;
    }
    goldIntensity = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_goldIntensityKey, value);
  }

  Future<void> togglePattern() async {
    showPattern = !showPattern;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showPatternKey, showPattern);
  }

  Future<void> setHeadingFont(String font) async {
    if (headingFont == font) {
      return;
    }
    headingFont = font;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_headingFontKey, font);
  }

  Future<void> toggleSplash() async {
    showSplash = !showSplash;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showSplashKey, showSplash);
  }

  Future<void> setDarkMode(bool value) async {
    if (isDarkMode == value) {
      return;
    }
    isDarkMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isDarkModeKey, value);
  }

  Future<void> setNotificationsEnabled(bool value) async {
    if (notificationsEnabled == value) {
      return;
    }
    notificationsEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, value);
  }
}
