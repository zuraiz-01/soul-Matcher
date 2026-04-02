import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soul_matcher/app/data/models/app_user.dart';
import 'package:soul_matcher/app/data/models/swipe_action.dart';
import 'package:soul_matcher/app/modules/discover/discover_controller.dart';
import 'package:soul_matcher/app/modules/discover/widgets/discover_card.dart';
import 'package:soul_matcher/app/modules/discover/widgets/discover_interaction_widgets.dart';
import 'package:soul_matcher/app/modules/discover/widgets/filter_bottom_sheet.dart';
import 'package:soul_matcher/app/widgets/app_loader.dart';
import 'package:soul_matcher/app/widgets/empty_state.dart';
import 'package:soul_matcher/app/widgets/premium_background.dart';

class DiscoverPage extends GetView<DiscoverController> {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PremiumBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: <Widget>[
              PremiumGlassCard(
                padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Discover',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        showModalBottomSheet<void>(
                          context: context,
                          builder: (_) => FilterBottomSheet(
                            initialFilter: controller.filter.value,
                            onApply: controller.applyFilter,
                          ),
                        );
                      },
                      icon: const Icon(Icons.tune_rounded),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller.searchController,
                onChanged: controller.onSearchChanged,
                decoration: const InputDecoration(
                  hintText: 'Search by name',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Obx(() {
                  return _buildBody(context);
                }),
              ),
              const SizedBox(height: 8),
              Obx(
                () => DiscoverActionButtons(
                  enabled: controller.candidates.isNotEmpty,
                  onPass: controller.swipeLeft,
                  onSuperLike: controller.superLike,
                  onLike: controller.swipeRight,
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (controller.isLoading.value && controller.candidates.isEmpty) {
      return const AppLoader();
    }
    if (controller.candidates.isEmpty) {
      return EmptyState(
        title: 'No more profiles',
        subtitle: 'Try adjusting filters or check back later.',
        actionLabel: 'Refresh',
        onAction: controller.refreshCandidates,
      );
    }

    final AppUser user = controller.candidates.first;
    return Align(
      child: FractionallySizedBox(
        widthFactor: 0.96,
        heightFactor: 0.95,
        child: Dismissible(
          key: ValueKey<String>('discover_${user.uid}'),
          direction: DismissDirection.horizontal,
          confirmDismiss: (DismissDirection direction) async {
            final SwipeType swipeType = direction == DismissDirection.startToEnd
                ? SwipeType.like
                : SwipeType.pass;
            return controller.swipeFromDismiss(target: user, type: swipeType);
          },
          onDismissed: (_) => controller.removeCandidate(user.uid),
          child: GestureDetector(
            onTap: () => controller.openProfile(user),
            child: DiscoverCard(
              user: user,
              onMorePressed: () => _showMoreActionSheet(context),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showMoreActionSheet(BuildContext context) async {
    final DiscoverSafetyAction? action = await showDiscoverSafetyActionSheet(
      context,
    );

    if (action == null || !context.mounted) return;
    if (action == DiscoverSafetyAction.report) {
      await showDiscoverReportBottomSheet(
        context: context,
        onSubmit: controller.reportCurrent,
      );
      return;
    }
    if (action == DiscoverSafetyAction.block) {
      await controller.blockCurrent();
    }
  }
}
