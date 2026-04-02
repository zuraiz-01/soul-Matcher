import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:soul_matcher/app/data/repositories/auth_repository.dart';
import 'package:soul_matcher/app/data/repositories/user_repository.dart';

class ReferralApplyResult {
  const ReferralApplyResult({required this.isSuccess, required this.message});

  final bool isSuccess;
  final String message;
}

class MockPayoutRequestResult {
  const MockPayoutRequestResult({
    required this.isSuccess,
    required this.message,
    this.requestId,
    this.points,
  });

  final bool isSuccess;
  final String message;
  final String? requestId;
  final int? points;
}

class ReferralService extends GetxService {
  ReferralService({
    required AuthRepository authRepository,
    required UserRepository userRepository,
    FirebaseFirestore? firestore,
  }) : _authRepository = authRepository,
       _userRepository = userRepository,
       _firestore = firestore ?? FirebaseFirestore.instance;

  static const int newUserJoinRewardPoints = 50;
  static const int referrerRewardPoints = 100;
  static const int minPayoutPoints = 500;

  final AuthRepository _authRepository;
  final UserRepository _userRepository;
  final FirebaseFirestore _firestore;

  String? get _uid => _authRepository.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _referralRewards =>
      _firestore.collection('referral_rewards');
  CollectionReference<Map<String, dynamic>> get _mockPayoutRequests =>
      _firestore.collection('mock_payout_requests');

  Future<void> ensureReferralProfile() async {
    final String? uid = _uid;
    if (uid == null || uid.isEmpty) return;

    final DocumentReference<Map<String, dynamic>> userRef = _users.doc(uid);
    final DocumentSnapshot<Map<String, dynamic>> snapshot = await userRef.get();
    final Map<String, dynamic> data = snapshot.data() ?? <String, dynamic>{};
    final Map<String, dynamic> patch = <String, dynamic>{};

    final String referralCode = (data['referralCode'] as String? ?? '').trim();
    if (referralCode.isEmpty) {
      patch['referralCode'] = _userRepository.buildReferralCode(uid);
    }

    if (!data.containsKey('referralPoints')) {
      patch['referralPoints'] = 0;
    }
    if (!data.containsKey('totalReferralPointsEarned')) {
      patch['totalReferralPointsEarned'] = 0;
    }
    if (!data.containsKey('totalReferralPayoutPoints')) {
      patch['totalReferralPayoutPoints'] = 0;
    }
    if (!data.containsKey('referredByUid')) {
      patch['referredByUid'] = null;
    }
    if (!data.containsKey('referredByCode')) {
      patch['referredByCode'] = null;
    }

    if (patch.isEmpty) return;
    patch['updatedAt'] = FieldValue.serverTimestamp();
    await userRef.set(patch, SetOptions(merge: true));
  }

