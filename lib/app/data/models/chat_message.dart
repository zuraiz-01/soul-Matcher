import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.matchId,
    required this.senderId,
    required this.receiverId,
    this.text = '',
    this.imageUrl,
    this.createdAt,
  });

  final String id;
  final String matchId;
  final String senderId;
  final String receiverId;
  final String text;
  final String? imageUrl;
  final DateTime? createdAt;

  factory ChatMessage.fromMap(Map<String, dynamic> map, String docId) {
    return ChatMessage(
      id: docId,
      matchId: map['matchId'] as String? ?? '',
      senderId: map['senderId'] as String? ?? '',
      receiverId: map['receiverId'] as String? ?? '',
      text: map['text'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'matchId': matchId,
    'senderId': senderId,
    'receiverId': receiverId,
    'text': text,
    'imageUrl': imageUrl,
    'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
  };
}
