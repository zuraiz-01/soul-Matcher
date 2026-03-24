import 'package:get/get.dart';
import 'package:soul_matcher/app/data/repositories/auth_repository.dart';
import 'package:soul_matcher/app/data/repositories/chat_repository.dart';
import 'package:soul_matcher/app/data/repositories/discover_repository.dart';
import 'package:soul_matcher/app/data/repositories/user_repository.dart';
import 'package:soul_matcher/app/modules/splash/splash_controller.dart';
import 'package:soul_matcher/app/services/cloudinary_upload_service.dart';
import 'package:soul_matcher/app/services/firebase_notification_service.dart';
import 'package:soul_matcher/app/services/openrouter_service.dart';
import 'package:soul_matcher/app/theme/theme_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ThemeController>()) {
      Get.put(ThemeController(), permanent: true);
    }

    Get.lazyPut<AuthRepository>(() => AuthRepository(), fenix: true);
    Get.lazyPut<CloudinaryUploadService>(
      () => CloudinaryUploadService(),
      fenix: true,
    );
    Get.lazyPut<UserRepository>(
      () => UserRepository(
        cloudinaryUploadService: Get.find<CloudinaryUploadService>(),
      ),
      fenix: true,
    );
    Get.lazyPut<DiscoverRepository>(() => DiscoverRepository(), fenix: true);
    Get.lazyPut<ChatRepository>(() => ChatRepository(), fenix: true);
    Get.lazyPut<OpenRouterService>(() => OpenRouterService(), fenix: true);
    Get.lazyPut<FirebaseNotificationService>(
      () => FirebaseNotificationService(
        userRepository: Get.find<UserRepository>(),
        authRepository: Get.find<AuthRepository>(),
      ),
      fenix: true,
    );
    Get.put(SplashController(), permanent: true);
  }
}
