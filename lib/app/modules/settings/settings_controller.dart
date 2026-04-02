import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:soul_matcher/app/core/subscription/subscription_plan.dart';
import 'package:soul_matcher/app/data/models/app_user.dart';
import 'package:soul_matcher/app/data/repositories/auth_repository.dart';
import 'package:soul_matcher/app/data/repositories/user_repository.dart';
import 'package:soul_matcher/app/routes/app_routes.dart';
import 'package:soul_matcher/app/services/mock_payment_service.dart';
import 'package:soul_matcher/app/services/referral_service.dart';
import 'package:soul_matcher/app/services/subscription_service.dart';
import 'package:soul_matcher/app/theme/theme_controller.dart';

class SettingsController extends GetxController {
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final UserRepository _userRepository = Get.find<UserRepository>();
  final ThemeController _themeController = Get.find<ThemeController>();
  final SubscriptionService _subscriptionService =
      Get.find<SubscriptionService>();
  final MockPaymentService _mockPaymentService = Get.find<MockPaymentService>();
  final ReferralService _referralService = Get.find<ReferralService>();

  final RxBool isLoading = false.obs;
  final Rx<SubscriptionPlan> currentPlan = SubscriptionPlan.free.obs;
  final Rxn<AppUser> currentUser = Rxn<AppUser>();
  final RxBool isReferralLoading = false.obs;
  final TextEditingController referralCodeController = TextEditingController();

  StreamSubscription<SubscriptionPlan>? _planSubscription;
  StreamSubscription<AppUser?>? _userSubscription;

  ThemeMode get themeMode => _themeController.themeMode.value;
  String get referralCode => currentUser.value?.referralCode.trim() ?? '';
  int get referralPoints => currentUser.value?.referralPoints ?? 0;
  bool get hasUsedReferralCode =>
      (currentUser.value?.referredByUid?.trim().isNotEmpty ?? false);
  int get minPayoutPoints => ReferralService.minPayoutPoints;

  @override
  void onInit() {
    super.onInit();
    _planSubscription = _subscriptionService.watchCurrentPlan().listen((
      SubscriptionPlan plan,
    ) {
      currentPlan.value = plan;
    });

    final String? uid = _authRepository.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      _userSubscription = _userRepository.streamUser(uid).listen((
        AppUser? user,
      ) {
        currentUser.value = user;
      });
      _bootstrapReferral();
    }
  }

  void setThemeMode(ThemeMode mode) => _themeController.setThemeMode(mode);

  Future<void> _bootstrapReferral() async {
    try {
      await _referralService.ensureReferralProfile();
      final int claimedPoints = await _referralService
          .claimPendingReferrerRewards();
      if (claimedPoints > 0) {
        Get.snackbar(
          'Referral reward added',
          '+$claimedPoints points added to your wallet.',
        );
      }
    } catch (_) {
      // Silent bootstrap failure; user can retry manually.
    }
  }

  Future<void> copyReferralCode() async {
    if (referralCode.isEmpty) {
      Get.snackbar('Referral code', 'Generating your referral code...');
      return;
    }
    await Clipboard.setData(ClipboardData(text: referralCode));
    Get.snackbar('Copied', 'Referral code copied.');
  }

  Future<void> applyReferralCode() async {
    final String code = referralCodeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      Get.snackbar('Validation', 'Enter a referral code.');
      return;
    }
    if (hasUsedReferralCode) {
      Get.snackbar('Referral used', 'Referral code already applied.');
      return;
    }

    isReferralLoading.value = true;
    try {
      final ReferralApplyResult result = await _referralService
          .applyReferralCode(code);
      if (!result.isSuccess) {
        Get.snackbar('Referral failed', result.message);
        return;
      }

      referralCodeController.clear();
      Get.snackbar('Referral applied', result.message);
    } catch (e) {
      Get.snackbar('Referral failed', e.toString());
    } finally {
      isReferralLoading.value = false;
    }
  }

  Future<void> claimReferralRewards() async {
    isReferralLoading.value = true;
    try {
      final int claimedPoints = await _referralService
          .claimPendingReferrerRewards();
      if (claimedPoints <= 0) {
        Get.snackbar('No rewards', 'No pending referral rewards right now.');
        return;
      }
      Get.snackbar(
        'Rewards claimed',
        '+$claimedPoints points added to your wallet.',
      );
    } catch (e) {
      Get.snackbar('Claim failed', e.toString());
    } finally {
      isReferralLoading.value = false;
    }
  }

  Future<void> requestMockPayout() async {
    isReferralLoading.value = true;
    try {
      final MockPayoutRequestResult result = await _referralService
          .requestMockPayout();
      if (!result.isSuccess) {
        Get.snackbar('Payout failed', result.message);
        return;
      }
      Get.snackbar(
        'Payout requested',
        'Request #${result.requestId} created for ${result.points} points.',
      );
    } catch (e) {
      Get.snackbar('Payout failed', e.toString());
    } finally {
      isReferralLoading.value = false;
    }
  }

  Future<void> switchPlan(SubscriptionPlan plan) async {
    if (!kDebugMode) {
      Get.snackbar(
        'Plan switch locked',
        'Subscription plan can only be changed by billing in release builds.',
      );
      return;
    }

    if (currentPlan.value == plan) {
      Get.snackbar('Plan active', '${plan.label} is already active.');
      return;
    }

    isLoading.value = true;
    try {
      if (plan != SubscriptionPlan.free) {
        final MockPaymentResult paymentResult = await _mockPaymentService
            .purchasePlan(plan: plan);
        if (!paymentResult.isSuccess) {
          Get.snackbar('Payment failed', paymentResult.message);
          return;
        }

        final double paidAmount =
            paymentResult.amount ?? _mockPaymentService.priceForPlan(plan);
        Get.snackbar(
          'Payment successful',
          'Mock paid \$${paidAmount.toStringAsFixed(2)} (Txn: ${paymentResult.transactionId ?? 'N/A'})',
        );
      }

      await _subscriptionService.switchCurrentPlan(plan);
      Get.snackbar('Plan updated', 'Active plan: ${plan.label}');
    } catch (e) {
      Get.snackbar('Plan update failed', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> cancelPlan() async {
    if (currentPlan.value == SubscriptionPlan.free) {
      Get.snackbar('No active plan', 'You are already on Free plan.');
      return;
    }

    if (!kDebugMode) {
      Get.snackbar(
        'Manage subscription',
        'Use billing provider flow to cancel in release builds.',
      );
      return;
    }

    isLoading.value = true;
    try {
      await _subscriptionService.cancelCurrentPlan();
      Get.snackbar('Plan canceled', 'Your account is now on Free plan.');
    } catch (e) {
      Get.snackbar('Cancel failed', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    isLoading.value = true;
    try {
      await _authRepository.signOut();
      Get.offAllNamed(AppRoutes.auth);
    } catch (e) {
      Get.snackbar('Logout failed', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteAccount() async {
    final String? uid = _authRepository.currentUser?.uid;
    if (uid == null) return;
    isLoading.value = true;
    try {
      await _userRepository.deleteUser(uid);
      await _authRepository.deleteCurrentUser();
      Get.offAllNamed(AppRoutes.auth);
    } catch (e) {
      Get.snackbar(
        'Delete failed',
        'Please re-login and try again.\n${e.toString()}',
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _planSubscription?.cancel();
    _userSubscription?.cancel();
    referralCodeController.dispose();
    super.onClose();
  }
}
