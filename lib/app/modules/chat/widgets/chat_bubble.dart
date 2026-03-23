import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:soul_matcher/app/data/models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({required this.message, required this.isMine, super.key});

  final ChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(isMine ? 16 : 4),
      bottomRight: Radius.circular(isMine ? 4 : 16),
    );
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: isMine ? const Color(0xFFE55B79) : const Color(0x2AFFFFFF),
          border: isMine ? null : Border.all(color: const Color(0x30FFFFFF)),
          borderRadius: radius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            if (message.text.isNotEmpty)
              Text(
                message.text,
                style: TextStyle(color: isMine ? Colors.white : null),
              ),
            const SizedBox(height: 4),
            Text(
              message.createdAt == null
                  ? 'Now'
                  : DateFormat('h:mm a').format(message.createdAt!),
              style: TextStyle(
                color: isMine ? Colors.white70 : Colors.grey,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
