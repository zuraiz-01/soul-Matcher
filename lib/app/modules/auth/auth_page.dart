import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soul_matcher/app/modules/auth/auth_controller.dart';
import 'package:soul_matcher/app/routes/app_routes.dart';
import 'package:video_player/video_player.dart';

class AuthPage extends GetView<AuthController> {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const _AuthBackgroundVideo(),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0xB5000000),
                  Color(0x7A000000),
                  Color(0xCE020406),
                ],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Obx(
                    () => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const SizedBox(height: 18),
                        _ModeSwitcher(controller: controller),
                        const SizedBox(height: 48),
                        Text(
                          controller.isLoginMode.value
                              ? 'Welcome\nback'
                              : 'Create\nnew account',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            height: 1.02,
                            letterSpacing: -0.4,
                            fontSize: 46,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _LineInput(
                          controller: controller.emailController,
                          hint: 'Phone Number/Email',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 20),
                        _LineInput(
                          controller: controller.passwordController,
                          hint: 'Password',
                          obscureText: true,
                        ),
                        if (!controller.isLoginMode.value) ...<Widget>[
                          const SizedBox(height: 20),
                          _LineInput(
                            controller: controller.confirmPasswordController,
                            hint: 'Confirm Password',
                            obscureText: true,
                          ),
                        ],
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: controller.isLoading.value
                                ? null
                                : controller.submitEmailAuth,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF111111),
                              disabledBackgroundColor: Colors.white70,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(2),
                              ),
                              elevation: 0,
                            ),
                            child: controller.isLoading.value
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF111111),
                                      ),
                                    ),
                                  )
                                : Text(
                                    controller.isLoginMode.value
                                        ? 'Log In'
                                        : 'Create Account',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Center(
                          child: Text(
                            controller.isLoginMode.value
                                ? 'or sign in with'
                                : 'or sign up with',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _SocialButton(
                                label: 'Google',
                                icon: Icons.g_mobiledata_rounded,
                                onTap: controller.signInWithGoogle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SocialButton(
                                label: 'Phone',
                                icon: Icons.phone_outlined,
                                onTap: () => Get.toNamed(AppRoutes.phoneAuth),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineInput extends StatelessWidget {
  const _LineInput({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.white,
          selectionColor: Color(0x66FFFFFF),
          selectionHandleColor: Colors.white,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xB0FFFFFF), fontSize: 18),
          contentPadding: const EdgeInsets.only(bottom: 10),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0x66FFFFFF), width: 1),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white, width: 1.2),
          ),
        ),
      ),
    );
  }
}

class _ModeSwitcher extends StatelessWidget {
  const _ModeSwitcher({required this.controller});

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          width: 170,
          decoration: BoxDecoration(
            color: const Color(0x3316171C),
            border: Border.all(color: const Color(0x55FFFFFF)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: <Widget>[
              _ModeTab(
                title: 'Login',
                selected: controller.isLoginMode.value,
                onTap: () {
                  if (!controller.isLoginMode.value) {
                    controller.toggleMode();
                  }
                },
              ),
              _ModeTab(
                title: 'Sign Up',
                selected: !controller.isLoginMode.value,
                onTap: () {
                  if (controller.isLoginMode.value) {
                    controller.toggleMode();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.black : Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0x99FFFFFF)),
          foregroundColor: Colors.white,
          backgroundColor: const Color(0x22000000),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        ),
        icon: Icon(icon, size: 20),
        label: Text(label),
      ),
    );
  }
}

class _AuthBackgroundVideo extends StatefulWidget {
  const _AuthBackgroundVideo();

  @override
  State<_AuthBackgroundVideo> createState() => _AuthBackgroundVideoState();
}

class _AuthBackgroundVideoState extends State<_AuthBackgroundVideo>
    with WidgetsBindingObserver {
  late final VideoPlayerController _videoController;
  bool _hasError = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _videoController = VideoPlayerController.asset('assets/videos/auth_bg.mp4')
      ..setLooping(true)
      ..setVolume(0)
      ..initialize()
          .then((_) {
            if (!mounted) return;
            debugPrint(
              'Auth video initialized: ${_videoController.value.size}',
            );
            _videoController.play();
            _isPlaying = true;
            setState(() {});
          })
          .catchError((Object error, StackTrace stackTrace) {
            if (!mounted) return;
            debugPrint('Auth video init failed: $error');
            debugPrintStack(stackTrace: stackTrace);
            _hasError = true;
            setState(() {});
          });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_hasError || !_videoController.value.isInitialized) return;
    if (state == AppLifecycleState.resumed) {
      _videoController.play();
    } else if (state == AppLifecycleState.paused) {
      _videoController.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return const _AuthAnimatedFallback();
    }

    if (!_videoController.value.isInitialized) {
      return const DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.4,
            colors: <Color>[Color(0xFF2A1E21), Color(0xFF04070B)],
          ),
        ),
      );
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: _isPlaying ? 1 : 0,
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _videoController.value.size.width,
            height: _videoController.value.size.height,
            child: VideoPlayer(_videoController),
          ),
        ),
      ),
    );
  }
}

class _AuthAnimatedFallback extends StatelessWidget {
  const _AuthAnimatedFallback();

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Image.asset(
        'assets/videos/auth_bg_fallback.gif',
        fit: BoxFit.cover,
        filterQuality: FilterQuality.low,
        gaplessPlayback: true,
      ),
    );
  }
}
