import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soul_matcher/app/data/models/app_user.dart';
import 'package:soul_matcher/app/data/repositories/auth_repository.dart';
import 'package:soul_matcher/app/data/repositories/user_repository.dart';
import 'package:soul_matcher/app/modules/discover/discover_page.dart';
import 'package:soul_matcher/app/modules/home/home_controller.dart';
import 'package:soul_matcher/app/modules/matches/matches_page.dart';
import 'package:soul_matcher/app/routes/app_routes.dart';
import 'package:soul_matcher/app/widgets/premium_background.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    const List<Widget> tabs = <Widget>[DiscoverPage(), MatchesPage(), _MeTab()];

    return Obx(
      () => Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: controller.selectedIndex.value,
          children: tabs,
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: NavigationBar(
              selectedIndex: controller.selectedIndex.value,
              onDestinationSelected: controller.changeTab,
              destinations: const <NavigationDestination>[
                NavigationDestination(
                  icon: Icon(Icons.explore_outlined),
                  selectedIcon: Icon(Icons.explore),
                  label: 'Discover',
                ),
                NavigationDestination(
                  icon: Icon(Icons.favorite_outline_rounded),
                  selectedIcon: Icon(Icons.favorite_rounded),
                  label: 'Matches',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Me',
                ),
              ],
            ),
          ),
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
              final AppUser? user = snapshot.data;
              if (!snapshot.hasData || user == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return ListView(
                children: <Widget>[
                  Text(
                    'My Profile',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 14),
                  PremiumGlassCard(
                    child: Column(
                      children: <Widget>[
                        CircleAvatar(
                          radius: 48,
                          backgroundImage: user.photos.isNotEmpty
                              ? NetworkImage(user.photos.first)
                              : null,
                          child: user.photos.isEmpty
                              ? Text(
                                  user.displayName.isEmpty
                                      ? '?'
                                      : user.displayName[0],
                                )
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user.displayName.isEmpty
                              ? 'Your Profile'
                              : user.displayName,
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        if (user.location.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 6),
                          Text(
                            user.location,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.white70),
                          ),
                        ],
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed: () => Get.toNamed(AppRoutes.profileEdit),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit Profile'),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () => Get.toNamed(AppRoutes.settings),
                          icon: const Icon(Icons.settings_outlined),
                          label: const Text('Settings'),
                        ),
                      ],
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
