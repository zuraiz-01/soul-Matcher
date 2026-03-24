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
    final dynamic rawUnreadData = map['unreadCount'];
    final Map<String, dynamic> rawUnread = rawUnreadData is Map
        ? rawUnreadData.map(
            (dynamic key, dynamic value) =>
                MapEntry(key.toString(), value),
          )
        : <String, dynamic>{};

    final dynamic rawUsersData = map['users'];
    final List<String> users = rawUsersData is List
        ? rawUsersData.map((dynamic e) => e.toString()).toList()
        : <String>[];

    int parseUnread(dynamic value) {
      if (value is num) return value.toInt();
      if (value is String) {
        return int.tryParse(value) ?? 0;
      }
      return 0;
    }

    DateTime? parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return null;
    }

    return MatchModel(
      id: docId,
      users: users,
      createdAt: parseDate(map['createdAt']),
      lastMessage: map['lastMessage']?.toString(),
      lastMessageAt: parseDate(map['lastMessageAt']),
      unreadCount: rawUnread.map(
        (String key, dynamic value) => MapEntry(key, parseUnread(value)),
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
