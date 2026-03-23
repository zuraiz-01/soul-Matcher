import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:soul_matcher/app/core/constants/app_constants.dart';
import 'package:soul_matcher/app/data/models/app_user.dart';
import 'package:soul_matcher/app/data/models/match_model.dart';
import 'package:soul_matcher/app/data/models/swipe_action.dart';

class DiscoverFilter {
  const DiscoverFilter({
    this.searchText = '',
    this.minAge = 18,
    this.maxAge = 60,
    this.interestedIn,
  });

  final String searchText;
  final int minAge;
  final int maxAge;
  final String? interestedIn;

  DiscoverFilter copyWith({
    String? searchText,
    int? minAge,
    int? maxAge,
    String? interestedIn,
  }) {
    return DiscoverFilter(
      searchText: searchText ?? this.searchText,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      interestedIn: interestedIn ?? this.interestedIn,
    );
  }
}

class DiscoverRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _matches =>
      _firestore.collection('matches');
  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection('reports');

  Future<List<AppUser>> getCandidates({
    required AppUser currentUser,
    required DiscoverFilter filter,
  }) async {
    final Set<String> swiped = await _getSwipedUserIds(currentUser.uid);
    final Set<String> blocked = await _getBlockedUserIds(currentUser.uid);

    final QuerySnapshot<Map<String, dynamic>> snapshot = await _users
        .where('profileCompleted', isEqualTo: true)
        .limit(AppConstants.discoverBatchSize * 2)
        .get();

    return snapshot.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
          return AppUser.fromMap(doc.data(), doc.id);
        })
        .where((AppUser user) {
          if (user.uid == currentUser.uid) return false;
          if (swiped.contains(user.uid)) return false;
          if (blocked.contains(user.uid)) return false;
          if (user.age == null) return false;

          final bool ageValid =
              user.age! >= filter.minAge && user.age! <= filter.maxAge;
          if (!ageValid) return false;

          if (filter.interestedIn != null &&
              filter.interestedIn!.isNotEmpty &&
              user.gender != filter.interestedIn) {
            return false;
          }

          if (filter.searchText.trim().isNotEmpty) {
            final String q = filter.searchText.trim().toLowerCase();
            if (!user.displayName.toLowerCase().contains(q)) return false;
          }
          return true;
        })
        .toList();
  }

  Future<void> swipe({required SwipeActionModel action}) {
    return _firestore
        .collection('swipes')
        .doc(action.byUserId)
        .collection('actions')
        .doc(action.targetUserId)
        .set(<String, dynamic>{
          'byUserId': action.byUserId,
          'targetUserId': action.targetUserId,
          'action': action.firestoreValue,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  Future<bool> isMutualLike({
    required String myUid,
    required String targetUid,
  }) async {
    final DocumentSnapshot<Map<String, dynamic>> reverseSwipe = await _firestore
        .collection('swipes')
        .doc(targetUid)
        .collection('actions')
        .doc(myUid)
        .get();
    final String? action = reverseSwipe.data()?['action'] as String?;
    return action == 'like' || action == 'super_like';
  }

  Future<MatchModel> createMatch({
    required String uidA,
    required String uidB,
  }) async {
    final List<String> sorted = <String>[uidA, uidB]..sort();
    final String matchId = '${sorted[0]}_${sorted[1]}';
    final DocumentReference<Map<String, dynamic>> matchRef = _matches.doc(
      matchId,
    );
    final DocumentSnapshot<Map<String, dynamic>> existing = await matchRef
        .get();

    if (!existing.exists) {
      await matchRef.set(<String, dynamic>{
        'users': sorted,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': null,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadCount': <String, int>{uidA: 0, uidB: 0},
      });
    }

    final DocumentSnapshot<Map<String, dynamic>> snapshot = await matchRef
        .get();
    return MatchModel.fromMap(
      snapshot.data() ?? <String, dynamic>{},
      snapshot.id,
    );
  }

  Stream<List<MatchModel>> streamMatches(String uid) {
    return _matches
        .where('users', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> query) {
          return query.docs.map((
            QueryDocumentSnapshot<Map<String, dynamic>> doc,
          ) {
            return MatchModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  Future<void> reportUser({
    required String reporterUid,
    required String reportedUid,
    required String reason,
  }) {
    return _reports.add(<String, dynamic>{
      'reporterUid': reporterUid,
      'reportedUid': reportedUid,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> blockUser({
    required String myUid,
    required String targetUid,
  }) async {
    await _firestore
        .collection('blocks')
        .doc(myUid)
        .collection('blocked')
        .doc(targetUid)
        .set(<String, dynamic>{
          'targetUid': targetUid,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  Future<Set<String>> _getSwipedUserIds(String uid) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('swipes')
        .doc(uid)
        .collection('actions')
        .get();
    return snapshot.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) => doc.id)
        .toSet();
  }

  Future<Set<String>> _getBlockedUserIds(String uid) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('blocks')
        .doc(uid)
        .collection('blocked')
        .get();
    return snapshot.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) => doc.id)
        .toSet();
  }
}
