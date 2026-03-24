import 'package:get/get.dart';
import 'package:soul_matcher/app/modules/activity/activity_controller.dart';

class ActivityBinding extends Bindings {
  ActivityBinding({required this.type});

  final ActivityListType type;

  @override
  void dependencies() {
    Get.lazyPut<ActivityController>(
      () => ActivityController(type: type),
      tag: type.name,
    );
  }
}
