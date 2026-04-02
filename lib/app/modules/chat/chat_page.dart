import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soul_matcher/app/modules/chat/chat_controller.dart';
import 'package:soul_matcher/app/modules/chat/widgets/chat_bubble.dart';
import 'package:soul_matcher/app/widgets/app_loader.dart';
import 'package:soul_matcher/app/widgets/premium_background.dart';

class ChatPage extends GetView<ChatController> {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: <Widget>[
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white24,
              child: _ChatAvatarImage(photoUrl: controller.otherUserPhoto),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: controller.openOtherUserProfile,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    controller.otherUserName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      extendBodyBehindAppBar: true,
      body: PremiumBackground(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value &&
                      controller.messages.isEmpty) {
                    return const AppLoader();
                  }
                  final bool showTyping =
                      controller.canSeeTypingIndicator &&
                      controller.isDemoChat &&
                      controller.isGeneratingDemoReply.value;
                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                    itemCount:
                        controller.messages.length + (showTyping ? 1 : 0),
                    itemBuilder: (_, int index) {
                      if (showTyping && index == 0) {
                        return const TypingBubble();
                      }
                      final int messageIndex = showTyping ? index - 1 : index;
                      final message = controller.messages[messageIndex];
                      return ChatBubble(
                        message: message,
                        isMine: message.senderId == controller.myUid,
                      );
                    },
                  );
                }),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                child: PremiumGlassCard(
                  padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
                  child: Row(
                    children: <Widget>[
                      IconButton(
                        tooltip: 'Image message',
                        onPressed: controller.onImageMessageTap,
                        icon: const Icon(Icons.image_outlined),
                      ),
                      IconButton(
                        tooltip: 'Audio message',
                        onPressed: controller.onAudioMessageTap,
                        icon: const Icon(Icons.mic_none_rounded),
                      ),
                      Expanded(
                        child: TextField(
                          controller: controller.messageController,
                          decoration: const InputDecoration(
                            hintText: 'Type a message...',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton.filled(
                        onPressed: controller.sendMessage,
                        icon: const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatAvatarImage extends StatelessWidget {
  const _ChatAvatarImage({required this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    if (photoUrl == null || photoUrl!.trim().isEmpty) {
      return const Icon(Icons.person);
    }

    return ClipOval(
      child: Image.network(
        photoUrl!,
        width: 36,
        height: 36,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.low,
        cacheWidth: 120,
        errorBuilder: (_, _, _) => const Icon(Icons.person),
      ),
    );
  }
}
