import 'package:get/get.dart';
import 'package:soul_matcher/app/modules/discover/discover_controller.dart';
import 'package:soul_matcher/app/modules/home/home_controller.dart';
import 'package:soul_matcher/app/modules/matches/matches_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<HomeController>()) {
      Get.lazyPut<HomeController>(() => HomeController());
    }
    if (!Get.isRegistered<DiscoverController>()) {
      Get.lazyPut<DiscoverController>(() => DiscoverController());
    }
    if (!Get.isRegistered<MatchesController>()) {
      Get.lazyPut<MatchesController>(() => MatchesController());
    }
  }
}
