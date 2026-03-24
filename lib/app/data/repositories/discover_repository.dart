import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:soul_matcher/app/core/constants/app_constants.dart';
import 'package:soul_matcher/app/data/models/app_user.dart';
import 'package:soul_matcher/app/data/models/match_model.dart';
import 'package:soul_matcher/app/data/models/swipe_action.dart';
import 'package:soul_matcher/app/data/models/user_activity_item.dart';

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
  CollectionReference<Map<String, dynamic>> _swipeActions(String uid) =>
      _firestore.collection('swipes').doc(uid).collection('actions');
  CollectionReference<Map<String, dynamic>> _blockedUsers(String uid) =>
      _firestore.collection('blocks').doc(uid).collection('blocked');

  Future<List<AppUser>> getCandidates({
    required AppUser currentUser,
    required DiscoverFilter filter,
    bool includePreviouslySwiped = false,
  }) async {
    final Set<String> swiped = includePreviouslySwiped
        ? <String>{}
        : await _getSwipedUserIds(currentUser.uid);
    final Set<String> blocked = await _getBlockedUserIds(currentUser.uid);
    final Set<String> reported = await _getReportedUserIds(currentUser.uid);

    List<AppUser> firestoreUsers = const <AppUser>[];
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _users
          .where('profileCompleted', isEqualTo: true)
          .limit(AppConstants.discoverBatchSize * 2)
          .get();

      firestoreUsers = snapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
            return AppUser.fromMap(doc.data(), doc.id);
          })
          .toList(growable: false);
    } on FirebaseException catch (e) {
      if (!_isPermissionDenied(e)) rethrow;
      // Fall back to local demo users when Firestore permissions are not yet
      // deployed/configured for discover reads.
      firestoreUsers = const <AppUser>[];
    }

    final List<AppUser> combined = <AppUser>[...firestoreUsers, ..._demoUsers];

    return combined
        .where((AppUser user) {
          if (user.uid == currentUser.uid) return false;
          if (swiped.contains(user.uid)) return false;
          if (blocked.contains(user.uid)) return false;
          if (reported.contains(user.uid)) return false;
          if (user.age == null) return false;

          final bool ageValid =
              user.age! >= filter.minAge && user.age! <= filter.maxAge;
          if (!ageValid) return false;

          if (filter.interestedIn != null &&
              filter.interestedIn!.trim().isNotEmpty &&
              !_isSameGender(user.gender, filter.interestedIn)) {
            return false;
          }

          // Show profiles that are likely compatible with current user.
          if (!_isPotentiallyInterestedInMe(
            candidateInterestedIn: user.interestedIn,
            myGender: currentUser.gender,
          )) {
            return false;
          }

          if (filter.searchText.trim().isNotEmpty) {
            final String q = filter.searchText.trim().toLowerCase();
            if (!user.displayName.toLowerCase().contains(q)) return false;
          }
          return true;
        })
        .take(AppConstants.discoverBatchSize)
        .toList(growable: false);
  }

  AppUser? getDemoUserById(String uid) {
    for (final AppUser user in _demoUsers) {
      if (user.uid == uid) {
        return user;
      }
    }
    return null;
  }

  bool _isPotentiallyInterestedInMe({
    required String? candidateInterestedIn,
    required String? myGender,
  }) {
    final String? normalizedCandidateInterest = _normalizeGender(
      candidateInterestedIn,
    );
    final String? normalizedMyGender = _normalizeGender(myGender);

    // If either side is missing/unknown, don't block the profile.
    if (normalizedCandidateInterest == null || normalizedMyGender == null) {
      return true;
    }

    return normalizedCandidateInterest == normalizedMyGender;
  }

  bool _isSameGender(String? a, String? b) {
    final String? first = _normalizeGender(a);
    final String? second = _normalizeGender(b);
    return first != null && second != null && first == second;
  }

  String? _normalizeGender(String? value) {
    if (value == null) return null;
    final String cleaned = value.trim().toLowerCase();
    if (cleaned.isEmpty) return null;

    if (cleaned == 'man' || cleaned == 'male' || cleaned == 'boy') {
      return 'man';
    }
    if (cleaned == 'woman' || cleaned == 'female' || cleaned == 'girl') {
      return 'woman';
    }
    if (cleaned == 'non-binary' || cleaned == 'nonbinary' || cleaned == 'nb') {
      return 'non-binary';
    }
    return cleaned;
  }

  Future<void> swipe({required SwipeActionModel action}) {
    return _swipeActions(
      action.byUserId,
    ).doc(action.targetUserId).set(<String, dynamic>{
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
    if (_isDemoUserUid(targetUid)) {
      // Demo profiles auto-like back to keep the app flow testable.
      return true;
    }

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

    // Do not read before create: a non-existing doc can be denied by rules.
    await matchRef.set(<String, dynamic>{
      'users': sorted,
      'createdAt': FieldValue.serverTimestamp(),
      'unreadCount': <String, int>{uidA: 0, uidB: 0},
    }, SetOptions(merge: true));

    return MatchModel(
      id: matchId,
      users: sorted,
      unreadCount: <String, int>{uidA: 0, uidB: 0},
    );
  }

  Stream<List<MatchModel>> streamMatches(String uid) {
    return _matches.where('users', arrayContains: uid).snapshots().map((
      QuerySnapshot<Map<String, dynamic>> query,
    ) {
      final List<MatchModel> matches = query.docs.map((
        QueryDocumentSnapshot<Map<String, dynamic>> doc,
      ) {
        return MatchModel.fromMap(doc.data(), doc.id);
      }).toList();

      matches.sort((MatchModel a, MatchModel b) {
        final DateTime aTime =
            a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final DateTime bTime =
            b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return matches;
    });
  }

  Future<void> reportUser({
    required String reporterUid,
    required String reportedUid,
    required String reason,
  }) async {
    final String trimmedReason = reason.trim();

    Future<void> saveToReporterProfileOnly() {
      return _users.doc(reporterUid).set(<String, dynamic>{
        'reportedUsers.$reportedUid': <String, dynamic>{
          'reason': trimmedReason,
          'createdAt': FieldValue.serverTimestamp(),
        },
        'dismissedReportedUsers.$reportedUid': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    final WriteBatch batch = _firestore.batch();
    final DocumentReference<Map<String, dynamic>> reportRef = _reports.doc();
    final DocumentReference<Map<String, dynamic>> reporterRef = _users.doc(
      reporterUid,
    );

    batch.set(reportRef, <String, dynamic>{
      'reporterUid': reporterUid,
      'reportedUid': reportedUid,
      'reason': trimmedReason,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Keep a per-user report history to make "Reported Users" page reliable
    // even when top-level reports query permissions are restricted.
    batch.set(reporterRef, <String, dynamic>{
      'reportedUsers.$reportedUid': <String, dynamic>{
        'reason': trimmedReason,
        'createdAt': FieldValue.serverTimestamp(),
      },
      'dismissedReportedUsers.$reportedUid': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    try {
      await batch.commit();
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') {
        rethrow;
      }
      // Graceful fallback when reports collection access is restricted.
      await saveToReporterProfileOnly();
    }
  }

  Future<void> blockUser({
    required String myUid,
    required String targetUid,
  }) async {
    await _blockedUsers(myUid).doc(targetUid).set(<String, dynamic>{
      'targetUid': targetUid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeSwipeAction({
    required String myUid,
    required String targetUid,
  }) {
    return _swipeActions(myUid).doc(targetUid).delete();
  }

  Future<bool> removeSwipeActionAndDeleteConversation({
    required String myUid,
    required String targetUid,
  }) async {
    await removeSwipeAction(myUid: myUid, targetUid: targetUid);
    return deleteMatchAndMessages(uidA: myUid, uidB: targetUid);
  }

  Future<bool> deleteMatchAndMessages({
    required String uidA,
    required String uidB,
  }) async {
    final String matchId = _buildMatchId(uidA, uidB);
    final DocumentReference<Map<String, dynamic>> matchRef = _matches.doc(
      matchId,
    );

    try {
      while (true) {
        final QuerySnapshot<Map<String, dynamic>> snapshot = await matchRef
            .collection('messages')
            .limit(200)
            .get();
        if (snapshot.docs.isEmpty) break;

        final WriteBatch batch = _firestore.batch();
        for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
            in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      await matchRef.delete();
      return true;
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') return true;
      if (_isPermissionDenied(e)) return false;
      rethrow;
    }
  }

  Future<void> unblockUser({required String myUid, required String targetUid}) {
    return _blockedUsers(myUid).doc(targetUid).delete();
  }

  Future<void> dismissReportedUser({
    required String reporterUid,
    required String reportedUid,
  }) {
    return _users.doc(reporterUid).set(<String, dynamic>{
      'reportedUsers.$reportedUid': FieldValue.delete(),
      'dismissedReportedUsers.$reportedUid': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<UserActivityItem>> getLikedUsers(String uid) {
    return _getSwipeUsersByAction(uid: uid, action: 'like');
  }

  Future<List<UserActivityItem>> getSuperLikedUsers(String uid) {
    return _getSwipeUsersByAction(uid: uid, action: 'super_like');
  }

  Future<List<UserActivityItem>> getBlockedUsers(String uid) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _blockedUsers(
      uid,
    ).get();
    final List<UserActivityItem> items = snapshot.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
          final Map<String, dynamic> data = doc.data();
          return UserActivityItem(
            targetUserId: (data['targetUid'] as String?) ?? doc.id,
            createdAt: _parseTimestamp(data['createdAt']),
          );
        })
        .toList(growable: false);
    _sortByCreatedAtDesc(items);
    return items;
  }

  Future<List<UserActivityItem>> getReportedUsers(String uid) async {
    final DocumentSnapshot<Map<String, dynamic>> userDoc = await _users
        .doc(uid)
        .get();
    final Map<String, dynamic>? userData = userDoc.data();
    final Set<String> dismissedReportedUsers = _parseDismissedReportedUsers(
      userData?['dismissedReportedUsers'],
    );

    final List<UserActivityItem> combined = <UserActivityItem>[
      ..._getReportedUsersFromProfileMap(userData?['reportedUsers']),
    ];

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _reports
          .where('reporterUid', isEqualTo: uid)
          .get();

      combined.addAll(
        snapshot.docs
            .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
              final Map<String, dynamic> data = doc.data();
              return UserActivityItem(
                targetUserId: (data['reportedUid'] as String?) ?? '',
                reason: (data['reason'] as String?)?.trim(),
                createdAt: _parseTimestamp(data['createdAt']),
              );
            })
            .where((UserActivityItem item) => item.targetUserId.isNotEmpty),
      );
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') {
        rethrow;
      }
      // If reports collection read is blocked by rules, profile-backed
      // history still keeps this feature usable.
    }

    final List<UserActivityItem> merged = _mergeUniqueActivityItems(combined);
    return merged
        .where(
          (UserActivityItem item) =>
              !dismissedReportedUsers.contains(item.targetUserId),
        )
        .toList(growable: false);
  }

  Future<Set<String>> _getSwipedUserIds(String uid) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _swipeActions(
        uid,
      ).get();
      return snapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) => doc.id)
          .toSet();
    } on FirebaseException catch (e) {
      if (_isPermissionDenied(e)) {
        return <String>{};
      }
      rethrow;
    }
  }

  Future<Set<String>> _getBlockedUserIds(String uid) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _blockedUsers(
        uid,
      ).get();
      return snapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) => doc.id)
          .toSet();
    } on FirebaseException catch (e) {
      if (_isPermissionDenied(e)) {
        return <String>{};
      }
      rethrow;
    }
  }

  Future<Set<String>> _getReportedUserIds(String uid) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> doc = await _users
          .doc(uid)
          .get();
      final Map<String, dynamic>? data = doc.data();
      final dynamic rawReportedUsers = data?['reportedUsers'];
      if (rawReportedUsers is! Map) {
        return <String>{};
      }

      return rawReportedUsers.keys
          .map((dynamic key) => key.toString())
          .where((String id) => id.trim().isNotEmpty)
          .toSet();
    } on FirebaseException catch (e) {
      if (_isPermissionDenied(e)) {
        return <String>{};
      }
      rethrow;
    }
  }

  Future<List<UserActivityItem>> _getSwipeUsersByAction({
    required String uid,
    required String action,
  }) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _swipeActions(
      uid,
    ).where('action', isEqualTo: action).get();
    final List<UserActivityItem> items = snapshot.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
          final Map<String, dynamic> data = doc.data();
          return UserActivityItem(
            targetUserId: (data['targetUserId'] as String?) ?? doc.id,
            createdAt: _parseTimestamp(data['createdAt']),
          );
        })
        .toList(growable: false);
    _sortByCreatedAtDesc(items);
    return items;
  }

  Future<List<String>> getMutualLikeUserIds(String myUid) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _swipeActions(
        myUid,
      ).get();

      final List<String> likedTargets = snapshot.docs
          .where((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
            final String action = (doc.data()['action'] as String?) ?? '';
            return action == 'like' || action == 'super_like';
          })
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) => doc.id)
          .toList(growable: false);

      final List<String> mutual = <String>[];
      for (final String targetUid in likedTargets) {
        try {
          final bool isMutual = await isMutualLike(
            myUid: myUid,
            targetUid: targetUid,
          );
          if (isMutual) {
            mutual.add(targetUid);
          }
        } catch (_) {
          // Skip broken/inaccessible records and continue.
        }
      }
      return mutual;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return const <String>[];
      }
      rethrow;
    }
  }

  DateTime? _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return null;
  }

  void _sortByCreatedAtDesc(List<UserActivityItem> items) {
    items.sort((UserActivityItem a, UserActivityItem b) {
      final DateTime aTime =
          a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime bTime =
          b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
  }

  List<UserActivityItem> _getReportedUsersFromProfileMap(
    dynamic rawReportedUsers,
  ) {
    if (rawReportedUsers is! Map) {
      return const <UserActivityItem>[];
    }

    final List<UserActivityItem> items = <UserActivityItem>[];
    rawReportedUsers.forEach((dynamic key, dynamic value) {
      final String targetUid = key?.toString() ?? '';
      if (targetUid.isEmpty) return;

      if (value is Map) {
        final Map<String, dynamic> reportData = value.map(
          (dynamic k, dynamic v) => MapEntry(k.toString(), v),
        );
        items.add(
          UserActivityItem(
            targetUserId: targetUid,
            reason: (reportData['reason'] as String?)?.trim(),
            createdAt: _parseTimestamp(reportData['createdAt']),
          ),
        );
        return;
      }

      items.add(UserActivityItem(targetUserId: targetUid));
    });
    _sortByCreatedAtDesc(items);
    return items;
  }

  Set<String> _parseDismissedReportedUsers(dynamic rawDismissedUsers) {
    if (rawDismissedUsers is! Map) {
      return <String>{};
    }

    final Set<String> dismissed = <String>{};
    rawDismissedUsers.forEach((dynamic key, dynamic value) {
      if (value == true) {
        final String uid = key?.toString() ?? '';
        if (uid.isNotEmpty) {
          dismissed.add(uid);
        }
      }
    });
    return dismissed;
  }

  List<UserActivityItem> _mergeUniqueActivityItems(List<UserActivityItem> raw) {
    final Map<String, UserActivityItem> merged = <String, UserActivityItem>{};

    for (final UserActivityItem item in raw) {
      if (item.targetUserId.isEmpty) continue;
      final UserActivityItem? existing = merged[item.targetUserId];
      if (existing == null) {
        merged[item.targetUserId] = item;
        continue;
      }

      final DateTime existingTime =
          existing.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime incomingTime =
          item.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bool pickIncoming = incomingTime.isAfter(existingTime);

      if (pickIncoming) {
        merged[item.targetUserId] = UserActivityItem(
          targetUserId: item.targetUserId,
          createdAt: item.createdAt,
          reason: item.reason?.isNotEmpty == true
              ? item.reason
              : existing.reason,
        );
        continue;
      }

      if ((existing.reason == null || existing.reason!.isEmpty) &&
          (item.reason?.isNotEmpty == true)) {
        merged[item.targetUserId] = UserActivityItem(
          targetUserId: existing.targetUserId,
          createdAt: existing.createdAt,
          reason: item.reason,
        );
      }
    }

    final List<UserActivityItem> items = merged.values.toList(growable: false);
    _sortByCreatedAtDesc(items);
    return items;
  }

  bool _isPermissionDenied(FirebaseException exception) {
    return exception.code == 'permission-denied';
  }

  bool _isDemoUserUid(String uid) {
    return uid.startsWith('demo_boy_') || uid.startsWith('demo_girl_');
  }

  String _buildMatchId(String uidA, String uidB) {
    final List<String> users = <String>[uidA, uidB]..sort();
    return '${users[0]}_${users[1]}';
  }
}

final List<AppUser> _demoUsers = _buildDemoUsers();

List<AppUser> _buildDemoUsers() {
  const List<String> cities = <String>[
    'Karachi',
    'Lahore',
    'Islamabad',
    'Rawalpindi',
    'Peshawar',
    'Faisalabad',
    'Multan',
    'Hyderabad',
    'Quetta',
    'Sialkot',
  ];

  const List<String> menNames = <String>[
    'Liam',
    'Noah',
    'Ethan',
    'Logan',
    'Aiden',
    'Ryan',
    'Mason',
    'Owen',
    'Jacob',
    'Lucas',
    'Asher',
    'Daniel',
    'Caleb',
    'Henry',
    'Leo',
    'Adam',
    'Eli',
    'Hudson',
    'Isaac',
    'Julian',
    'Nolan',
    'Parker',
    'Roman',
    'Theo',
    'Zane',
  ];

  const List<String> womenNames = <String>[
    'Ava',
    'Mia',
    'Sophia',
    'Isabella',
    'Olivia',
    'Emma',
    'Amelia',
    'Harper',
    'Ella',
    'Aria',
    'Nora',
    'Luna',
    'Chloe',
    'Grace',
    'Hazel',
    'Ivy',
    'Leah',
    'Mila',
    'Naomi',
    'Piper',
    'Ruby',
    'Sarah',
    'Tessa',
    'Violet',
    'Zara',
  ];

  const List<String> menBios = <String>[
    'Coffee, football and spontaneous road trips.',
    'Gym in the morning, gaming at night.',
    'Photographer chasing city lights and stories.',
    'Foodie soul, sunset biker, and travel lover.',
    'Calm energy with a loud laugh and big dreams.',
  ];

  const List<String> womenBios = <String>[
    'Sunsets, poetry and long walks with good music.',
    'Artist soul, chai lover, and weekend traveler.',
    'Books, baking, and meaningful conversations.',
    'Dancing, desserts and deep talks after midnight.',
    'Curious mind, soft heart, and bold plans.',
  ];

  const List<String> menPhotos = <String>[
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=900&q=80',
    'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=900&q=80',
    'https://images.unsplash.com/photo-1463453091185-61582044d556?auto=format&fit=crop&w=900&q=80',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=900&q=80',
    'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?auto=format&fit=crop&w=900&q=80',
    'https://images.unsplash.com/photo-1504257432389-52343af06ae3?auto=format&fit=crop&w=900&q=80',
    'https://images.unsplash.com/photo-1528892952291-009c663ce843?auto=format&fit=crop&w=900&q=80',
    'https://images.unsplash.com/photo-1546961329-78bef0414d7c?auto=format&fit=crop&w=900&q=80',
    'https://images.unsplash.com/photo-1504593811423-6dd665756598?auto=format&fit=crop&w=900&q=80',
    'https://images.unsplash.com/photo-1499996860823-5214fcc65f8f?auto=format&fit=crop&w=900&q=80',
  ];

  const List<String> womenPhotos = <String>[
    'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?auto=format&fit=crop&w=900&q=80',
    'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=900&q=80',
    'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=900&q=80',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=900&q=80',
    'https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91?auto=format&fit=crop&w=900&q=80',
    'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?auto=format&fit=crop&w=900&q=80',
    'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?auto=format&fit=crop&w=900&q=80',
    'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=900&q=80',
    'https://images.unsplash.com/photo-1504593811423-6dd665756598?auto=format&fit=crop&w=900&q=80',
    'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=900&q=80',
  ];

  final List<AppUser> users = <AppUser>[];

  for (int i = 0; i < menNames.length; i++) {
    final String name = menNames[i];
    users.add(
      AppUser(
        uid: 'demo_boy_${(i + 1).toString().padLeft(2, '0')}',
        email: '${name.toLowerCase()}.demo@soulmatch.app',
        displayName: name,
        bio: menBios[i % menBios.length],
        age: 22 + (i % 9),
        gender: 'Man',
        interestedIn: 'Woman',
        location: cities[i % cities.length],
        photos: <String>[menPhotos[i % menPhotos.length]],
        onboardingCompleted: true,
        profileCompleted: true,
      ),
    );
  }

  for (int i = 0; i < womenNames.length; i++) {
    final String name = womenNames[i];
    users.add(
      AppUser(
        uid: 'demo_girl_${(i + 1).toString().padLeft(2, '0')}',
        email: '${name.toLowerCase()}.demo@soulmatch.app',
        displayName: name,
        bio: womenBios[i % womenBios.length],
        age: 21 + (i % 9),
        gender: 'Woman',
        interestedIn: 'Man',
        location: cities[(i + 3) % cities.length],
        photos: <String>[womenPhotos[i % womenPhotos.length]],
        onboardingCompleted: true,
        profileCompleted: true,
      ),
    );
  }

  return users;
}
