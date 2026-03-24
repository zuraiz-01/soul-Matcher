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

class TypingBubble extends StatelessWidget {
  const TypingBubble({super.key});

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: const Radius.circular(4),
      bottomRight: const Radius.circular(16),
    );

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 140),
        decoration: BoxDecoration(
          color: const Color(0x2AFFFFFF),
          border: Border.all(color: const Color(0x30FFFFFF)),
          borderRadius: radius,
        ),
        child: const _TypingDots(),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 14,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, Widget? child) {
          final double t = _controller.value;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              _dot(opacity: _dotOpacity(t, 0.0)),
              _dot(opacity: _dotOpacity(t, 0.2)),
              _dot(opacity: _dotOpacity(t, 0.4)),
            ],
          );
        },
      ),
    );
  }

  double _dotOpacity(double t, double delay) {
    final double phase = (t + delay) % 1.0;
    if (phase < 0.5) {
      return 0.35 + (phase / 0.5) * 0.65;
    }
    return 1.0 - ((phase - 0.5) / 0.5) * 0.65;
  }

  Widget _dot({required double opacity}) {
    return Opacity(
      opacity: opacity.clamp(0.25, 1.0),
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
