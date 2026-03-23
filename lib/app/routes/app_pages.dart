import 'package:get/get.dart';
import 'package:soul_matcher/app/bindings/auth_binding.dart';
import 'package:soul_matcher/app/bindings/chat_binding.dart';
import 'package:soul_matcher/app/bindings/home_binding.dart';
import 'package:soul_matcher/app/bindings/onboarding_binding.dart';
import 'package:soul_matcher/app/bindings/profile_binding.dart';
import 'package:soul_matcher/app/bindings/settings_binding.dart';
import 'package:soul_matcher/app/modules/auth/auth_page.dart';
import 'package:soul_matcher/app/modules/auth/phone_auth_page.dart';
import 'package:soul_matcher/app/modules/chat/chat_page.dart';
import 'package:soul_matcher/app/modules/home/home_page.dart';
import 'package:soul_matcher/app/modules/onboarding/onboarding_page.dart';
import 'package:soul_matcher/app/modules/profile/profile_setup_page.dart';
import 'package:soul_matcher/app/modules/settings/settings_page.dart';
import 'package:soul_matcher/app/modules/splash/splash_page.dart';
import 'package:soul_matcher/app/routes/app_routes.dart';

class AppPages {
  AppPages._();

  static final List<GetPage<dynamic>> routes = <GetPage<dynamic>>[
    GetPage<dynamic>(name: AppRoutes.splash, page: () => const SplashPage()),
    GetPage<dynamic>(
      name: AppRoutes.auth,
      page: () => const AuthPage(),
      binding: AuthBinding(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.phoneAuth,
      page: () => const PhoneAuthPage(),
      binding: AuthBinding(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.onboarding,
      page: () => const OnboardingPage(),
      binding: OnboardingBinding(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.profileSetup,
      page: () => const ProfileSetupPage(),
      binding: ProfileBinding(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.profileEdit,
      page: () => const ProfileSetupPage(),
      binding: ProfileBinding(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.home,
      page: () => const HomePage(),
      binding: HomeBinding(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.chat,
      page: () => const ChatPage(),
      binding: ChatBinding(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.settings,
      page: () => const SettingsPage(),
      binding: SettingsBinding(),
    ),
  ];
}
