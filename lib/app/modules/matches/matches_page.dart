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
      itemBuilder: (BuildContext context, int index) {
        final MatchModel match = data[index];
        return MatchTile(
          name: controller.displayNameForMatch(match),
          photoUrl: controller.photoForMatch(match),
          subtitle: match.lastMessage ?? '',
          unread: controller.unreadFor(match),
          lastMessageAt: match.lastMessageAt,
          onTap: () => controller.openChat(match),
          onLongPress: () => _showMatchActions(context, match),
        );
      },
    );
  }

  Future<void> _showMatchActions(BuildContext context, MatchModel match) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: PremiumGlassCard(
              child: Obx(
                () => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    Text(
                      controller.displayNameForMatch(match),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Delete chat messages from this conversation.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: controller.isDeletingMatch(match.id)
                          ? null
                          : () async {
                              Navigator.of(context).pop();
                              await controller.clearChat(match);
                            },
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Delete chat'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
