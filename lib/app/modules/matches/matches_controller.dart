import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soul_matcher/app/data/models/app_user.dart';
import 'package:soul_matcher/app/data/models/match_model.dart';
import 'package:soul_matcher/app/data/repositories/auth_repository.dart';
import 'package:soul_matcher/app/data/repositories/chat_repository.dart';
import 'package:soul_matcher/app/data/repositories/discover_repository.dart';
import 'package:soul_matcher/app/data/repositories/user_repository.dart';
import 'package:soul_matcher/app/routes/app_routes.dart';

class MatchesController extends GetxController {
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final ChatRepository _chatRepository = Get.find<ChatRepository>();
  final DiscoverRepository _discoverRepository = Get.find<DiscoverRepository>();
  final UserRepository _userRepository = Get.find<UserRepository>();

  final TextEditingController searchController = TextEditingController();
  final RxList<MatchModel> matches = <MatchModel>[].obs;
  final RxMap<String, AppUser> matchUsers = <String, AppUser>{}.obs;
  final RxBool isLoading = true.obs;
  final RxString deletingMatchId = ''.obs;
  final RxString searchQuery = ''.obs;
  bool _permissionWarningShown = false;

  StreamSubscription<List<MatchModel>>? _subscription;
  String get _myUid => _authRepository.currentUser?.uid ?? '';
  String get myUid => _myUid;

  @override
  void onInit() {
    super.onInit();
    _listenMatches();
  }

  List<MatchModel> get filteredMatches {
    final String query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return matches;
    return matches.where((MatchModel match) {
      final String otherId = match.otherUserId(_myUid);
      final String name = _displayNameForUid(otherId).toLowerCase();
      return name.contains(query);
    }).toList();
  }

  void onSearchChanged(String value) {
    searchQuery.value = value;
  }

  Future<void> _listenMatches() async {
    if (_myUid.isEmpty) {
      isLoading.value = false;
      return;
    }
    _subscription = _chatRepository
        .streamMatches(_myUid)
        .listen(
          (List<MatchModel> data) async {
            try {
              final List<MatchModel> safeData = data
                  .where(
                    (MatchModel match) =>
                        match.users.isNotEmpty && match.users.contains(_myUid),
                  )
                  .toList(growable: false);
              matches.assignAll(safeData);
              await _resolveUsers(safeData);
            } catch (e) {
              Get.snackbar('Matches error', e.toString());
            } finally {
              isLoading.value = false;
            }
          },
          onError: (Object error) async {
            if (error is FirebaseException &&
                error.code == 'permission-denied') {
              await _loadFallbackMatchesFromMutualLikes();
              if (!_permissionWarningShown) {
                _permissionWarningShown = true;
                Get.snackbar(
                  'Matches Limited',
                  'Could not read matches due to Firestore permissions. Showing mutual-like fallback.',
                );
              }
              isLoading.value = false;
              return;
            }
            isLoading.value = false;
            Get.snackbar('Matches error', error.toString());
          },
        );
  }

  Future<void> _resolveUsers(List<MatchModel> data) async {
    final Iterable<String> ids = data.map(
      (MatchModel m) => m.otherUserId(_myUid),
    );
    final List<String> missing = ids
        .where((String id) => id.isNotEmpty && !matchUsers.containsKey(id))
        .toSet()
        .toList(growable: false);
    if (missing.isEmpty) return;

    final List<AppUser?> resolved = await Future.wait<AppUser?>(
      missing.map((String uid) async {
        try {
          final AppUser? firestoreUser = await _userRepository.getUser(uid);
          if (firestoreUser != null) {
            if (_looksLikeDemoLabel(firestoreUser.displayName)) {
              final AppUser? demoUser = _discoverRepository.getDemoUserById(
                uid,
              );
              if (demoUser != null) {
                return demoUser;
              }
            }
            return firestoreUser;
          }
          return _discoverRepository.getDemoUserById(uid);
        } catch (_) {
          return _discoverRepository.getDemoUserById(uid);
        }
      }),
    );
    for (int i = 0; i < missing.length; i++) {
      final AppUser? user = resolved[i];
      if (user != null) {
        matchUsers[missing[i]] = user;
      }
    }
  }

