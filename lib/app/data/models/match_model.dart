import 'package:cloud_firestore/cloud_firestore.dart';

class MatchModel {
  const MatchModel({
    required this.id,
    required this.users,
    this.createdAt,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = const <String, int>{},
  });

  final String id;
  final List<String> users;
  final DateTime? createdAt;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final Map<String, int> unreadCount;

  factory MatchModel.fromMap(Map<String, dynamic> map, String docId) {
    final Map<String, dynamic> rawUnread =
        (map['unreadCount'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    return MatchModel(
      id: docId,
      users: ((map['users'] as List<dynamic>?) ?? <dynamic>[])
          .map((dynamic e) => e.toString())
          .toList(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      lastMessage: map['lastMessage'] as String?,
      lastMessageAt: (map['lastMessageAt'] as Timestamp?)?.toDate(),
      unreadCount: rawUnread.map(
        (String key, dynamic value) => MapEntry(key, (value as num).toInt()),
      ),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'users': users,
    'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
    'lastMessage': lastMessage,
    'lastMessageAt': lastMessageAt == null
        ? null
        : Timestamp.fromDate(lastMessageAt!),
    'unreadCount': unreadCount,
  };

  String otherUserId(String myUid) {
    return users.firstWhere((String uid) => uid != myUid, orElse: () => '');
  }
}
