import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soul_matcher/app/core/subscription/subscription_plan.dart';
import 'package:soul_matcher/app/data/models/app_user.dart';
import 'package:soul_matcher/app/data/models/chat_message.dart';
import 'package:soul_matcher/app/data/repositories/auth_repository.dart';
import 'package:soul_matcher/app/data/repositories/chat_repository.dart';
import 'package:soul_matcher/app/data/repositories/discover_repository.dart';
import 'package:soul_matcher/app/data/repositories/user_repository.dart';
import 'package:soul_matcher/app/routes/app_routes.dart';
import 'package:soul_matcher/app/services/openrouter_service.dart';
import 'package:soul_matcher/app/services/subscription_service.dart';

class ChatController extends GetxController {
  ChatController({
    required this.matchId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserPhoto,
  });

  final String matchId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhoto;

  final ChatRepository _chatRepository = Get.find<ChatRepository>();
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final UserRepository _userRepository = Get.find<UserRepository>();
  final DiscoverRepository _discoverRepository = Get.find<DiscoverRepository>();
  final OpenRouterService _openRouterService = Get.find<OpenRouterService>();
  final SubscriptionService _subscriptionService =
      Get.find<SubscriptionService>();

  final TextEditingController messageController = TextEditingController();
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isGeneratingDemoReply = false.obs;
  final Rx<SubscriptionPlan> currentPlan = SubscriptionPlan.free.obs;

  StreamSubscription<List<ChatMessage>>? _subscription;
  StreamSubscription<SubscriptionPlan>? _planSubscription;

  String get myUid => _authRepository.currentUser?.uid ?? '';
  bool get isDemoChat => _isDemoUserUid(otherUserId);
  bool get canSeeTypingIndicator => currentPlan.value.canSeeTypingIndicator;

  Future<void> openOtherUserProfile() async {
    try {
      final AppUser? firestoreUser = await _userRepository.getUser(otherUserId);
      final AppUser? demoUser = _discoverRepository.getDemoUserById(
        otherUserId,
      );
      final AppUser profile =
          firestoreUser ??
          demoUser ??
          AppUser(
            uid: otherUserId,
            email: '',
            displayName: otherUserName,
            photos: otherUserPhoto == null
                ? const <String>[]
                : <String>[otherUserPhoto!],
            profileCompleted: true,
          );

      Get.toNamed(
        AppRoutes.userProfile,
        arguments: <String, dynamic>{'user': profile},
      );
    } catch (e) {
      Get.snackbar('Profile unavailable', e.toString());
    }
  }

  void onImageMessageTap() {
    if (!currentPlan.value.canSendImages) {
      Get.snackbar(
        'Upgrade required',
        'Image sharing Gold/Platinum plan mein available hai. Plan upgrade karein.',
      );
      return;
    }

    Get.snackbar(
      'Coming soon',
      'Image message sending feature jaldi available hogi.',
    );
  }

  void onAudioMessageTap() {
    if (!currentPlan.value.canSendAudio) {
      Get.snackbar(
        'Upgrade required',
        'Audio messages sirf Platinum plan mein available hain. Plan upgrade karein.',
      );
      return;
    }

    Get.snackbar(
      'Coming soon',
      'Audio message sending feature jaldi available hogi.',
    );
  }

  @override
  void onInit() {
    super.onInit();
    if (matchId.isEmpty || myUid.isEmpty) {
      isLoading.value = false;
      Get.snackbar('Chat error', 'Invalid chat session.');
      return;
    }

    _planSubscription = _subscriptionService.watchCurrentPlan().listen((
      SubscriptionPlan plan,
    ) {
      currentPlan.value = plan;
    });
    _listenMessages();
  }

  Future<void> _listenMessages() async {
    _subscription = _chatRepository
        .streamMessages(matchId)
        .listen(
          (List<ChatMessage> data) async {
            messages.assignAll(data);
            isLoading.value = false;
            await _chatRepository.markAsRead(matchId: matchId, uid: myUid);
          },
          onError: (Object error) {
            isLoading.value = false;
            Get.snackbar('Chat error', error.toString());
          },
        );
  }

  Future<void> sendMessage() async {
    final String text = messageController.text.trim();
    if (text.isEmpty) return;

    final SubscriptionGateResult gate = await _subscriptionService
        .reserveMessageQuota(matchId: matchId);
    if (!gate.allowed) {
      Get.snackbar(
        'Message limit reached',
        gate.message ?? 'Upgrade your plan to continue chatting.',
      );
      return;
    }

    messageController.clear();
    try {
      await _chatRepository.sendMessage(
        matchId: matchId,
        senderId: myUid,
        receiverId: otherUserId,
        text: text,
      );

      if (_isDemoUserUid(otherUserId)) {
        unawaited(_sendDemoAutoReply(userMessage: text));
      }
    } catch (e) {
      await _subscriptionService.releaseMessageQuota(matchId: matchId);
      Get.snackbar('Send failed', e.toString());
    }
  }

  Future<void> _sendDemoAutoReply({required String userMessage}) async {
    if (isGeneratingDemoReply.value) return;
    isGeneratingDemoReply.value = true;

    try {
      final String reply =
          await _openRouterService.generateDemoReply(
            personaName: otherUserName,
            userMessage: userMessage,
          ) ??
          _fallbackDemoReply(userMessage);

      if (reply.trim().isEmpty) return;

      await Future<void>.delayed(const Duration(milliseconds: 900));
      await _chatRepository.sendMessage(
        matchId: matchId,
        senderId: otherUserId,
        receiverId: myUid,
        text: reply.trim(),
      );
    } catch (_) {
      Get.snackbar('Demo reply failed', 'Could not send demo auto reply.');
    } finally {
      isGeneratingDemoReply.value = false;
    }
  }

  bool _isDemoUserUid(String uid) {
    return uid.startsWith('demo_boy_') || uid.startsWith('demo_girl_');
  }

  String _fallbackDemoReply(String userMessage) {
    final String message = userMessage.trim();
    if (message.endsWith('?')) {
      return 'Good question. Tell me a bit more about what you are looking for?';
    }
    return 'Nice! I like your vibe. What should we plan next?';
  }

  @override
  void onClose() {
    _subscription?.cancel();
    _planSubscription?.cancel();
    messageController.dispose();
    super.onClose();
  }
}
