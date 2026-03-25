import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:soul_matcher/app/data/models/app_user.dart';
import 'package:soul_matcher/app/data/models/user_activity_item.dart';
import 'package:soul_matcher/app/data/repositories/auth_repository.dart';
import 'package:soul_matcher/app/data/repositories/discover_repository.dart';
import 'package:soul_matcher/app/data/repositories/user_repository.dart';

enum ActivityListType { liked, superLiked, blocked, reported }

class ActivityListEntry {
  const ActivityListEntry({
    required this.uid,
    required this.displayName,
    required this.subtitle,
    this.photoUrl,
    this.createdAt,
  });

  final String uid;
  final String displayName;
  final String subtitle;
  final String? photoUrl;
  final DateTime? createdAt;
}

class ActivityController extends GetxController {
  ActivityController({required this.type});

  final ActivityListType type;

  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final DiscoverRepository _discoverRepository = Get.find<DiscoverRepository>();
  final UserRepository _userRepository = Get.find<UserRepository>();

  final RxBool isLoading = true.obs;
  final RxBool isRemoving = false.obs;
  final RxList<ActivityListEntry> entries = <ActivityListEntry>[].obs;

  String get title {
    switch (type) {
      case ActivityListType.liked:
        return 'Liked Users';
      case ActivityListType.superLiked:
        return 'Super Liked Users';
      case ActivityListType.blocked:
        return 'Blocked Users';
      case ActivityListType.reported:
        return 'Reported Users';
    }
  }

  String get emptyTitle {
    switch (type) {
      case ActivityListType.liked:
        return 'No likes yet';
      case ActivityListType.superLiked:
        return 'No super likes yet';
      case ActivityListType.blocked:
        return 'No blocked users';
      case ActivityListType.reported:
        return 'No reports yet';
    }
  }

  String get emptySubtitle {
    switch (type) {
      case ActivityListType.liked:
        return 'Profiles you like will appear here.';
      case ActivityListType.superLiked:
        return 'Profiles you super like will appear here.';
      case ActivityListType.blocked:
        return 'Users you block will appear here.';
      case ActivityListType.reported:
        return 'Users you report will appear here.';
    }
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    final String? uid = _authRepository.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      entries.clear();
      isLoading.value = false;
      return;
    }

    isLoading.value = true;
    try {
      final List<UserActivityItem> activityItems = await _loadActivityItems(
        uid,
      );

      final List<ActivityListEntry> resolved = await Future.wait(
        activityItems.map(_toEntry),
      );
      entries.assignAll(resolved);
    } catch (e) {
      Get.snackbar('Activity error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<UserActivityItem>> _loadActivityItems(String uid) {
    switch (type) {
      case ActivityListType.liked:
        return _discoverRepository.getLikedUsers(uid);
      case ActivityListType.superLiked:
        return _discoverRepository.getSuperLikedUsers(uid);
      case ActivityListType.blocked:
        return _discoverRepository.getBlockedUsers(uid);
      case ActivityListType.reported:
        return _discoverRepository.getReportedUsers(uid);
    }
  }

  Future<ActivityListEntry> _toEntry(UserActivityItem item) async {
    final AppUser? user = await _resolveUser(item.targetUserId);
    final String displayName = _displayName(user, item.targetUserId);
    final String subtitle = _subtitle(item);

    return ActivityListEntry(
      uid: item.targetUserId,
      displayName: displayName,
      subtitle: subtitle,
      photoUrl: user?.photos.isNotEmpty == true ? user!.photos.first : null,
      createdAt: item.createdAt,
    );
  }

  Future<AppUser?> _resolveUser(String uid) async {
    try {
      final AppUser? firestoreUser = await _userRepository.getUser(uid);
      if (firestoreUser != null &&
          !_looksLikeDemoLabel(firestoreUser.displayName)) {
        return firestoreUser;
      }
    } catch (_) {
      // Ignore and fall back to demo profile lookup.
    }
    return _discoverRepository.getDemoUserById(uid);
  }

  String _displayName(AppUser? user, String uid) {
    final String name = user?.displayName.trim() ?? '';
    if (name.isNotEmpty && !_looksLikeDemoLabel(name)) return name;
    final String demoName =
        _discoverRepository.getDemoUserById(uid)?.displayName.trim() ?? '';
    if (demoName.isNotEmpty) return demoName;
    if (uid.length <= 8) return 'User $uid';
    return 'User ${uid.substring(0, 8)}';
  }

  bool _looksLikeDemoLabel(String value) {
    final String normalized = value.trim().toLowerCase();
    return normalized.startsWith('demo_boy_') ||
        normalized.startsWith('demo_girl_');
  }

  String _subtitle(UserActivityItem item) {
    switch (type) {
      case ActivityListType.liked:
        return 'You liked this profile.';
      case ActivityListType.superLiked:
        return 'You super liked this profile.';
      case ActivityListType.blocked:
        return 'You blocked this user.';
      case ActivityListType.reported:
        final String reason = item.reason?.trim() ?? '';
        if (reason.isEmpty) return 'Report submitted.';
        return 'Reason: $reason';
    }
  }

  String get removeActionLabel {
    switch (type) {
      case ActivityListType.liked:
        return 'Remove from liked';
      case ActivityListType.superLiked:
        return 'Remove from super liked';
      case ActivityListType.blocked:
        return 'Unblock user';
      case ActivityListType.reported:
        return 'Remove from reported';
    }
  }

  Future<void> removeEntry(ActivityListEntry entry) async {
    final String? myUid = _authRepository.currentUser?.uid;
    if (myUid == null || myUid.isEmpty || isRemoving.value) return;

    isRemoving.value = true;
    bool chatDeleted = true;
    try {
      switch (type) {
        case ActivityListType.liked:
        case ActivityListType.superLiked:
          chatDeleted = await _discoverRepository
              .removeSwipeActionAndDeleteConversation(
                myUid: myUid,
                targetUid: entry.uid,
              );
          break;
        case ActivityListType.blocked:
          await _discoverRepository.unblockUser(
            myUid: myUid,
            targetUid: entry.uid,
          );
          break;
        case ActivityListType.reported:
          await _discoverRepository.dismissReportedUser(
            reporterUid: myUid,
            reportedUid: entry.uid,
          );
          break;
      }

      entries.removeWhere((ActivityListEntry item) => item.uid == entry.uid);
      Get.snackbar(
        'Updated',
        _removedMessage(entry.displayName, chatDeleted: chatDeleted),
      );
    } on FirebaseException catch (e) {
      final String detail = e.message?.trim().isNotEmpty == true
          ? e.message!.trim()
          : e.code;
      Get.snackbar('Unable to update', detail);
    } catch (e) {
      Get.snackbar('Unable to update', e.toString());
    } finally {
      isRemoving.value = false;
    }
  }

  String _removedMessage(String displayName, {bool chatDeleted = true}) {
    final String name = displayName.trim().isEmpty
        ? 'User'
        : displayName.trim();
    switch (type) {
      case ActivityListType.liked:
        return chatDeleted
            ? '$name removed from liked users and chat deleted.'
            : '$name removed from liked users.';
      case ActivityListType.superLiked:
        return chatDeleted
            ? '$name removed from super liked users and chat deleted.'
            : '$name removed from super liked users.';
      case ActivityListType.blocked:
        return '$name has been unblocked.';
      case ActivityListType.reported:
        return '$name removed from reported users.';
    }
  }
}
