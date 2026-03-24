import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soul_matcher/app/data/models/swipe_action.dart';
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
        onAction: controller.refreshCandidates,
      );
    }

    final user = controller.candidates.first;
    return Dismissible(
      key: ValueKey<String>('discover_${user.uid}'),
      direction: DismissDirection.horizontal,
      onDismissed: (DismissDirection direction) {
        final SwipeType swipeType = direction == DismissDirection.startToEnd
            ? SwipeType.like
            : SwipeType.pass;
        controller.dismissAndSwipe(target: user, type: swipeType);
      },
      child: GestureDetector(
        onTap: () => controller.openProfile(user),
        child: DiscoverCard(
          user: user,
          onMorePressed: () => _showMoreActionSheet(context),
        ),
      ),
    );
  }

  Future<void> _showMoreActionSheet(BuildContext context) async {
    final _SafetyAction? action = await showModalBottomSheet<_SafetyAction>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext modalContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: _SheetCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const _BottomSheetHandle(),
                Text(
                  'Safety actions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Take action on this profile.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                _SheetActionTile(
                  icon: Icons.flag_outlined,
                  iconColor: const Color(0xFFF6A23A),
                  title: 'Report user',
                  subtitle: 'Tell us why this profile looks suspicious',
                  onTap: () =>
                      Navigator.of(modalContext).pop(_SafetyAction.report),
                ),
                const SizedBox(height: 8),
                _SheetActionTile(
                  icon: Icons.block_outlined,
                  iconColor: const Color(0xFFFF6B6B),
                  title: 'Block user',
                  subtitle: 'They will no longer appear in Discover',
                  onTap: () =>
                      Navigator.of(modalContext).pop(_SafetyAction.block),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (action == null || !context.mounted) return;
    if (action == _SafetyAction.report) {
      await _showReportBottomSheet(context);
      return;
    }
    if (action == _SafetyAction.block) {
      await controller.blockCurrent();
    }
  }

  Future<void> _showReportBottomSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReportBottomSheet(onSubmit: controller.reportCurrent),
    );
  }
}

enum _SafetyAction { report, block }

class _ReportBottomSheet extends StatefulWidget {
  const _ReportBottomSheet({required this.onSubmit});

  final Future<void> Function(String reason) onSubmit;

  @override
  State<_ReportBottomSheet> createState() => _ReportBottomSheetState();
}

class _ReportBottomSheetState extends State<_ReportBottomSheet> {
  static const List<String> _quickReasons = <String>[
    'Fake profile',
    'Spam behavior',
    'Inappropriate content',
    'Harassment',
    'Scam attempt',
  ];

  final TextEditingController _reasonController = TextEditingController();
  String? _selectedReason;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      Get.snackbar('Validation', 'Please add a reason before submitting.');
      return;
    }
    Navigator.of(context).pop();
    await widget.onSubmit(reason);
  }

  void _onReasonSelected(bool selected, String reason) {
    setState(() {
      _selectedReason = selected ? reason : null;
      if (selected && _reasonController.text.trim().isEmpty) {
        _reasonController.text = reason;
        _reasonController.selection = TextSelection.fromPosition(
          TextPosition(offset: _reasonController.text.length),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          12,
          0,
          12,
          MediaQuery.of(context).viewInsets.bottom + 12,
        ),
        child: _SheetCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const _BottomSheetHandle(),
              Text(
                'Report user',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'This report is anonymous. Help us understand what happened.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickReasons
                    .map((String reason) {
                      final bool isSelected = _selectedReason == reason;
                      return ChoiceChip(
                        label: Text(reason),
                        selected: isSelected,
                        onSelected: (bool selected) =>
                            _onReasonSelected(selected, reason),
                      );
                    })
                    .toList(growable: false),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _reasonController,
                maxLines: 4,
                maxLength: 180,
                decoration: const InputDecoration(
                  hintText: 'Write a short reason...',
                  prefixIcon: Icon(Icons.edit_note_rounded),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _submit,
                      child: const Text('Submit Report'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomSheetHandle extends StatelessWidget {
  const _BottomSheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 42,
        height: 5,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white30,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}

class _SheetCard extends StatelessWidget {
  const _SheetCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        child: child,
      ),
    );
  }
}

class _SheetActionTile extends StatelessWidget {
  const _SheetActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withValues(alpha: 0.16),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white54),
          ],
        ),
      ),
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
