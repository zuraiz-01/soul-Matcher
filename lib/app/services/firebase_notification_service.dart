import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:soul_matcher/app/data/repositories/auth_repository.dart';
import 'package:soul_matcher/app/data/repositories/user_repository.dart';

class FirebaseNotificationService {
  FirebaseNotificationService({
    required UserRepository userRepository,
    required AuthRepository authRepository,
  }) : _userRepository = userRepository,
       _authRepository = authRepository;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final UserRepository _userRepository;
  final AuthRepository _authRepository;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: true,
    );

    final String? token = await _messaging.getToken();
    await _saveToken(token);

    _messaging.onTokenRefresh.listen(_saveToken);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final RemoteNotification? notification = message.notification;
      if (notification != null) {
        Get.snackbar(
          notification.title ?? 'SoulMatch',
          notification.body ?? 'You have a new update',
          snackPosition: SnackPosition.TOP,
        );
      }
    });
  }

  Future<void> _saveToken(String? token) async {
    final String? uid = _authRepository.currentUser?.uid;
    if (uid == null || token == null || token.isEmpty) return;
    await _userRepository.updateFcmToken(uid: uid, token: token);
  }
}
