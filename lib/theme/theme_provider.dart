import 'package:flutter/foundation.dart';

class ThemeProvider extends ChangeNotifier {
  String appStyle = 'classic';
  double goldIntensity = 1.0;
  bool showPattern = true;
  String headingFont = 'Cormorant Garamond';
  bool showSplash = true;

  void setStyle(String style) {
    if (appStyle == style) {
      return;
    }
    appStyle = style;
    notifyListeners();
  }

  void setGoldIntensity(double val) {
    final value = val.clamp(0.0, 1.0);
    if (goldIntensity == value) {
      return;
    }
    goldIntensity = value;
    notifyListeners();
  }

  void togglePattern() {
    showPattern = !showPattern;
    notifyListeners();
  }

  void setHeadingFont(String font) {
    if (headingFont == font) {
      return;
    }
    headingFont = font;
    notifyListeners();
  }

  void toggleSplash() {
    showSplash = !showSplash;
    notifyListeners();
  }
}
