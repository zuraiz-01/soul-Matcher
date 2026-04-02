enum SubscriptionPlan { free, gold, platinum }

SubscriptionPlan subscriptionPlanFromValue(String? rawValue) {
  final String value = (rawValue ?? '').trim().toLowerCase();
  switch (value) {
    case 'gold':
      return SubscriptionPlan.gold;
    case 'platinum':
      return SubscriptionPlan.platinum;
    case 'free':
    default:
      return SubscriptionPlan.free;
  }
}

extension SubscriptionPlanX on SubscriptionPlan {
  String get firestoreValue {
    switch (this) {
      case SubscriptionPlan.free:
        return 'free';
      case SubscriptionPlan.gold:
        return 'gold';
      case SubscriptionPlan.platinum:
        return 'platinum';
    }
  }

  String get label {
    switch (this) {
      case SubscriptionPlan.free:
        return 'Free';
      case SubscriptionPlan.gold:
        return 'Gold';
      case SubscriptionPlan.platinum:
        return 'Platinum';
    }
  }

  String get description {
    switch (this) {
      case SubscriptionPlan.free:
        return 'Start chatting and exploring with limited access.';
      case SubscriptionPlan.gold:
        return 'Chat freely and connect without limits.';
      case SubscriptionPlan.platinum:
        return 'Full access with advanced chat and visibility.';
    }
  }

  int? get dailySwipeLimit {
    switch (this) {
      case SubscriptionPlan.free:
        return 30;
      case SubscriptionPlan.gold:
      case SubscriptionPlan.platinum:
        return null;
    }
  }

  int? get dailySuperLikeLimit {
    switch (this) {
      case SubscriptionPlan.free:
        return 1;
      case SubscriptionPlan.gold:
        return 5;
      case SubscriptionPlan.platinum:
        return null;
    }
  }

  int? get dailyMessageLimit {
    switch (this) {
      case SubscriptionPlan.free:
        return 30;
      case SubscriptionPlan.gold:
      case SubscriptionPlan.platinum:
        return null;
    }
  }

  int? get perMatchMessageLimit {
    switch (this) {
      case SubscriptionPlan.free:
        return 15;
      case SubscriptionPlan.gold:
      case SubscriptionPlan.platinum:
        return null;
    }
  }

  bool get showAds => this == SubscriptionPlan.free;
  bool get canSendImages => this != SubscriptionPlan.free;
  bool get canSendAudio => this == SubscriptionPlan.platinum;
  bool get canSeeReadReceipts => this == SubscriptionPlan.platinum;
  bool get canSeeTypingIndicator => this == SubscriptionPlan.platinum;
  bool get canUseAdvancedFilters => this != SubscriptionPlan.free;

  String get seeWhoLikedYouLevel {
    switch (this) {
      case SubscriptionPlan.free:
        return 'none';
      case SubscriptionPlan.gold:
        return 'partial';
      case SubscriptionPlan.platinum:
        return 'full';
    }
  }

  String get boostAccess {
    switch (this) {
      case SubscriptionPlan.free:
        return 'none';
      case SubscriptionPlan.gold:
        return 'weekly';
      case SubscriptionPlan.platinum:
        return 'daily';
    }
  }
}
