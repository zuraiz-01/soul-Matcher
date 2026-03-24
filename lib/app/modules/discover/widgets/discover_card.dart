import 'package:flutter/material.dart';
import 'package:soul_matcher/app/data/models/app_user.dart';

class DiscoverCard extends StatelessWidget {
  const DiscoverCard({
    required this.user,
    required this.onMorePressed,
    super.key,
  });

  final AppUser user;
  final VoidCallback onMorePressed;

  @override
  Widget build(BuildContext context) {
    final String? photo = user.photos.isNotEmpty ? user.photos.first : null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (photo != null)
            Image.network(
              photo,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildPhotoFallback(),
            )
          else
            _buildPhotoFallback(),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[Colors.transparent, Colors.black87],
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.more_horiz, color: Colors.white),
                onPressed: onMorePressed,
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  '${user.displayName}${user.age != null ? ', ${user.age}' : ''}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                if (user.location.isNotEmpty)
                  Text(
                    user.location,
                    style: const TextStyle(color: Colors.white70),
                  ),
                if (user.bio.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    user.bio,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF1B2333), Color(0xFF3A1F2F)],
        ),
      ),
      child: const Icon(Icons.person, size: 80, color: Colors.white70),
    );
  }
}
