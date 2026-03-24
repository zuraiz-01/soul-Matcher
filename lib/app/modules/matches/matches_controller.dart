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
      final String name = matchUsers[otherId]?.displayName.toLowerCase() ?? '';
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
          return await _userRepository.getUser(uid);
        } catch (_) {
          return null;
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
    final AppUser? otherUser = matchUsers[otherId];
    Get.toNamed(
      AppRoutes.chat,
      arguments: <String, dynamic>{
        'matchId': match.id,
        'otherUserId': otherId,
        'otherUserName': otherUser?.displayName ?? 'Soul',
        'otherUserPhoto': otherUser?.photos.isNotEmpty == true
            ? otherUser!.photos.first
            : null,
      },
    );
  }

  int unreadFor(MatchModel match) {
    return match.unreadCount[_myUid] ?? 0;
  }

  Future<void> _loadFallbackMatchesFromMutualLikes() async {
    final List<String> mutualIds = await _discoverRepository.getMutualLikeUserIds(
      _myUid,
    );
    final List<MatchModel> fallback = mutualIds.map((String otherUid) {
      final List<String> users = <String>[_myUid, otherUid]..sort();
      return MatchModel(
        id: '${users[0]}_${users[1]}',
        users: users,
        unreadCount: <String, int>{_myUid: 0, otherUid: 0},
      );
    }).toList(growable: false);
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
