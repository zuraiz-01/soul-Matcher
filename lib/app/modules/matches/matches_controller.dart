import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soul_matcher/app/data/models/app_user.dart';
import 'package:soul_matcher/app/data/models/match_model.dart';
import 'package:soul_matcher/app/data/repositories/auth_repository.dart';
import 'package:soul_matcher/app/data/repositories/chat_repository.dart';
import 'package:soul_matcher/app/data/repositories/user_repository.dart';
import 'package:soul_matcher/app/routes/app_routes.dart';

class MatchesController extends GetxController {
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final ChatRepository _chatRepository = Get.find<ChatRepository>();
  final UserRepository _userRepository = Get.find<UserRepository>();

  final TextEditingController searchController = TextEditingController();
  final RxList<MatchModel> matches = <MatchModel>[].obs;
  final RxMap<String, AppUser> matchUsers = <String, AppUser>{}.obs;
  final RxBool isLoading = true.obs;
  final RxString searchQuery = ''.obs;

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
    if (_myUid.isEmpty) return;
    _subscription = _chatRepository
        .streamMatches(_myUid)
        .listen(
          (List<MatchModel> data) async {
            matches.assignAll(data);
            await _resolveUsers(data);
            isLoading.value = false;
          },
          onError: (Object error) {
            isLoading.value = false;
            Get.snackbar('Matches error', error.toString());
          },
        );
  }

  Future<void> _resolveUsers(List<MatchModel> data) async {
    final Iterable<String> ids = data.map(
      (MatchModel m) => m.otherUserId(_myUid),
    );
    final Iterable<String> missing = ids.where(
      (String id) => !matchUsers.containsKey(id),
    );
    for (final String uid in missing) {
      if (uid.isEmpty) continue;
      final AppUser? user = await _userRepository.getUser(uid);
      if (user != null) {
        matchUsers[uid] = user;
      }
    }
  }

  void openChat(MatchModel match) {
    final String otherId = match.otherUserId(_myUid);
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

  @override
  void onClose() {
    _subscription?.cancel();
    searchController.dispose();
    super.onClose();
  }
}
