import 'package:get/get.dart';
import 'package:soul_matcher/app/data/models/app_user.dart';
import 'package:soul_matcher/app/data/repositories/auth_repository.dart';
import 'package:soul_matcher/app/data/repositories/user_repository.dart';
import 'package:soul_matcher/app/routes/app_routes.dart';
import 'package:soul_matcher/app/services/firebase_notification_service.dart';

class SplashController extends GetxController {
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final UserRepository _userRepository = Get.find<UserRepository>();
  final FirebaseNotificationService _notificationService =
      Get.find<FirebaseNotificationService>();

  @override
  void onReady() {
    super.onReady();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final user = _authRepository.currentUser;
    if (user == null) {
      Get.offAllNamed(AppRoutes.auth);
      return;
    }

    await _userRepository.createUserIfNotExists(user);
    await _notificationService.initialize();

    final AppUser? appUser = await _userRepository.getUser(user.uid);
    if (appUser == null || !appUser.onboardingCompleted) {
      Get.offAllNamed(AppRoutes.onboarding);
      return;
    }
    if (!appUser.profileCompleted) {
      Get.offAllNamed(AppRoutes.profileSetup);
      return;
    }
    Get.offAllNamed(AppRoutes.home);
  }
}
