import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ThemeController extends GetxController {
  final Rx<ThemeMode> themeMode = ThemeMode.dark.obs;

  void setThemeMode(ThemeMode mode) {
    if (themeMode.value == mode) return;
    themeMode.value = mode;
    Get.changeThemeMode(mode);
  }

  void toggleTheme() {
    final bool useDark = themeMode.value != ThemeMode.dark;
    setThemeMode(useDark ? ThemeMode.dark : ThemeMode.light);
  }
}
