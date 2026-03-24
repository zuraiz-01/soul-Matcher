import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:soul_matcher/app/data/models/chat_message.dart';
import 'package:soul_matcher/app/data/models/match_model.dart';

class ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _matches =>
      _firestore.collection('matches');

  Stream<List<ChatMessage>> streamMessages(String matchId) {
    return _matches
        .doc(matchId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> query) {
          return query.docs.map((
            QueryDocumentSnapshot<Map<String, dynamic>> doc,
          ) {
            return ChatMessage.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  Stream<List<MatchModel>> streamMatches(String uid) {
    return _matches
        .where('users', arrayContains: uid)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> query) {
          final List<MatchModel> matches = query.docs.map((
            QueryDocumentSnapshot<Map<String, dynamic>> doc,
          ) {
            return MatchModel.fromMap(doc.data(), doc.id);
          }).toList();

          // Keep sorting client-side to avoid requiring a composite Firestore
          // index for arrayContains + orderBy queries.
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

  Future<void> sendMessage({
    required String matchId,
    required String senderId,
    required String receiverId,
    required String text,
    String? imageUrl,
  }) async {
    final DocumentReference<Map<String, dynamic>> matchRef = _matches.doc(
      matchId,
    );
    final DocumentReference<Map<String, dynamic>> messageRef = matchRef
        .collection('messages')
        .doc();

    await _firestore.runTransaction((Transaction transaction) async {
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await transaction
          .get(matchRef);
      final Map<String, dynamic> current =
          snapshot.data() ?? <String, dynamic>{};
      final Map<String, dynamic> unread =
          (current['unreadCount'] as Map<String, dynamic>?) ??
          <String, dynamic>{};
      final int currentUnread = (unread[receiverId] as num?)?.toInt() ?? 0;

      transaction.set(messageRef, <String, dynamic>{
        'matchId': matchId,
        'senderId': senderId,
        'receiverId': receiverId,
        'text': text.trim(),
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      transaction.set(matchRef, <String, dynamic>{
        'lastMessage': text.trim().isEmpty ? '[image]' : text.trim(),
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadCount': <String, int>{
          ...unread.map(
            (String key, dynamic value) =>
                MapEntry(key, (value as num?)?.toInt() ?? 0),
          ),
          receiverId: currentUnread + 1,
        },
      }, SetOptions(merge: true));
    });
  }

  Future<void> markAsRead({required String matchId, required String uid}) {
    return _matches.doc(matchId).update(<String, dynamic>{
      'unreadCount.$uid': 0,
    });
  }
}
