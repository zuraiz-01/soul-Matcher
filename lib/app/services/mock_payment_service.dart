import 'package:get/get.dart';
import 'package:soul_matcher/app/core/subscription/subscription_plan.dart';

class MockPaymentResult {
  const MockPaymentResult({
    required this.isSuccess,
    required this.message,
    this.transactionId,
    this.amount,
  });

  final bool isSuccess;
  final String message;
  final String? transactionId;
  final double? amount;
}

class MockPaymentService extends GetxService {
  final RxBool isProcessing = false.obs;

  Future<MockPaymentResult> purchasePlan({
    required SubscriptionPlan plan,
    bool simulateFailure = false,
  }) async {
    if (plan == SubscriptionPlan.free) {
      return const MockPaymentResult(
        isSuccess: false,
        message: 'Free plan does not require payment.',
      );
    }

    if (isProcessing.value) {
      return const MockPaymentResult(
        isSuccess: false,
        message: 'Payment is already in progress. Please wait.',
      );
    }

    isProcessing.value = true;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 1500));

      if (simulateFailure) {
        return const MockPaymentResult(
          isSuccess: false,
          message: 'Mock payment failed. Please try again.',
        );
      }

      final String txId = 'MOCK-${DateTime.now().millisecondsSinceEpoch}';
      final double amount = _price(plan);

      return MockPaymentResult(
        isSuccess: true,
        message: 'Payment successful.',
        transactionId: txId,
        amount: amount,
      );
    } finally {
      isProcessing.value = false;
    }
  }

  double priceForPlan(SubscriptionPlan plan) => _price(plan);

  double _price(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.gold:
        return 9.99;
      case SubscriptionPlan.platinum:
        return 19.99;
      case SubscriptionPlan.free:
        return 0;
    }
  }
}
