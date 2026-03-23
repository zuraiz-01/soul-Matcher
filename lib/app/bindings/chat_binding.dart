import 'package:get/get.dart';
import 'package:soul_matcher/app/modules/chat/chat_controller.dart';

class ChatBinding extends Bindings {
  @override
  void dependencies() {
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
