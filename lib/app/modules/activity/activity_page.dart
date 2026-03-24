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
