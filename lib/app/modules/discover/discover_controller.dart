import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soul_matcher/app/data/models/app_user.dart';
import 'package:soul_matcher/app/data/models/swipe_action.dart';
import 'package:soul_matcher/app/data/repositories/auth_repository.dart';
import 'package:soul_matcher/app/data/repositories/discover_repository.dart';
import 'package:soul_matcher/app/data/repositories/user_repository.dart';

class DiscoverController extends GetxController {
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final UserRepository _userRepository = Get.find<UserRepository>();
  final DiscoverRepository _discoverRepository = Get.find<DiscoverRepository>();

  final TextEditingController searchController = TextEditingController();

  final Rxn<AppUser> currentUser = Rxn<AppUser>();
  final RxList<AppUser> candidates = <AppUser>[].obs;
  final Rx<DiscoverFilter> filter = const DiscoverFilter().obs;
  final RxBool isLoading = false.obs;
  final RxBool isSwiping = false.obs;
  int _candidateRequestSequence = 0;

  @override
  void onInit() {
    super.onInit();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final String? uid = _authRepository.currentUser?.uid;
    if (uid == null) return;
    final AppUser? user = await _userRepository.getUser(uid);
    currentUser.value = user;
    if (user != null) {
      await loadCandidates();
    }
  }

  Future<void> loadCandidates() async {
    final AppUser? me = currentUser.value;
    if (me == null) return;
    final int requestId = ++_candidateRequestSequence;
    final DiscoverFilter activeFilter = filter.value;

    isLoading.value = true;
    try {
      final List<AppUser> data = await _discoverRepository.getCandidates(
        currentUser: me,
        filter: activeFilter,
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

  Future<void> swipeLeft() => _swipeCurrent(SwipeType.pass);
  Future<void> swipeRight() => _swipeCurrent(SwipeType.like);
  Future<void> superLike() => _swipeCurrent(SwipeType.superLike);

  Future<void> _swipeCurrent(SwipeType type) async {
    final AppUser? me = currentUser.value;
    if (me == null || candidates.isEmpty || isSwiping.value) return;
    final AppUser target = candidates.first;
    final String targetName = target.displayName.isEmpty
        ? 'this profile'
        : target.displayName;

    isSwiping.value = true;
    try {
      await _discoverRepository.swipe(
        action: SwipeActionModel(
          byUserId: me.uid,
          targetUserId: target.uid,
          type: type,
        ),
      );

      if (type == SwipeType.like || type == SwipeType.superLike) {
        final bool mutual = await _discoverRepository.isMutualLike(
          myUid: me.uid,
          targetUid: target.uid,
        );
        if (mutual) {
          await _discoverRepository.createMatch(uidA: me.uid, uidB: target.uid);
          Get.snackbar(
            'It\'s a match',
            'You and ${target.displayName} liked each other.',
          );
        } else {
          Get.snackbar(
            type == SwipeType.superLike ? 'Super liked' : 'Liked',
            type == SwipeType.superLike
                ? 'You super liked $targetName.'
                : 'You liked $targetName.',
          );
        }
      } else {
        Get.snackbar('Passed', 'You passed on $targetName.');
      }
      candidates.removeAt(0);
    } catch (e) {
      Get.snackbar('Swipe failed', e.toString());
    } finally {
      isSwiping.value = false;
    }
  }

  Future<void> reportCurrent(String reason) async {
    final AppUser? me = currentUser.value;
    if (me == null || candidates.isEmpty) return;
    try {
      await _discoverRepository.reportUser(
        reporterUid: me.uid,
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
    final AppUser? me = currentUser.value;
    if (me == null || candidates.isEmpty) return;
    try {
      await _discoverRepository.blockUser(
        myUid: me.uid,
        targetUid: candidates.first.uid,
      );
      candidates.removeAt(0);
      Get.snackbar('Blocked', 'This user has been blocked.');
    } catch (e) {
      Get.snackbar('Block failed', e.toString());
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
