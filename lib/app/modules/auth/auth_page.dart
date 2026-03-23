import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soul_matcher/app/modules/auth/auth_controller.dart';
import 'package:video_player/video_player.dart';

class AuthPage extends GetView<AuthController> {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const SizedBox(height: 12),
                        const Text(
                          'SoulMatch',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Obx(() {
                          final bool isLoginMode = controller.isLoginMode.value;
                          return _ModeSwitcher(
                            isLoginMode: isLoginMode,
                            onLoginTap: () {
                              if (!controller.isLoginMode.value) {
                                controller.toggleMode();
                              }
                            },
                            onSignupTap: () {
                              if (controller.isLoginMode.value) {
                                controller.toggleMode();
                              }
                            },
                          );
                        }),
                        const SizedBox(height: 8),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (BuildContext context, BoxConstraints constraints) {
                              return SingleChildScrollView(
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: constraints.maxHeight,
                                  ),
                                  child: Obx(() {
                                    final bool isLoginMode =
                                        controller.isLoginMode.value;
                                    final bool isLoading =
                                        controller.isLoading.value;
                                    final bool isPasswordObscured =
                                        controller.isPasswordObscured.value;
                                    final bool isConfirmPasswordObscured =
                                        controller
                                            .isConfirmPasswordObscured
                                            .value;

                                    return AutofillGroup(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 220,
                                            ),
                                            switchInCurve: Curves.easeOutCubic,
                                            switchOutCurve: Curves.easeInCubic,
                                            child: FittedBox(
                                              key: ValueKey<bool>(isLoginMode),
                                              fit: BoxFit.scaleDown,
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                isLoginMode
                                                    ? 'Welcome back'
                                                    : 'Create new account',
                                                maxLines: 1,
                                                softWrap: false,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w800,
                                                  height: 1.02,
                                                  letterSpacing: -0.4,
                                                  fontSize: 46,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 220,
                                            ),
                                            child: Text(
                                              isLoginMode
                                                  ? 'Sign in to continue'
                                                  : 'Set up your account in seconds',
                                              key: ValueKey<bool>(isLoginMode),
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            child: BackdropFilter(
                                              filter: ImageFilter.blur(
                                                sigmaX: 10,
                                                sigmaY: 10,
                                              ),
                                              child: Container(
                                                width: double.infinity,
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                      16,
                                                      16,
                                                      16,
                                                      18,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0x30131B28,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color: const Color(
                                                      0x55FFFFFF,
                                                    ),
                                                    width: 0.9,
                                                  ),
                                                ),
                                                child: Column(
                                                  children: <Widget>[
                                                    _LineInput(
                                                      controller: controller
                                                          .emailController,
                                                      hint: 'Email Address',
                                                      keyboardType:
                                                          TextInputType
                                                              .emailAddress,
                                                      textInputAction:
                                                          TextInputAction.next,
                                                      autofillHints:
                                                          const <String>[
                                                            AutofillHints
                                                                .username,
                                                            AutofillHints.email,
                                                          ],
                                                      leadingIcon: Icons
                                                          .alternate_email_rounded,
                                                    ),
                                                    const SizedBox(height: 20),
                                                    _LineInput(
                                                      controller: controller
                                                          .passwordController,
                                                      hint: 'Password',
                                                      obscureText:
                                                          isPasswordObscured,
                                                      textInputAction:
                                                          isLoginMode
                                                          ? TextInputAction.done
                                                          : TextInputAction
                                                                .next,
                                                      autofillHints:
                                                          const <String>[
                                                            AutofillHints
                                                                .password,
                                                          ],
                                                      onSubmitted: (_) {
                                                        if (isLoginMode) {
                                                          controller
                                                              .submitEmailAuth();
                                                          return;
                                                        }
                                                        FocusScope.of(
                                                          context,
                                                        ).nextFocus();
                                                      },
                                                      leadingIcon:
                                                          Icons.lock_outline,
                                                      trailing: IconButton(
                                                        onPressed: controller
                                                            .togglePasswordVisibility,
                                                        splashRadius: 18,
                                                        icon: Icon(
                                                          isPasswordObscured
                                                              ? Icons
                                                                    .visibility_off_outlined
                                                              : Icons
                                                                    .visibility_outlined,
                                                          size: 20,
                                                          color: Colors.white70,
                                                        ),
                                                      ),
                                                    ),
                                                    AnimatedSwitcher(
                                                      duration: const Duration(
                                                        milliseconds: 220,
                                                      ),
                                                      child: isLoginMode
                                                          ? const SizedBox(
                                                              key: ValueKey<String>(
                                                                'empty-confirm',
                                                              ),
                                                            )
                                                          : Padding(
                                                              key:
                                                                  const ValueKey<
                                                                    String
                                                                  >(
                                                                    'confirm-field',
                                                                  ),
                                                              padding:
                                                                  const EdgeInsets.only(
                                                                    top: 20,
                                                                  ),
                                                              child: _LineInput(
                                                                controller:
                                                                    controller
                                                                        .confirmPasswordController,
                                                                hint:
                                                                    'Confirm Password',
                                                                obscureText:
                                                                    isConfirmPasswordObscured,
                                                                textInputAction:
                                                                    TextInputAction
                                                                        .done,
                                                                autofillHints:
                                                                    const <
                                                                      String
                                                                    >[
                                                                      AutofillHints
                                                                          .password,
                                                                    ],
                                                                onSubmitted: (_) =>
                                                                    controller
                                                                        .submitEmailAuth(),
                                                                leadingIcon: Icons
                                                                    .lock_reset_outlined,
                                                                trailing: IconButton(
                                                                  onPressed:
                                                                      controller
                                                                          .toggleConfirmPasswordVisibility,
                                                                  splashRadius:
                                                                      18,
                                                                  icon: Icon(
                                                                    isConfirmPasswordObscured
                                                                        ? Icons
                                                                              .visibility_off_outlined
                                                                        : Icons
                                                                              .visibility_outlined,
                                                                    size: 20,
                                                                    color: Colors
                                                                        .white70,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                    ),
                                                    const SizedBox(height: 28),
                                                    SizedBox(
                                                      width: double.infinity,
                                                      height: 50,
                                                      child: ElevatedButton(
                                                        onPressed: isLoading
                                                            ? null
                                                            : controller
                                                                  .submitEmailAuth,
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.white,
                                                          foregroundColor:
                                                              const Color(
                                                                0xFF111111,
                                                              ),
                                                          disabledBackgroundColor:
                                                              Colors.white70,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                          ),
                                                          elevation: 0,
                                                        ),
                                                        child: isLoading
                                                            ? const SizedBox(
                                                                width: 20,
                                                                height: 20,
                                                                child: CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2,
                                                                  valueColor:
                                                                      AlwaysStoppedAnimation<
                                                                        Color
                                                                      >(
                                                                        Color(
                                                                          0xFF111111,
                                                                        ),
                                                                      ),
                                                                ),
                                                              )
                                                            : Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .center,
                                                                children: <Widget>[
                                                                  Text(
                                                                    isLoginMode
                                                                        ? 'Log In'
                                                                        : 'Create Account',
                                                                    style: const TextStyle(
                                                                      fontSize:
                                                                          16,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w700,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 6,
                                                                  ),
                                                                  const Icon(
                                                                    Icons
                                                                        .arrow_forward_rounded,
                                                                    size: 19,
                                                                  ),
                                                                ],
                                                              ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 52),
                                        ],
                                      ),
                                    );
                                  }),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
    this.textInputAction,
    this.autofillHints,
    this.onSubmitted,
    this.trailing,
    this.leadingIcon,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;
  final Widget? trailing;
  final IconData? leadingIcon;

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
        textInputAction: textInputAction,
        autofillHints: autofillHints,
        onSubmitted: onSubmitted,
        autocorrect: false,
        enableSuggestions: !obscureText,
        keyboardAppearance: Brightness.dark,
        textCapitalization: TextCapitalization.none,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xB0FFFFFF), fontSize: 18),
          contentPadding: const EdgeInsets.only(bottom: 10),
          prefixIcon: leadingIcon == null
              ? null
              : Icon(leadingIcon, color: Colors.white70, size: 19),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 34,
            minHeight: 30,
          ),
          suffixIcon: trailing,
          suffixIconConstraints: const BoxConstraints(
            minWidth: 42,
            minHeight: 36,
          ),
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
  const _ModeSwitcher({
    required this.isLoginMode,
    required this.onLoginTap,
    required this.onSignupTap,
  });

  final bool isLoginMode;
  final VoidCallback onLoginTap;
  final VoidCallback onSignupTap;

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
                selected: isLoginMode,
                onTap: onLoginTap,
              ),
              _ModeTab(
                title: 'Sign Up',
                selected: !isLoginMode,
                onTap: onSignupTap,
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
