import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MatchTile extends StatelessWidget {
  const MatchTile({
    required this.name,
    required this.photoUrl,
    required this.subtitle,
    required this.unread,
    required this.lastMessageAt,
    required this.onTap,
    this.onLongPress,
    super.key,
  });

  final String name;
  final String? photoUrl;
  final String subtitle;
  final int unread;
  final DateTime? lastMessageAt;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        onLongPress: onLongPress,
        leading: CircleAvatar(
          radius: 24,
          child: _MatchAvatarImage(photoUrl: photoUrl),
        ),
        title: Text(name),
        subtitle: Text(
          subtitle.isEmpty ? 'Say hi' : subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xCCFFFFFF)),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (lastMessageAt != null)
              Text(
                DateFormat('h:mm a').format(lastMessageAt!),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (unread > 0) ...<Widget>[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  unread.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MatchAvatarImage extends StatelessWidget {
  const _MatchAvatarImage({required this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    if (photoUrl == null || photoUrl!.trim().isEmpty) {
      return const Icon(Icons.person);
    }

    return ClipOval(
      child: Image.network(
        photoUrl!,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Icon(Icons.person),
      ),
    );
  }
}
