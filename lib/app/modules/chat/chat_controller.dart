import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soul_matcher/app/data/models/chat_message.dart';
import 'package:soul_matcher/app/data/repositories/auth_repository.dart';
import 'package:soul_matcher/app/data/repositories/chat_repository.dart';

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

  final TextEditingController messageController = TextEditingController();
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxBool isLoading = true.obs;

  StreamSubscription<List<ChatMessage>>? _subscription;

  String get myUid => _authRepository.currentUser?.uid ?? '';

  @override
  void onInit() {
    super.onInit();
    if (matchId.isEmpty || myUid.isEmpty) {
      isLoading.value = false;
      Get.snackbar('Chat error', 'Invalid chat session.');
      return;
    }
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
    messageController.clear();
    try {
      await _chatRepository.sendMessage(
        matchId: matchId,
        senderId: myUid,
        receiverId: otherUserId,
        text: text,
      );
    } catch (e) {
      Get.snackbar('Send failed', e.toString());
    }
  }

  @override
  void onClose() {
    _subscription?.cancel();
    messageController.dispose();
    super.onClose();
  }
}