  void openChat(MatchModel match) {
    final String otherId = match.otherUserId(_myUid);
    if (otherId.isEmpty) {
      Get.snackbar(
        'Chat unavailable',
        'This match record looks incomplete. Please refresh matches.',
      );
      return;
    }
    final AppUser? otherUser = _resolvedUserForUid(otherId);
    final String resolvedName = _displayNameForUid(otherId);
    Get.toNamed(
      AppRoutes.chat,
      arguments: <String, dynamic>{
        'matchId': match.id,
        'otherUserId': otherId,
        'otherUserName': resolvedName,
        'otherUserPhoto': otherUser?.photos.isNotEmpty == true
            ? otherUser!.photos.first
            : null,
      },
    );
  }

  String displayNameForMatch(MatchModel match) {
    final String otherId = match.otherUserId(_myUid);
    return _displayNameForUid(otherId);
  }

  String? photoForMatch(MatchModel match) {
    final String otherId = match.otherUserId(_myUid);
    final AppUser? otherUser = _resolvedUserForUid(otherId);
    if (otherUser == null || otherUser.photos.isEmpty) {
      return null;
    }
    return otherUser.photos.first;
  }

  AppUser? _resolvedUserForUid(String uid) {
    return matchUsers[uid] ?? _discoverRepository.getDemoUserById(uid);
  }

  String _displayNameForUid(String uid) {
    final AppUser? user = _resolvedUserForUid(uid);
    final String displayName = user?.displayName.trim() ?? '';
    if (displayName.isNotEmpty) {
      return displayName;
    }
    return _fallbackName(uid);
  }

  String _fallbackName(String uid) {
    final AppUser? demoUser = _discoverRepository.getDemoUserById(uid);
    if (demoUser != null && demoUser.displayName.trim().isNotEmpty) {
      return demoUser.displayName.trim();
    }
    if (uid.isEmpty) return 'Soul User';
    if (uid.length <= 8) return 'User $uid';
    return 'User ${uid.substring(0, 8)}';
  }

  bool _looksLikeDemoLabel(String value) {
    final String normalized = value.trim().toLowerCase();
    return normalized.startsWith('demo_boy_') ||
        normalized.startsWith('demo_girl_');
  }

  int unreadFor(MatchModel match) {
    return match.unreadCount[_myUid] ?? 0;
  }

  bool isDeletingMatch(String matchId) {
    return deletingMatchId.value == matchId;
  }

  Future<void> clearChat(MatchModel match) async {
    if (_myUid.isEmpty) return;
    if (deletingMatchId.value.isNotEmpty) return;

    deletingMatchId.value = match.id;
    try {
      final bool cleared = await _chatRepository.clearChat(
        matchId: match.id,
        users: match.users,
      );
      if (!cleared) {
        Get.snackbar(
          'Delete not allowed',
          'Firestore permissions do not allow deleting this chat.',
        );
        return;
      }

      _applyLocalClear(match.id);
      Get.snackbar('Chat cleared', 'All messages deleted successfully.');
    } on FirebaseException catch (e) {
      Get.snackbar('Delete failed', e.message ?? e.code);
    } catch (_) {
      Get.snackbar('Delete failed', 'Could not clear this chat.');
    } finally {
      deletingMatchId.value = '';
    }
  }

  void _applyLocalClear(String matchId) {
    final int index = matches.indexWhere((MatchModel item) => item.id == matchId);
    if (index == -1) return;

    final MatchModel current = matches[index];
    final Map<String, int> resetUnread = <String, int>{
      for (final String uid in current.users) uid: 0,
    };
    matches[index] = MatchModel(
      id: current.id,
      users: current.users,
      createdAt: current.createdAt,
      lastMessage: null,
      lastMessageAt: null,
      unreadCount: resetUnread,
    );
  }

  Future<void> _loadFallbackMatchesFromMutualLikes() async {
    final List<String> mutualIds = await _discoverRepository
        .getMutualLikeUserIds(_myUid);
    final List<MatchModel> fallback = mutualIds
        .map((String otherUid) {
          final List<String> users = <String>[_myUid, otherUid]..sort();
          return MatchModel(
            id: '${users[0]}_${users[1]}',
            users: users,
            unreadCount: <String, int>{_myUid: 0, otherUid: 0},
          );
        })
        .toList(growable: false);
    matches.assignAll(fallback);
    await _resolveUsers(fallback);
  }

  @override
  void onClose() {
    _subscription?.cancel();
    searchController.dispose();
    super.onClose();
  }
}
