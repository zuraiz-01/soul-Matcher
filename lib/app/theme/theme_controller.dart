import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ThemeController extends GetxController {
  final Rx<ThemeMode> themeMode = ThemeMode.system.obs;

  void setThemeMode(ThemeMode mode) {
    themeMode.value = mode;
  }

  void toggleTheme() {
    final bool useDark = themeMode.value != ThemeMode.dark;
    themeMode.value = useDark ? ThemeMode.dark : ThemeMode.light;
  }
}
