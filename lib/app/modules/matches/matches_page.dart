import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soul_matcher/app/data/models/match_model.dart';
import 'package:soul_matcher/app/modules/matches/matches_controller.dart';
import 'package:soul_matcher/app/modules/matches/widgets/match_tile.dart';
import 'package:soul_matcher/app/widgets/app_loader.dart';
import 'package:soul_matcher/app/widgets/empty_state.dart';
import 'package:soul_matcher/app/widgets/premium_background.dart';

class MatchesPage extends GetView<MatchesController> {
  const MatchesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PremiumBackground(
      child: SafeArea(
        child: Obx(
          () => Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: <Widget>[
                const PremiumGlassCard(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Matches',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller.searchController,
                  onChanged: controller.onSearchChanged,
                  decoration: const InputDecoration(
                    hintText: 'Search matches',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (controller.isLoading.value) {
      return const AppLoader();
    }
    final List<MatchModel> data = controller.filteredMatches;
    if (data.isEmpty) {
      return const EmptyState(
        title: 'No matches yet',
        subtitle: 'Keep swiping to find your spark.',
        icon: Icons.favorite_border_rounded,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: data.length,
      itemBuilder: (_, int index) {
        final MatchModel match = data[index];
        return MatchTile(
          name: controller.displayNameForMatch(match),
          photoUrl: controller.photoForMatch(match),
          subtitle: match.lastMessage ?? '',
          unread: controller.unreadFor(match),
          lastMessageAt: match.lastMessageAt,
          onTap: () => controller.openChat(match),
        );
      },
    );
  }
}
