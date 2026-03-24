import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soul_matcher/app/data/models/app_user.dart';
import 'package:soul_matcher/app/data/repositories/auth_repository.dart';
import 'package:soul_matcher/app/data/repositories/user_repository.dart';
import 'package:soul_matcher/app/routes/app_routes.dart';

class AuthController extends GetxController {
  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final UserRepository _userRepository = Get.find<UserRepository>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final RxBool isLoginMode = true.obs;
  final RxBool isLoading = false.obs;
  final RxBool isPasswordObscured = true.obs;
  final RxBool isConfirmPasswordObscured = true.obs;

  void toggleMode() {
    isLoginMode.value = !isLoginMode.value;
    isPasswordObscured.value = true;
    isConfirmPasswordObscured.value = true;
  }

  void togglePasswordVisibility() {
    isPasswordObscured.value = !isPasswordObscured.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordObscured.value = !isConfirmPasswordObscured.value;
  }

  Future<void> submitEmailAuth() async {
    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      Get.snackbar('Validation', 'Email and password are required.');
      return;
    }
    if (!GetUtils.isEmail(email)) {
      Get.snackbar('Validation', 'Enter a valid email address.');
      return;
    }
    if (password.length < 6) {
      Get.snackbar('Validation', 'Password must be at least 6 characters.');
      return;
    }
    if (!isLoginMode.value &&
        password != confirmPasswordController.text.trim()) {
      Get.snackbar('Validation', 'Passwords do not match.');
      return;
    }

    isLoading.value = true;
    try {
      final UserCredential credential;
      if (isLoginMode.value) {
        credential = await _authRepository.signInWithEmail(
          email: email,
          password: password,
        );
      } else {
        credential = await _authRepository.signUpWithEmail(
          email: email,
          password: password,
        );
      }
      await _userRepository.createUserIfNotExists(credential.user!);
      await _routeAfterAuth(credential.user!.uid);
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Auth failed', _friendlyAuthMessage(e));
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        Get.snackbar(
          'Signup failed',
          'Firestore permission issue. Please deploy latest rules and try again.',
        );
      } else {
        Get.snackbar('Auth failed', e.message ?? e.code);
      }
    } catch (e) {
      Get.snackbar('Auth failed', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signInWithGoogle() async {
    isLoading.value = true;
    try {
      final UserCredential? credential = await _authRepository
          .signInWithGoogle();
      final User? user = credential?.user;
      if (user == null) {
        Get.snackbar('Google sign-in', 'Sign-in cancelled.');
        return;
      }

      await _userRepository.createUserIfNotExists(user);
      await _routeAfterAuth(user.uid);
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Google sign-in failed', _friendlyAuthMessage(e));
    } catch (e) {
      final String text = e.toString();
      if (text.contains('ApiException: 10') ||
          text.toLowerCase().contains('developer_error')) {
        Get.snackbar(
          'Google sign-in failed',
          'Android SHA fingerprint missing. Rebuild app after Firebase SHA update.',
        );
      } else {
        Get.snackbar('Google sign-in failed', text);
      }
    } finally {
      isLoading.value = false;
    }
  }

  String _friendlyAuthMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Email format invalid hai.';
      case 'user-disabled':
        return 'This account is disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email ya password sahi nahi hai.';
      case 'email-already-in-use':
        return 'Is email par account already maujood hai.';
      case 'operation-not-allowed':
        return 'Firebase provider enable nahi hai (Email/Google).';
      case 'weak-password':
        return 'Password bohat weak hai.';
      case 'too-many-requests':
        return 'Too many attempts. Thodi der baad try karein.';
      default:
        return e.message ?? e.code;
    }
  }

  Future<void> _routeAfterAuth(String uid) async {
    final AppUser? appUser = await _userRepository.getUser(uid);
    if (appUser == null || !appUser.onboardingCompleted) {
      Get.offAllNamed(AppRoutes.onboarding);
      return;
    }
    if (!appUser.profileCompleted) {
      Get.offAllNamed(AppRoutes.profileSetup);
      return;
    }
    Get.offAllNamed(AppRoutes.home);
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
