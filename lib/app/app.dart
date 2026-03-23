import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soul_matcher/app/bindings/initial_binding.dart';
import 'package:soul_matcher/app/routes/app_pages.dart';
import 'package:soul_matcher/app/routes/app_routes.dart';
import 'package:soul_matcher/app/theme/app_theme.dart';
import 'package:soul_matcher/app/theme/theme_controller.dart';

class SoulMatchApp extends StatelessWidget {
  const SoulMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetX<ThemeController>(
      builder: (themeController) => GetMaterialApp(
        title: 'SoulMatch',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeController.themeMode.value,
        initialBinding: InitialBinding(),
        initialRoute: AppRoutes.splash,
        getPages: AppPages.routes,
        defaultTransition: Transition.cupertino,
      ),
    );
  }
}
