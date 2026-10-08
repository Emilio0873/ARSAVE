import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

class ThemeController extends ChangeNotifier {
  static const _themeKey = 'arsave_theme';
  static const _thumbsKey = 'arsave_show_thumbs';

  String themeId = 'night';
  bool showThumbnails = true;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    themeId = prefs.getString(_themeKey) ?? 'night';
    if (themeId != 'light') themeId = 'night';
    showThumbnails = prefs.getBool(_thumbsKey) ?? true;
    AppColors.apply(themeId);
    notifyListeners();
  }

  Future<void> setTheme(String id) async {
    themeId = id == 'light' ? 'light' : 'night';
    AppColors.apply(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, id);
    notifyListeners();
  }

  Future<void> setShowThumbnails(bool value) async {
    showThumbnails = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_thumbsKey, value);
    notifyListeners();
  }
}
