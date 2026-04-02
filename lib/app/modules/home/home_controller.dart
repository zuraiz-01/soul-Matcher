import 'dart:async';

import 'package:get/get.dart';
import 'package:soul_matcher/app/core/subscription/subscription_plan.dart';
import 'package:soul_matcher/app/services/subscription_service.dart';

class HomeController extends GetxController {
  final SubscriptionService _subscriptionService =
      Get.find<SubscriptionService>();

  final RxInt selectedIndex = 0.obs;
  final Rx<SubscriptionPlan> currentPlan = SubscriptionPlan.free.obs;

  StreamSubscription<SubscriptionPlan>? _planSubscription;

  bool get shouldShowAds => currentPlan.value.showAds;

  @override
  void onInit() {
    super.onInit();
    _planSubscription = _subscriptionService.watchCurrentPlan().listen((
      SubscriptionPlan plan,
    ) {
      currentPlan.value = plan;
    });
  }

  void changeTab(int index) {
    selectedIndex.value = index;
  }

  @override
  void onClose() {
    _planSubscription?.cancel();
    super.onClose();
  }
}