  Future<ReferralApplyResult> applyReferralCode(String rawCode) async {
    final String? uid = _uid;
    if (uid == null || uid.isEmpty) {
      return const ReferralApplyResult(
        isSuccess: false,
        message: 'Please login again.',
      );
    }

    final String code = rawCode.trim().toUpperCase();
    if (code.isEmpty) {
      return const ReferralApplyResult(
        isSuccess: false,
        message: 'Referral code required.',
      );
    }

    await ensureReferralProfile();

    final QuerySnapshot<Map<String, dynamic>> referrerQuery = await _users
        .where('referralCode', isEqualTo: code)
        .limit(1)
        .get();
    if (referrerQuery.docs.isEmpty) {
      return const ReferralApplyResult(
        isSuccess: false,
        message: 'Invalid referral code.',
      );
    }

    final String referrerUid = referrerQuery.docs.first.id;
    if (referrerUid == uid) {
      return const ReferralApplyResult(
        isSuccess: false,
        message: 'You cannot use your own referral code.',
      );
    }

    final DocumentReference<Map<String, dynamic>> userRef = _users.doc(uid);
    final DocumentReference<Map<String, dynamic>> referrerRef = _users.doc(
      referrerUid,
    );
    final DocumentReference<Map<String, dynamic>> rewardRef = _referralRewards
        .doc('${uid}_$referrerUid');

    try {
      await _firestore.runTransaction((Transaction transaction) async {
        final DocumentSnapshot<Map<String, dynamic>> userDoc = await transaction
            .get(userRef);
        final Map<String, dynamic> userData =
            userDoc.data() ?? <String, dynamic>{};
        final String referredByUid =
            (userData['referredByUid'] as String? ?? '').trim();
        if (referredByUid.isNotEmpty) {
          throw Exception('Referral already applied on this account.');
        }

        final String ownCode = (userData['referralCode'] as String? ?? '')
            .trim()
            .toUpperCase();
        if (ownCode == code) {
          throw Exception('You cannot use your own referral code.');
        }

        final DocumentSnapshot<Map<String, dynamic>> referrerDoc =
            await transaction.get(referrerRef);
        if (!referrerDoc.exists) {
          throw Exception('Referral owner not found.');
        }

        final String referrerCode =
            (referrerDoc.data()?['referralCode'] as String? ?? '')
                .trim()
                .toUpperCase();
        if (referrerCode != code) {
          throw Exception('Invalid referral code.');
        }

        final DocumentSnapshot<Map<String, dynamic>> rewardDoc =
            await transaction.get(rewardRef);
        if (rewardDoc.exists) {
          throw Exception('Referral already used.');
        }

        transaction.set(userRef, <String, dynamic>{
          'referredByUid': referrerUid,
          'referredByCode': code,
          'referralPoints': FieldValue.increment(newUserJoinRewardPoints),
          'totalReferralPointsEarned': FieldValue.increment(
            newUserJoinRewardPoints,
          ),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        transaction.set(rewardRef, <String, dynamic>{
          'id': rewardRef.id,
          'referrerUid': referrerUid,
          'referredUid': uid,
          'referralCode': code,
          'pointsForReferrer': referrerRewardPoints,
          'claimedByReferrer': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      return ReferralApplyResult(isSuccess: false, message: e.toString());
    }

    return const ReferralApplyResult(
      isSuccess: true,
      message:
          'Referral applied. You earned 50 points. Referrer reward is pending claim.',
    );
  }

  Future<int> claimPendingReferrerRewards() async {
    final String? uid = _uid;
    if (uid == null || uid.isEmpty) return 0;

    await ensureReferralProfile();

    final QuerySnapshot<Map<String, dynamic>> pendingRewards =
        await _referralRewards
            .where('referrerUid', isEqualTo: uid)
            .where('claimedByReferrer', isEqualTo: false)
            .limit(100)
            .get();

    if (pendingRewards.docs.isEmpty) {
      return 0;
    }

    int totalPoints = 0;
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in pendingRewards.docs) {
      final int points =
          (doc.data()['pointsForReferrer'] as num?)?.toInt() ??
          referrerRewardPoints;
      totalPoints += points;
    }

    final WriteBatch batch = _firestore.batch();
    final DocumentReference<Map<String, dynamic>> userRef = _users.doc(uid);
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in pendingRewards.docs) {
      batch.update(doc.reference, <String, dynamic>{
        'claimedByReferrer': true,
        'claimedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    batch.set(userRef, <String, dynamic>{
      'referralPoints': FieldValue.increment(totalPoints),
      'totalReferralPointsEarned': FieldValue.increment(totalPoints),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
    return totalPoints;
  }

  Future<MockPayoutRequestResult> requestMockPayout({int? points}) async {
    final String? uid = _uid;
    if (uid == null || uid.isEmpty) {
      return const MockPayoutRequestResult(
        isSuccess: false,
        message: 'Please login again.',
      );
    }

    await ensureReferralProfile();

    final DocumentReference<Map<String, dynamic>> userRef = _users.doc(uid);
    final DocumentSnapshot<Map<String, dynamic>> userSnapshot = await userRef
        .get();
    final Map<String, dynamic> data =
        userSnapshot.data() ?? <String, dynamic>{};
    final int availablePoints = (data['referralPoints'] as num?)?.toInt() ?? 0;

    if (availablePoints < minPayoutPoints) {
      return MockPayoutRequestResult(
        isSuccess: false,
        message:
            'Minimum $minPayoutPoints points required for payout. You have $availablePoints.',
      );
    }

    final int payoutPoints;
    if (points == null) {
      payoutPoints = availablePoints;
    } else {
      payoutPoints = points.clamp(minPayoutPoints, availablePoints).toInt();
    }

    final DocumentReference<Map<String, dynamic>> payoutRef =
        _mockPayoutRequests.doc();
    final WriteBatch batch = _firestore.batch();

    batch.set(payoutRef, <String, dynamic>{
      'id': payoutRef.id,
      'uid': uid,
      'points': payoutPoints,
      'status': 'pending',
      'method': 'mock_wallet',
      'requestedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.set(userRef, <String, dynamic>{
      'referralPoints': FieldValue.increment(-payoutPoints),
      'totalReferralPayoutPoints': FieldValue.increment(payoutPoints),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();

    return MockPayoutRequestResult(
      isSuccess: true,
      message: 'Mock payout request submitted.',
      requestId: payoutRef.id,
      points: payoutPoints,
    );
  }
}
