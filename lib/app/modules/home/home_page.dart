import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soul_matcher/app/data/models/app_user.dart';
import 'package:soul_matcher/app/data/repositories/auth_repository.dart';
import 'package:soul_matcher/app/data/repositories/user_repository.dart';
import 'package:soul_matcher/app/modules/discover/discover_page.dart';
import 'package:soul_matcher/app/modules/home/home_controller.dart';
import 'package:soul_matcher/app/modules/matches/matches_page.dart';
import 'package:soul_matcher/app/modules/settings/settings_page.dart';
import 'package:soul_matcher/app/routes/app_routes.dart';
import 'package:soul_matcher/app/widgets/admob_banner.dart';
import 'package:soul_matcher/app/widgets/premium_background.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    const List<Widget> tabs = <Widget>[
      DiscoverPage(),
      MatchesPage(),
      _MeTab(),
      SettingsPage(),
    ];

    return Obx(
      () => Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: controller.selectedIndex.value,
          children: tabs,
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (controller.shouldShowAds)
              const AdMobBanner(margin: EdgeInsets.fromLTRB(0, 2, 0, 10)),
            SafeArea(
              minimum: const EdgeInsets.fromLTRB(10, 0, 10, 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: NavigationBar(
                  height: 62,
                  selectedIndex: controller.selectedIndex.value,
                  onDestinationSelected: controller.changeTab,
                  destinations: const <NavigationDestination>[
                    NavigationDestination(
                      icon: Icon(Icons.explore_outlined, size: 20),
                      selectedIcon: Icon(Icons.explore, size: 20),
                      label: 'Discover',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.favorite_outline_rounded, size: 20),
                      selectedIcon: Icon(Icons.favorite_rounded, size: 20),
                      label: 'Matches',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline_rounded, size: 20),
                      selectedIcon: Icon(Icons.person_rounded, size: 20),
                      label: 'Me',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.settings_outlined, size: 20),
                      selectedIcon: Icon(Icons.settings, size: 20),
                      label: 'Settings',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeTab extends StatelessWidget {
  const _MeTab();

  @override
  Widget build(BuildContext context) {
    final AuthRepository authRepository = Get.find<AuthRepository>();
    final UserRepository userRepository = Get.find<UserRepository>();
    final String uid = authRepository.currentUser?.uid ?? '';

    if (uid.isEmpty) {
      return const Center(child: Text('Not signed in'));
    }

    return PremiumBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: StreamBuilder<AppUser?>(
            stream: userRepository.streamUser(uid),
            builder: (_, AsyncSnapshot<AppUser?> snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: PremiumGlassCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(Icons.warning_amber_rounded),
                        const SizedBox(height: 10),
                        Text(
                          'Profile load error',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          snapshot.error.toString(),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              }
              final AppUser? user = snapshot.data;
              if (!snapshot.hasData || user == null) {
                return const Center(child: CircularProgressIndicator());
              }

              final ThemeData theme = Theme.of(context);
              final String displayName = user.displayName.trim().isEmpty
                  ? 'Your Profile'
                  : user.displayName.trim();

              final List<_ProfileMetaItem> metaItems = <_ProfileMetaItem>[
                if (user.age != null)
                  _ProfileMetaItem(
                    icon: Icons.cake_outlined,
                    label: '${user.age} years',
                  ),
                if (user.gender?.trim().isNotEmpty == true)
                  _ProfileMetaItem(
                    icon: Icons.person_pin_circle_outlined,
                    label: user.gender!.trim(),
                  ),
                if (user.interestedIn?.trim().isNotEmpty == true)
                  _ProfileMetaItem(
                    icon: Icons.favorite_border_rounded,
                    label: 'Interested in ${user.interestedIn!.trim()}',
                  ),
                if (user.location.trim().isNotEmpty)
                  _ProfileMetaItem(
                    icon: Icons.location_on_outlined,
                    label: user.location.trim(),
                  ),
                _ProfileMetaItem(
                  icon: Icons.photo_library_outlined,
                  label: '${user.photos.length} photo(s)',
                ),
              ];

              return ListView(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'My Profile',
                          style: theme.textTheme.headlineSmall,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Text(
                          'SoulMatch',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Keep your profile fresh to get better matches.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withValues(
                        alpha: 0.72,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  PremiumGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            CircleAvatar(
                              radius: 46,
                              backgroundColor:
                                  theme.colorScheme.surfaceContainerHighest,
                              child: _ProfileAvatarImage(user: user),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    displayName,
                                    style: theme.textTheme.titleLarge,
                                  ),
                                  if (user.email.trim().isNotEmpty) ...<Widget>[
                                    const SizedBox(height: 4),
                                    Text(
                                      user.email.trim(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(color: Colors.white70),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: metaItems
                              .map(
                                (_ProfileMetaItem item) =>
                                    _ProfileMetaChip(item: item),
                              )
                              .toList(growable: false),
                        ),
                        if (user.bio.trim().isNotEmpty) ...<Widget>[
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Text(
                              user.bio.trim(),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Get.toNamed(AppRoutes.profileEdit),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit Profile'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProfileMetaItem {
  const _ProfileMetaItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _ProfileMetaChip extends StatelessWidget {
  const _ProfileMetaChip({required this.item});

  final _ProfileMetaItem item;

  @override
  Widget build(BuildContext context) {
    final double maxChipWidth = (MediaQuery.sizeOf(context).width - 120)
        .clamp(140.0, 280.0)
        .toDouble();

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxChipWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(item.icon, size: 14, color: Colors.white70),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatarImage extends StatelessWidget {
  const _ProfileAvatarImage({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final String fallbackLabel = user.displayName.isEmpty
        ? '?'
        : user.displayName[0];
    if (user.photos.isEmpty || user.photos.first.trim().isEmpty) {
      return Text(fallbackLabel);
    }

    return ClipOval(
      child: Image.network(
        user.photos.first,
        width: 96,
        height: 96,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.low,
        cacheWidth: 240,
        errorBuilder: (_, _, _) => Text(fallbackLabel),
      ),
    );
  }
}
