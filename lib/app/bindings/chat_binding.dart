import 'package:get/get.dart';
import 'package:soul_matcher/app/modules/chat/chat_controller.dart';
import 'package:soul_matcher/app/services/openrouter_service.dart';

class ChatBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<OpenRouterService>()) {
      Get.lazyPut<OpenRouterService>(() => OpenRouterService(), fenix: true);
    }

    final Map<String, dynamic> args =
        (Get.arguments as Map<String, dynamic>?) ?? <String, dynamic>{};

    Get.lazyPut<ChatController>(
      () => ChatController(
        matchId: args['matchId']?.toString() ?? '',
        otherUserId: args['otherUserId']?.toString() ?? '',
        otherUserName: args['otherUserName']?.toString() ?? 'Soul',
        otherUserPhoto: args['otherUserPhoto']?.toString(),
      ),
    );
  }
}
