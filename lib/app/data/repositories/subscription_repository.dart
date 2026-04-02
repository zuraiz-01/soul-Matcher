import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:soul_matcher/app/core/subscription/subscription_plan.dart';
import 'package:soul_matcher/app/data/models/daily_usage.dart';
import 'package:soul_matcher/app/data/models/swipe_action.dart';

class QuotaReservationResult {
  const QuotaReservationResult._({required this.allowed, this.message});

  final bool allowed;
  final String? message;

  factory QuotaReservationResult.allowed() =>
      const QuotaReservationResult._(allowed: true);

  factory QuotaReservationResult.blocked(String message) =>
      QuotaReservationResult._(allowed: false, message: message);
}

class SubscriptionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  DocumentReference<Map<String, dynamic>> _dailyUsageDoc({
    required String uid,
    required DateTime now,
  }) {
    final String dateKey = _dayKey(now);
    return _users.doc(uid).collection('dailyUsage').doc(dateKey);
  }

  String _dayKey(DateTime date) {
    final String year = date.year.toString().padLeft(4, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '$year$month$day';
  }

  Future<SubscriptionPlan> getUserPlan(String uid) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot = await _users
        .doc(uid)
        .get();
    final String? rawPlan = snapshot.data()?['subscriptionPlan'] as String?;
    return subscriptionPlanFromValue(rawPlan);
  }

  Stream<SubscriptionPlan> streamUserPlan(String uid) {
    return _users.doc(uid).snapshots().map((
      DocumentSnapshot<Map<String, dynamic>> snapshot,
    ) {
      final String? rawPlan = snapshot.data()?['subscriptionPlan'] as String?;
      return subscriptionPlanFromValue(rawPlan);
    });
  }

  Future<void> setUserPlan({
    required String uid,
    required SubscriptionPlan plan,
  }) {
    return _users.doc(uid).set(<String, dynamic>{
      'subscriptionPlan': plan.firestoreValue,
      'subscriptionStatus': plan == SubscriptionPlan.free
          ? 'inactive'
          : 'active',
      'subscriptionCanceledAt': plan == SubscriptionPlan.free
          ? FieldValue.serverTimestamp()
          : FieldValue.delete(),
      'subscriptionUpdatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> cancelUserPlan(String uid) {
    return _users.doc(uid).set(<String, dynamic>{
      'subscriptionPlan': SubscriptionPlan.free.firestoreValue,
      'subscriptionStatus': 'canceled',
      'subscriptionCanceledAt': FieldValue.serverTimestamp(),
      'subscriptionUpdatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<DailyUsage> getTodayUsage(String uid, {DateTime? now}) async {
    final DateTime today = (now ?? DateTime.now()).toLocal();
    final DocumentReference<Map<String, dynamic>> usageRef = _dailyUsageDoc(
      uid: uid,
      now: today,
    );
    final DocumentSnapshot<Map<String, dynamic>> snapshot = await usageRef
        .get();
    final Map<String, dynamic> data = snapshot.data() ?? <String, dynamic>{};

    return DailyUsage.fromMap(dateKey: _dayKey(today), map: data);
  }

  Future<int> getTodayMatchMessageCount({
    required String uid,
    required String matchId,
    DateTime? now,
  }) async {
    final DateTime today = (now ?? DateTime.now()).toLocal();
    final DocumentReference<Map<String, dynamic>> matchUsageRef =
        _dailyUsageDoc(uid: uid, now: today).collection('matches').doc(matchId);
    final DocumentSnapshot<Map<String, dynamic>> snapshot = await matchUsageRef
        .get();
    return (snapshot.data()?['messagesCount'] as num?)?.toInt() ?? 0;
  }

  Future<QuotaReservationResult> reserveSwipeQuota({
    required String uid,
    required SwipeType type,
    DateTime? now,
  }) {
    final DateTime today = (now ?? DateTime.now()).toLocal();
    final DocumentReference<Map<String, dynamic>> userRef = _users.doc(uid);
    final DocumentReference<Map<String, dynamic>> usageRef = _dailyUsageDoc(
      uid: uid,
      now: today,
    );

    return _firestore.runTransaction<QuotaReservationResult>((
      Transaction transaction,
    ) async {
      final DocumentSnapshot<Map<String, dynamic>> userSnapshot =
          await transaction.get(userRef);
      final String? rawPlan =
          userSnapshot.data()?['subscriptionPlan'] as String?;
      final SubscriptionPlan plan = subscriptionPlanFromValue(rawPlan);

      final int? swipeLimit = plan.dailySwipeLimit;
      final int? superLikeLimit = plan.dailySuperLikeLimit;
      if (swipeLimit == null && superLikeLimit == null) {
        return QuotaReservationResult.allowed();
      }

      final DocumentSnapshot<Map<String, dynamic>> usageSnapshot =
          await transaction.get(usageRef);
      final Map<String, dynamic> current =
          usageSnapshot.data() ?? <String, dynamic>{};
      final int swipes = (current['swipesCount'] as num?)?.toInt() ?? 0;
      final int superLikes = (current['superLikesCount'] as num?)?.toInt() ?? 0;
      final int messages = (current['messagesCount'] as num?)?.toInt() ?? 0;

      if (swipeLimit != null && swipes >= swipeLimit) {
        return QuotaReservationResult.blocked(
          'Daily swipe limit reached ($swipeLimit). Upgrade to continue swiping.',
        );
      }

      if (type == SwipeType.superLike &&
          superLikeLimit != null &&
          superLikes >= superLikeLimit) {
        return QuotaReservationResult.blocked(
          'Daily super likes limit reached ($superLikeLimit). Upgrade for more super likes.',
        );
      }

      transaction.set(usageRef, <String, dynamic>{
        'dateKey': _dayKey(today),
        'swipesCount': swipes + 1,
        'superLikesCount': type == SwipeType.superLike
            ? superLikes + 1
            : superLikes,
        'messagesCount': messages,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return QuotaReservationResult.allowed();
    });
  }

  Future<void> releaseSwipeQuota({
    required String uid,
    required SwipeType type,
    DateTime? now,
  }) async {
    final DateTime today = (now ?? DateTime.now()).toLocal();
    final DocumentReference<Map<String, dynamic>> usageRef = _dailyUsageDoc(
      uid: uid,
      now: today,
    );

    await _firestore.runTransaction((Transaction transaction) async {
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await transaction
          .get(usageRef);
      final Map<String, dynamic> current =
          snapshot.data() ?? <String, dynamic>{};
      final int swipes = (current['swipesCount'] as num?)?.toInt() ?? 0;
      final int superLikes = (current['superLikesCount'] as num?)?.toInt() ?? 0;
      final int messages = (current['messagesCount'] as num?)?.toInt() ?? 0;

      transaction.set(usageRef, <String, dynamic>{
        'dateKey': _dayKey(today),
        'swipesCount': swipes > 0 ? swipes - 1 : 0,
        'superLikesCount': type == SwipeType.superLike
            ? (superLikes > 0 ? superLikes - 1 : 0)
            : superLikes,
        'messagesCount': messages,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<QuotaReservationResult> reserveMessageQuota({
    required String uid,
    required String matchId,
    DateTime? now,
  }) {
    final DateTime today = (now ?? DateTime.now()).toLocal();
    final DocumentReference<Map<String, dynamic>> userRef = _users.doc(uid);
    final DocumentReference<Map<String, dynamic>> usageRef = _dailyUsageDoc(
      uid: uid,
      now: today,
    );
    final DocumentReference<Map<String, dynamic>> matchUsageRef = usageRef
        .collection('matches')
        .doc(matchId);

    return _firestore.runTransaction<QuotaReservationResult>((
      Transaction transaction,
    ) async {
      final DocumentSnapshot<Map<String, dynamic>> userSnapshot =
          await transaction.get(userRef);
      final String? rawPlan =
          userSnapshot.data()?['subscriptionPlan'] as String?;
      final SubscriptionPlan plan = subscriptionPlanFromValue(rawPlan);

      final int? dailyLimit = plan.dailyMessageLimit;
      final int? perMatchLimit = plan.perMatchMessageLimit;
      if (dailyLimit == null && perMatchLimit == null) {
        return QuotaReservationResult.allowed();
      }

      final DocumentSnapshot<Map<String, dynamic>> usageSnapshot =
          await transaction.get(usageRef);
      final DocumentSnapshot<Map<String, dynamic>> matchUsageSnapshot =
          await transaction.get(matchUsageRef);

      final Map<String, dynamic> usageCurrent =
          usageSnapshot.data() ?? <String, dynamic>{};
      final int currentMessages =
          (usageCurrent['messagesCount'] as num?)?.toInt() ?? 0;
      final int currentSwipes =
          (usageCurrent['swipesCount'] as num?)?.toInt() ?? 0;
      final int currentSuperLikes =
          (usageCurrent['superLikesCount'] as num?)?.toInt() ?? 0;
      final int currentMatchMessages =
          (matchUsageSnapshot.data()?['messagesCount'] as num?)?.toInt() ?? 0;

      if (dailyLimit != null && currentMessages >= dailyLimit) {
        return QuotaReservationResult.blocked(
          'Daily message limit reached ($dailyLimit). Upgrade to keep chatting.',
        );
      }

      if (perMatchLimit != null && currentMatchMessages >= perMatchLimit) {
        return QuotaReservationResult.blocked(
          'Per-match message limit reached ($perMatchLimit today). Upgrade to continue this chat.',
        );
      }

      transaction.set(usageRef, <String, dynamic>{
        'dateKey': _dayKey(today),
        'messagesCount': currentMessages + 1,
        'swipesCount': currentSwipes,
        'superLikesCount': currentSuperLikes,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      transaction.set(matchUsageRef, <String, dynamic>{
        'matchId': matchId,
        'dateKey': _dayKey(today),
        'messagesCount': currentMatchMessages + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return QuotaReservationResult.allowed();
    });
  }

  Future<void> releaseMessageQuota({
    required String uid,
    required String matchId,
    DateTime? now,
  }) async {
    final DateTime today = (now ?? DateTime.now()).toLocal();
    final DocumentReference<Map<String, dynamic>> usageRef = _dailyUsageDoc(
      uid: uid,
      now: today,
    );
    final DocumentReference<Map<String, dynamic>> matchUsageRef = usageRef
        .collection('matches')
        .doc(matchId);

    await _firestore.runTransaction((Transaction transaction) async {
      final DocumentSnapshot<Map<String, dynamic>> usageSnapshot =
          await transaction.get(usageRef);
      final DocumentSnapshot<Map<String, dynamic>> matchUsageSnapshot =
          await transaction.get(matchUsageRef);

      final Map<String, dynamic> usageCurrent =
          usageSnapshot.data() ?? <String, dynamic>{};
      final int currentMessages =
          (usageCurrent['messagesCount'] as num?)?.toInt() ?? 0;
      final int currentSwipes =
          (usageCurrent['swipesCount'] as num?)?.toInt() ?? 0;
      final int currentSuperLikes =
          (usageCurrent['superLikesCount'] as num?)?.toInt() ?? 0;
      final int currentMatchMessages =
          (matchUsageSnapshot.data()?['messagesCount'] as num?)?.toInt() ?? 0;

      transaction.set(usageRef, <String, dynamic>{
        'dateKey': _dayKey(today),
        'messagesCount': currentMessages > 0 ? currentMessages - 1 : 0,
        'swipesCount': currentSwipes,
        'superLikesCount': currentSuperLikes,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      transaction.set(matchUsageRef, <String, dynamic>{
        'matchId': matchId,
        'dateKey': _dayKey(today),
        'messagesCount': currentMatchMessages > 0
            ? currentMatchMessages - 1
            : 0,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }
}
