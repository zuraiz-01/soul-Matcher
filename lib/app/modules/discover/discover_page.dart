import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soul_matcher/app/modules/discover/discover_controller.dart';
import 'package:soul_matcher/app/modules/discover/widgets/discover_card.dart';
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
        child: Obx(
          () => Padding(
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
                const SizedBox(height: 14),
                Expanded(child: _buildBody(context)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    _ActionButton(
                      icon: Icons.close_rounded,
                      color: const Color(0xFF8E8E93),
                      onTap: controller.candidates.isEmpty
                          ? null
                          : controller.swipeLeft,
                    ),
                    _ActionButton(
                      icon: Icons.star_rounded,
                      color: const Color(0xFF5A7DFF),
                      onTap: controller.candidates.isEmpty
                          ? null
                          : controller.superLike,
                    ),
                    _ActionButton(
                      icon: Icons.favorite_rounded,
                      color: const Color(0xFFE55B79),
                      onTap: controller.candidates.isEmpty
                          ? null
                          : controller.swipeRight,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
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
        onAction: controller.loadCandidates,
      );
    }

    final user = controller.candidates.first;
    return Dismissible(
      key: ValueKey<String>('discover_${user.uid}'),
      direction: DismissDirection.horizontal,
      onDismissed: (DismissDirection direction) {
        if (direction == DismissDirection.startToEnd) {
          controller.swipeRight();
        } else {
          controller.swipeLeft();
        }
      },
      child: DiscoverCard(
        user: user,
        onMorePressed: () => _showMoreActionSheet(context),
      ),
    );
  }

  void _showMoreActionSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Report user'),
              onTap: () async {
                Navigator.of(context).pop();
                await _showReportDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.block_outlined),
              title: const Text('Block user'),
              onTap: () {
                Navigator.of(context).pop();
                controller.blockCurrent();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReportDialog(BuildContext context) async {
    final TextEditingController reasonController = TextEditingController();
    await Get.defaultDialog(
      title: 'Report user',
      content: Column(
        children: <Widget>[
          const Text('Tell us what happened.'),
          const SizedBox(height: 12),
          TextField(
            controller: reasonController,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Reason'),
          ),
        ],
      ),
      textCancel: 'Cancel',
      textConfirm: 'Submit',
      onConfirm: () async {
        final String reason = reasonController.text.trim();
        if (reason.isEmpty) return;
        Get.back();
        await controller.reportCurrent(reason);
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final Future<void> Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap == null ? null : () => onTap!(),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.16),
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: color, size: 30),
      ),
    );
  }
}
