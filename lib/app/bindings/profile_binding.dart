import 'package:get/get.dart';
import 'package:soul_matcher/app/modules/profile/profile_controller.dart';
import 'package:soul_matcher/app/services/location_search_service.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<LocationSearchService>()) {
      Get.lazyPut<LocationSearchService>(() => LocationSearchService());
    }
    if (!Get.isRegistered<ProfileController>()) {
      Get.lazyPut<ProfileController>(() => ProfileController());
    }
  }
}
