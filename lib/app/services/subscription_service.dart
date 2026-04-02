import 'package:get/get.dart';
import 'package:soul_matcher/app/core/subscription/subscription_plan.dart';
import 'package:soul_matcher/app/data/models/swipe_action.dart';
import 'package:soul_matcher/app/data/repositories/auth_repository.dart';
import 'package:soul_matcher/app/data/repositories/subscription_repository.dart';

class SubscriptionGateResult {
  const SubscriptionGateResult._({required this.allowed, this.message});

  final bool allowed;
  final String? message;

  factory SubscriptionGateResult.allowed() =>
      const SubscriptionGateResult._(allowed: true);

  factory SubscriptionGateResult.blocked(String message) =>
      SubscriptionGateResult._(allowed: false, message: message);
}

class SubscriptionService extends GetxService {
  SubscriptionService({
    required AuthRepository authRepository,
    required SubscriptionRepository subscriptionRepository,
  }) : _authRepository = authRepository,
       _subscriptionRepository = subscriptionRepository;

  final AuthRepository _authRepository;
  final SubscriptionRepository _subscriptionRepository;

  String? get _uid => _authRepository.currentUser?.uid;

  Future<SubscriptionPlan> getCurrentPlan() async {
    final String? uid = _uid;
    if (uid == null || uid.isEmpty) return SubscriptionPlan.free;
    return _subscriptionRepository.getUserPlan(uid);
  }

  Stream<SubscriptionPlan> watchCurrentPlan() {
    final String? uid = _uid;
    if (uid == null || uid.isEmpty) {
      return Stream<SubscriptionPlan>.value(SubscriptionPlan.free);
    }
    return _subscriptionRepository.streamUserPlan(uid);
  }

  Future<void> switchCurrentPlan(SubscriptionPlan plan) async {
    final String? uid = _uid;
    if (uid == null || uid.isEmpty) {
      throw Exception('Please login again.');
    }
    await _subscriptionRepository.setUserPlan(uid: uid, plan: plan);
  }

  Future<void> cancelCurrentPlan() async {
    final String? uid = _uid;
    if (uid == null || uid.isEmpty) {
      throw Exception('Please login again.');
    }
    await _subscriptionRepository.cancelUserPlan(uid);
  }

  Future<SubscriptionGateResult> reserveSwipeQuota(SwipeType type) async {
    final String? uid = _uid;
    if (uid == null || uid.isEmpty) {
      return SubscriptionGateResult.blocked('Please login again.');
    }

    try {
      final QuotaReservationResult result = await _subscriptionRepository
          .reserveSwipeQuota(uid: uid, type: type);
      return result.allowed
          ? SubscriptionGateResult.allowed()
          : SubscriptionGateResult.blocked(
              result.message ?? 'Plan limit reached.',
            );
    } catch (_) {
      return SubscriptionGateResult.blocked(
        'Could not verify swipe limit. Please try again.',
      );
    }
  }

  Future<void> releaseSwipeQuota(SwipeType type) async {
    final String? uid = _uid;
    if (uid == null || uid.isEmpty) return;
    try {
      await _subscriptionRepository.releaseSwipeQuota(uid: uid, type: type);
    } catch (_) {
      // Best-effort rollback.
    }
  }

  Future<SubscriptionGateResult> reserveMessageQuota({
    required String matchId,
  }) async {
    final String? uid = _uid;
    if (uid == null || uid.isEmpty) {
      return SubscriptionGateResult.blocked('Please login again.');
    }

    try {
      final QuotaReservationResult result = await _subscriptionRepository
          .reserveMessageQuota(uid: uid, matchId: matchId);
      return result.allowed
          ? SubscriptionGateResult.allowed()
          : SubscriptionGateResult.blocked(
              result.message ?? 'Plan limit reached.',
            );
    } catch (_) {
      return SubscriptionGateResult.blocked(
        'Could not verify message limit. Please try again.',
      );
    }
  }

  Future<void> releaseMessageQuota({required String matchId}) async {
    final String? uid = _uid;
    if (uid == null || uid.isEmpty) return;
    try {
      await _subscriptionRepository.releaseMessageQuota(
        uid: uid,
        matchId: matchId,
      );
    } catch (_) {
      // Best-effort rollback.
    }
  }
}
