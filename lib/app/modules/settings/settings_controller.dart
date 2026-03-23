import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soul_matcher/app/data/repositories/auth_repository.dart';
import 'package:soul_matcher/app/data/repositories/user_repository.dart';
import 'package:soul_matcher/app/routes/app_routes.dart';
import 'package:soul_matcher/app/theme/theme_controller.dart';

class SettingsController extends GetxController {
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final UserRepository _userRepository = Get.find<UserRepository>();
  final ThemeController _themeController = Get.find<ThemeController>();

  final RxBool isLoading = false.obs;

  ThemeMode get themeMode => _themeController.themeMode.value;

  void setThemeMode(ThemeMode mode) => _themeController.setThemeMode(mode);

  Future<void> logout() async {
    isLoading.value = true;
    try {
      await _authRepository.signOut();
      Get.offAllNamed(AppRoutes.auth);
    } catch (e) {
      Get.snackbar('Logout failed', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteAccount() async {
    final String? uid = _authRepository.currentUser?.uid;
    if (uid == null) return;
    isLoading.value = true;
    try {
      await _userRepository.deleteUser(uid);
      await _authRepository.deleteCurrentUser();
      Get.offAllNamed(AppRoutes.auth);
    } catch (e) {
      Get.snackbar(
        'Delete failed',
        'Please re-login and try again.\n${e.toString()}',
      );
    } finally {
      isLoading.value = false;
    }
  }
}
