import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:soul_matcher/app/modules/activity/activity_controller.dart';
import 'package:soul_matcher/app/widgets/app_loader.dart';
import 'package:soul_matcher/app/widgets/empty_state.dart';
import 'package:soul_matcher/app/widgets/premium_background.dart';

class ActivityPage extends GetView<ActivityController> {
  const ActivityPage({required this.type, super.key});

  final ActivityListType type;

  @override
  String? get tag => type.name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text(controller.title)),
      body: PremiumBackground(
        child: SafeArea(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const AppLoader();
            }

            if (controller.entries.isEmpty) {
              return EmptyState(
                title: controller.emptyTitle,
                subtitle: controller.emptySubtitle,
                icon: Icons.inbox_rounded,
              );
            }

            return RefreshIndicator(
              onRefresh: controller.load,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                itemCount: controller.entries.length,
                itemBuilder: (_, int index) {
                  final entry = controller.entries[index];
                  return Card(
                    child: ListTile(
                      onTap: () => _showEntryActionSheet(context, entry),
                      leading: CircleAvatar(
                        radius: 23,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        child: _ActivityAvatarImage(photoUrl: entry.photoUrl),
                      ),
                      title: Text(entry.displayName),
                      subtitle: Text(
                        entry.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: entry.createdAt == null
                          ? null
                          : Text(
                              DateFormat('dd MMM').format(entry.createdAt!),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                      onLongPress: () => _showEntryActionSheet(context, entry),
                    ),
                  );
                },
              ),
            );
          }),
        ),
      ),
    );
  }

  Future<void> _showEntryActionSheet(
    BuildContext context,
    ActivityListEntry entry,
  ) async {
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
                      entry.displayName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.subtitle,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: controller.isRemoving.value
                          ? null
                          : () async {
                              Navigator.of(context).pop();
                              await controller.removeEntry(entry);
                            },
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                      label: Text(controller.removeActionLabel),
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

class _ActivityAvatarImage extends StatelessWidget {
  const _ActivityAvatarImage({required this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    if (photoUrl == null || photoUrl!.trim().isEmpty) {
      return const Icon(Icons.person_outline_rounded);
    }

    return ClipOval(
      child: Image.network(
        photoUrl!,
        width: 46,
        height: 46,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Icon(Icons.person_outline_rounded),
      ),
    );
  }
}
