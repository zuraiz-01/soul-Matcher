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

    final List<AppUser> firestoreUsers = snapshot.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
          return AppUser.fromMap(doc.data(), doc.id);
        })
        .toList(growable: false);

    final List<AppUser> combined = <AppUser>[...firestoreUsers, ..._demoUsers];

    return combined
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
        .take(AppConstants.discoverBatchSize)
        .toList(growable: false);
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
