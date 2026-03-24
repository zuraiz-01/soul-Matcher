import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soul_matcher/app/data/models/app_user.dart';
import 'package:soul_matcher/app/data/models/swipe_action.dart';
import 'package:soul_matcher/app/modules/discover/discover_controller.dart';
import 'package:soul_matcher/app/widgets/premium_background.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  late final PageController _pageController;
  late final AppUser? _user;
  late final DiscoverController? _discoverController;
  int _currentPhotoIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _user = _extractUser(Get.arguments);
    _discoverController = Get.isRegistered<DiscoverController>()
        ? Get.find<DiscoverController>()
        : null;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppUser? user = _user;
    if (user == null) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const PremiumBackground(
          child: Center(child: Text('Profile not found')),
        ),
      );
    }

    final List<String> photos = user.photos
        .where((String photo) => photo.trim().isNotEmpty)
        .toList(growable: false);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: PremiumBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            children: <Widget>[
              _PhotoGallery(
                user: user,
                photos: photos,
                pageController: _pageController,
                currentPhotoIndex: _currentPhotoIndex,
                onPageChanged: (int index) {
                  setState(() {
                    _currentPhotoIndex = index;
                  });
                },
                onThumbnailTap: (int index) {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                  );
                },
              ),
              const SizedBox(height: 16),
              _ProfileHeader(user: user),
              if (user.bio.trim().isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                PremiumGlassCard(
                  child: Text(
                    user.bio.trim(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _ActionSection(
                user: user,
                discoverController: _discoverController,
                onPassTap: () => _onSwipe(SwipeType.pass),
                onSuperLikeTap: () => _onSwipe(SwipeType.superLike),
                onLikeTap: () => _onSwipe(SwipeType.like),
                onChatTap: _onChatTap,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onSwipe(SwipeType type) async {
    final DiscoverController? controller = _discoverController;
    final AppUser? user = _user;
    if (controller == null || user == null) {
      Get.snackbar(
        'Action unavailable',
        'Please open this profile from Discover.',
      );
      return;
    }
    final bool didSwipe = await controller.swipeOnUser(
      user,
      type: type,
      showFeedback: true,
    );
    if (didSwipe && mounted) {
      Get.back<void>();
    }
  }

  Future<void> _onChatTap() async {
    final DiscoverController? controller = _discoverController;
    final AppUser? user = _user;
    if (controller == null || user == null) {
      Get.snackbar(
        'Chat unavailable',
        'Please open this profile from Discover.',
      );
      return;
    }
    await controller.openChatWithUser(user);
  }

  AppUser? _extractUser(dynamic arguments) {
    if (arguments is AppUser) return arguments;
    if (arguments is Map<String, dynamic>) {
      final dynamic userValue = arguments['user'];
      if (userValue is AppUser) return userValue;
    }
    return null;
  }
}

class _PhotoGallery extends StatelessWidget {
  const _PhotoGallery({
    required this.user,
    required this.photos,
    required this.pageController,
    required this.currentPhotoIndex,
    required this.onPageChanged,
    required this.onThumbnailTap,
  });

  final AppUser user;
  final List<String> photos;
  final PageController pageController;
  final int currentPhotoIndex;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onThumbnailTap;

  @override
  Widget build(BuildContext context) {
    final List<String?> galleryItems = photos.isEmpty
        ? const <String?>[null]
        : photos;
    final int total = galleryItems.length;
    final int activeIndex = currentPhotoIndex.clamp(0, total - 1);

    return PremiumGlassCard(
      padding: const EdgeInsets.all(10),
      borderRadius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 420,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  PageView.builder(
                    controller: pageController,
                    itemCount: total,
                    onPageChanged: onPageChanged,
                    itemBuilder: (_, int index) {
                      final String? photoUrl = galleryItems[index];
                      if (photoUrl == null) {
                        return _PhotoFallback(label: _fallbackLabel(user));
                      }
                      return Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            _PhotoFallback(label: _fallbackLabel(user)),
                      );
                    },
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: Text(
                          '${activeIndex + 1}/$total',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(14, 24, 14, 14),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[Colors.transparent, Colors.black87],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            '${user.displayName}${user.age == null ? '' : ', ${user.age}'}',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          if (user.location.trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                user.location.trim(),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.white70),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (total > 1) ...<Widget>[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(total, (int index) {
                final bool selected = activeIndex == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: selected ? 18 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFE55B79)
                        : Colors.white.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: total,
                separatorBuilder: (_, int _) => const SizedBox(width: 8),
                itemBuilder: (_, int index) {
                  final bool selected = activeIndex == index;
                  final String? photoUrl = galleryItems[index];
                  return GestureDetector(
                    onTap: () => onThumbnailTap(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFFE55B79)
                              : Colors.white.withValues(alpha: 0.2),
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: photoUrl == null
                            ? _PhotoFallback(
                                label: _fallbackLabel(user),
                                compact: true,
                              )
                            : Image.network(
                                photoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => _PhotoFallback(
                                  label: _fallbackLabel(user),
                                  compact: true,
                                ),
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _fallbackLabel(AppUser user) {
    final String trimmed = user.displayName.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.characters.first.toUpperCase();
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return PremiumGlassCard(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          _MetaChip(
            icon: Icons.person_outline_rounded,
            label: user.gender?.trim().isNotEmpty == true
                ? user.gender!.trim()
                : 'Gender not set',
          ),
          _MetaChip(
            icon: Icons.favorite_outline_rounded,
            label: user.interestedIn?.trim().isNotEmpty == true
                ? 'Interested in ${user.interestedIn!.trim()}'
                : 'Preference not set',
          ),
          _MetaChip(
            icon: Icons.photo_library_outlined,
            label: '${user.photos.length} photo(s)',
          ),
        ],
      ),
    );
  }
}

class _ActionSection extends StatelessWidget {
  const _ActionSection({
    required this.user,
    required this.discoverController,
    required this.onPassTap,
    required this.onSuperLikeTap,
    required this.onLikeTap,
    required this.onChatTap,
  });

  final AppUser user;
  final DiscoverController? discoverController;
  final Future<void> Function() onPassTap;
  final Future<void> Function() onSuperLikeTap;
  final Future<void> Function() onLikeTap;
  final Future<void> Function() onChatTap;

  @override
  Widget build(BuildContext context) {
    final DiscoverController? controller = discoverController;
    if (controller == null) {
      return PremiumGlassCard(
        child: Text(
          'Open this profile from Discover to use chat and swipe actions.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
        ),
      );
    }

    return Obx(() {
      final bool busy = controller.isSwiping.value;
      return PremiumGlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            FilledButton.icon(
              onPressed: busy ? null : onChatTap,
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: Text('Chat with ${_displayName(user)}'),
            ),
            const SizedBox(height: 10),
            Text(
              'Like creates a match when both users like each other.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                _CircleActionButton(
                  icon: Icons.close_rounded,
                  label: 'Pass',
                  color: const Color(0xFF8E8E93),
                  onTap: busy ? null : onPassTap,
                ),
                _CircleActionButton(
                  icon: Icons.star_rounded,
                  label: 'Super Like',
                  color: const Color(0xFF5A7DFF),
                  onTap: busy ? null : onSuperLikeTap,
                ),
                _CircleActionButton(
                  icon: Icons.favorite_rounded,
                  label: 'Like',
                  color: const Color(0xFFE55B79),
                  onTap: busy ? null : onLikeTap,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  static String _displayName(AppUser user) {
    final String name = user.displayName.trim();
    return name.isEmpty ? 'this user' : name;
  }
}

class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Future<void> Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Material(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onTap == null ? null : () => onTap!(),
            child: SizedBox(
              width: 58,
              height: 58,
              child: Icon(icon, color: color, size: 30),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: Colors.white70),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback({required this.label, this.compact = false});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF1B2333), Color(0xFF3A1F2F)],
        ),
      ),
      child: Center(
        child: compact
            ? Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              )
            : Icon(
                Icons.person_rounded,
                size: 72,
                color: Colors.white.withValues(alpha: 0.72),
              ),
      ),
    );
  }
}
