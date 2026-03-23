import 'package:get/get.dart';
import 'package:soul_matcher/app/modules/onboarding/onboarding_controller.dart';

class OnboardingBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<OnboardingController>()) {
      Get.lazyPut<OnboardingController>(() => OnboardingController());
    }
  }
}
