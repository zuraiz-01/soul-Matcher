import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:soul_matcher/app/data/models/app_user.dart';
import 'package:soul_matcher/app/data/models/match_model.dart';
import 'package:soul_matcher/app/data/models/swipe_action.dart';
import 'package:soul_matcher/app/data/repositories/auth_repository.dart';
import 'package:soul_matcher/app/data/repositories/chat_repository.dart';
import 'package:soul_matcher/app/data/repositories/discover_repository.dart';
import 'package:soul_matcher/app/data/repositories/user_repository.dart';
import 'package:soul_matcher/app/routes/app_routes.dart';

class DiscoverController extends GetxController {
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final UserRepository _userRepository = Get.find<UserRepository>();
  final DiscoverRepository _discoverRepository = Get.find<DiscoverRepository>();
  final ChatRepository _chatRepository = Get.find<ChatRepository>();

  final TextEditingController searchController = TextEditingController();

  final Rxn<AppUser> currentUser = Rxn<AppUser>();
  final RxList<AppUser> candidates = <AppUser>[].obs;
  final Rx<DiscoverFilter> filter = const DiscoverFilter().obs;
  final RxBool isLoading = false.obs;
  final RxBool isSwiping = false.obs;
  int _candidateRequestSequence = 0;

  String? get _signedInUid => _authRepository.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final String? uid = _signedInUid;
    if (uid == null) return;
    final AppUser? user = await _userRepository.getUser(uid);
    currentUser.value = user?.copyWith(uid: uid);
    if (user != null) {
      await loadCandidates();
    }
  }

  Future<void> loadCandidates({bool includePreviouslySwiped = false}) async {
    final AppUser? me = currentUser.value;
    final String? uid = _signedInUid;
    if (me == null || uid == null) return;
    final AppUser normalizedCurrentUser = me.copyWith(uid: uid);
    final int requestId = ++_candidateRequestSequence;
    final DiscoverFilter activeFilter = filter.value;

    isLoading.value = true;
    try {
      final List<AppUser> data = await _discoverRepository.getCandidates(
        currentUser: normalizedCurrentUser,
        filter: activeFilter,
        includePreviouslySwiped: includePreviouslySwiped,
      );
      if (requestId != _candidateRequestSequence) return;
      candidates.assignAll(data);
    } catch (e) {
      if (requestId != _candidateRequestSequence) return;
      Get.snackbar('Discover error', e.toString());
    } finally {
      if (requestId == _candidateRequestSequence) {
        isLoading.value = false;
      }
    }
  }

  Future<void> applyFilter(DiscoverFilter newFilter) async {
    filter.value = newFilter;
    await loadCandidates();
  }

  Future<void> onSearchChanged(String query) async {
    filter.value = filter.value.copyWith(searchText: query);
    await loadCandidates();
  }

  Future<void> refreshCandidates() async {
    await loadCandidates(includePreviouslySwiped: true);
  }

  Future<void> swipeLeft() => _swipeCurrent(SwipeType.pass);
  Future<void> swipeRight() => _swipeCurrent(SwipeType.like);
  Future<void> superLike() => _swipeCurrent(SwipeType.superLike);

  Future<void> _swipeCurrent(SwipeType type) async {
    if (candidates.isEmpty) return;
    await swipeOnUser(candidates.first, type: type);
  }

  Future<void> dismissAndSwipe({
    required AppUser target,
    required SwipeType type,
  }) async {
    final int index = candidates.indexWhere(
      (AppUser user) => user.uid == target.uid,
    );
    if (index == -1) return;

    // Dismissible requires immediate removal from tree once dismissed.
    candidates.removeAt(index);

    final bool didSwipe = await swipeOnUser(
      target,
      type: type,
      removeFromDiscover: false,
    );

    // If Firestore action fails, restore the removed profile to avoid data loss.
    if (!didSwipe &&
        candidates.every((AppUser user) => user.uid != target.uid)) {
      final int insertIndex = index.clamp(0, candidates.length);
      candidates.insert(insertIndex, target);
    }
  }

  Future<void> reportCurrent(String reason) async {
    final String? myUid = _signedInUid;
    if (myUid == null || candidates.isEmpty) return;
    try {
      await _discoverRepository.reportUser(
        reporterUid: myUid,
        reportedUid: candidates.first.uid,
        reason: reason,
      );
      Get.snackbar(
        'Report submitted',
        'Thanks for helping keep SoulMatch safe.',
      );
    } catch (e) {
      Get.snackbar('Report failed', e.toString());
    }
  }

  Future<void> blockCurrent() async {
    final String? myUid = _signedInUid;
    if (myUid == null || candidates.isEmpty) return;
    try {
      await _discoverRepository.blockUser(
        myUid: myUid,
        targetUid: candidates.first.uid,
      );
      candidates.removeAt(0);
      Get.snackbar('Blocked', 'This user has been blocked.');
    } catch (e) {
      Get.snackbar('Block failed', e.toString());
    }
  }

  void openProfile(AppUser user) {
    Get.toNamed(
      AppRoutes.userProfile,
      arguments: <String, dynamic>{'user': user},
    );
  }

  Future<bool> swipeOnUser(
    AppUser target, {
    required SwipeType type,
    bool removeFromDiscover = true,
    bool showFeedback = true,
  }) async {
    final String? myUid = _signedInUid;
    if (myUid == null || isSwiping.value) return false;
    final String targetName = target.displayName.isEmpty
        ? 'this profile'
        : target.displayName;

    isSwiping.value = true;
    try {
      await _discoverRepository.swipe(
        action: SwipeActionModel(
          byUserId: myUid,
          targetUserId: target.uid,
          type: type,
        ),
      );

      bool mutual = false;
      if (type == SwipeType.like || type == SwipeType.superLike) {
        mutual = await _discoverRepository.isMutualLike(
          myUid: myUid,
          targetUid: target.uid,
        );
        if (mutual) {
          await _discoverRepository.createMatch(uidA: myUid, uidB: target.uid);
          if (showFeedback) {
            Get.snackbar(
              'It\'s a match',
              'You and ${target.displayName} liked each other.',
            );
          }
        } else {
          if (showFeedback) {
            Get.snackbar(
              type == SwipeType.superLike ? 'Super liked' : 'Liked',
              type == SwipeType.superLike
                  ? 'You super liked $targetName.'
                  : 'You liked $targetName.',
            );
          }
        }
      } else {
        if (showFeedback) {
          Get.snackbar('Passed', 'You passed on $targetName.');
        }
      }

      if (removeFromDiscover) {
        candidates.removeWhere((AppUser user) => user.uid == target.uid);
      }
      return true;
    } catch (e) {
      if (showFeedback) {
        Get.snackbar('Swipe failed', e.toString());
      }
      return false;
    } finally {
      isSwiping.value = false;
    }
  }

  Future<void> openChatWithUser(AppUser targetUser) async {
    final String? myUid = _signedInUid;
    if (myUid == null) {
      Get.snackbar('Chat unavailable', 'Please login again.');
      return;
    }

    final String matchId = _buildMatchId(myUid, targetUser.uid);
    try {
      final bool isMutual = await _discoverRepository.isMutualLike(
        myUid: myUid,
        targetUid: targetUser.uid,
      );
      if (!isMutual) {
        Get.snackbar(
          'Chat unavailable',
          'Match first with ${targetUser.displayName} to start chat.',
        );
        return;
      }

      MatchModel? match;
      try {
        match = await _chatRepository.getMatchById(matchId);
      } on FirebaseException catch (e) {
        // Reading a non-existing match doc can still fail in some rule
        // configurations. If users are mutually liked, create/open match.
        if (e.code != 'permission-denied') rethrow;
      }

      match ??= await _discoverRepository.createMatch(
        uidA: myUid,
        uidB: targetUser.uid,
      );

      Get.toNamed(
        AppRoutes.chat,
        arguments: <String, dynamic>{
          'matchId': match.id,
          'otherUserId': targetUser.uid,
          'otherUserName': targetUser.displayName.isEmpty
              ? 'Soul'
              : targetUser.displayName,
          'otherUserPhoto': targetUser.photos.isNotEmpty
              ? targetUser.photos.first
              : null,
        },
      );
    } on FirebaseException catch (e) {
      Get.snackbar('Chat error', e.message ?? e.code);
    } catch (e) {
      Get.snackbar('Chat error', e.toString());
    }
  }

  String _buildMatchId(String uidA, String uidB) {
    final List<String> users = <String>[uidA, uidB]..sort();
    return '${users[0]}_${users[1]}';
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
