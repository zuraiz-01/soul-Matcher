import 'package:get/get.dart';
import 'package:soul_matcher/app/bindings/activity_binding.dart';
import 'package:soul_matcher/app/bindings/auth_binding.dart';
import 'package:soul_matcher/app/bindings/chat_binding.dart';
import 'package:soul_matcher/app/bindings/home_binding.dart';
import 'package:soul_matcher/app/bindings/onboarding_binding.dart';
import 'package:soul_matcher/app/bindings/profile_binding.dart';
import 'package:soul_matcher/app/bindings/settings_binding.dart';
import 'package:soul_matcher/app/modules/activity/activity_controller.dart';
import 'package:soul_matcher/app/modules/activity/activity_page.dart';
import 'package:soul_matcher/app/modules/auth/auth_page.dart';
import 'package:soul_matcher/app/modules/chat/chat_page.dart';
import 'package:soul_matcher/app/modules/home/home_page.dart';
import 'package:soul_matcher/app/modules/onboarding/onboarding_page.dart';
import 'package:soul_matcher/app/modules/profile/profile_setup_page.dart';
import 'package:soul_matcher/app/modules/settings/settings_page.dart';
import 'package:soul_matcher/app/modules/splash/splash_page.dart';
import 'package:soul_matcher/app/modules/user_profile/user_profile_page.dart';
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
      name: AppRoutes.userProfile,
      page: () => const UserProfilePage(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.settings,
      page: () => const SettingsPage(),
      binding: SettingsBinding(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.likedUsers,
      page: () => const ActivityPage(type: ActivityListType.liked),
      binding: ActivityBinding(type: ActivityListType.liked),
    ),
    GetPage<dynamic>(
      name: AppRoutes.superLikedUsers,
      page: () => const ActivityPage(type: ActivityListType.superLiked),
      binding: ActivityBinding(type: ActivityListType.superLiked),
    ),
    GetPage<dynamic>(
      name: AppRoutes.blockedUsers,
      page: () => const ActivityPage(type: ActivityListType.blocked),
      binding: ActivityBinding(type: ActivityListType.blocked),
    ),
    GetPage<dynamic>(
      name: AppRoutes.reportedUsers,
      page: () => const ActivityPage(type: ActivityListType.reported),
      binding: ActivityBinding(type: ActivityListType.reported),
    ),
  ];
}
