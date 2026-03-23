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
    super.key,
  });

  final String name;
  final String? photoUrl;
  final String subtitle;
  final int unread;
  final DateTime? lastMessageAt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          radius: 24,
          backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
          child: photoUrl == null ? const Icon(Icons.person) : null,
        ),
        title: Text(name),
        subtitle: Text(
          subtitle.isEmpty ? 'Say hi' : subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
