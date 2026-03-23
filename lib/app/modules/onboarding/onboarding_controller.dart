import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:soul_matcher/app/data/models/app_user.dart';
import 'package:soul_matcher/app/data/repositories/auth_repository.dart';
import 'package:soul_matcher/app/data/repositories/user_repository.dart';
import 'package:soul_matcher/app/routes/app_routes.dart';

class OnboardingController extends GetxController {
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final UserRepository _userRepository = Get.find<UserRepository>();

  final PageController pageController = PageController();
  final RxInt pageIndex = 0.obs;
  final RxBool isCompleting = false.obs;

  void onPageChanged(int index) {
    if (pageIndex.value != index) {
      HapticFeedback.selectionClick();
    }
    pageIndex.value = index;
  }

  Future<void> nextOrComplete(int totalPages) async {
    if (isCompleting.value) return;
    if (pageIndex.value >= totalPages - 1) {
      await completeOnboarding();
      return;
    }

    await pageController.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> skipOnboarding() async {
    if (isCompleting.value) return;
    await completeOnboarding();
  }

  Future<void> completeOnboarding() async {
    final String? uid = _authRepository.currentUser?.uid;
    if (uid == null) {
      Get.offAllNamed(AppRoutes.auth);
      return;
    }

    isCompleting.value = true;
    try {
      await _userRepository.markOnboardingComplete(uid);
      final AppUser? appUser = await _userRepository.getUser(uid);
      if (appUser?.profileCompleted == true) {
        Get.offAllNamed(AppRoutes.home);
      } else {
        Get.offAllNamed(AppRoutes.profileSetup);
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isCompleting.value = false;
    }
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
