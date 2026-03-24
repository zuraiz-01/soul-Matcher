import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soul_matcher/app/modules/onboarding/onboarding_controller.dart';

class OnboardingPage extends GetView<OnboardingController> {
  const OnboardingPage({super.key});

  static const List<_OnboardingItem> _items = <_OnboardingItem>[
    _OnboardingItem(
      title: 'Meet Real People',
      subtitle: 'SoulMatch helps you discover people aligned with your vibe.',
      icon: Icons.diversity_1_rounded,
      colors: <Color>[Color(0xFF1A2334), Color(0xFF4E2133)],
    ),
    _OnboardingItem(
      title: 'Swipe With Intent',
      subtitle: 'Like, pass, or super like with premium profile cards.',
      icon: Icons.swipe_rounded,
      colors: <Color>[Color(0xFF102026), Color(0xFF2E274D)],
    ),
    _OnboardingItem(
      title: 'Build Real Connections',
      subtitle: 'Match instantly and chat in real-time.',
      icon: Icons.forum_rounded,
      colors: <Color>[Color(0xFF202737), Color(0xFF4A1D2F)],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          PageView.builder(
            controller: controller.pageController,
            itemCount: _items.length,
            onPageChanged: controller.onPageChanged,
            itemBuilder: (_, int index) {
              final _OnboardingItem item = _items[index];
              return _OnboardingSlide(item: item);
            },
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0x33000000),
                  Color(0x14000000),
                  Color(0xCC090C12),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                children: <Widget>[
                  Obx(() {
                    final int current = controller.pageIndex.value + 1;
                    return Row(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.42),
                            ),
                          ),
                          child: const Text(
                            'SoulMatch',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$current/${_items.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    );
                  }),
                  const Spacer(),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
                        decoration: BoxDecoration(
                          color: const Color(0x2D101520),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.24),
                          ),
                        ),
                        child: Column(
                          children: <Widget>[
                            Obx(() {
                              final int index = controller.pageIndex.value;
                              final _OnboardingItem item = _items[index];
                              return AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                child: Column(
                                  key: ValueKey<int>(index),
                                  children: <Widget>[
                                    Text(
                                      item.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 34,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.4,
                                        height: 1.05,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      item.subtitle,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 16,
                                        height: 1.4,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 8),
                            const Text(
                              'Swipe for next story',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Obx(
                              () => Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List<Widget>.generate(
                                  _items.length,
                                  (int i) => AnimatedContainer(
                                    duration: const Duration(milliseconds: 220),
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    width: controller.pageIndex.value == i
                                        ? 24
                                        : 9,
                                    height: 9,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(99),
                                      color: controller.pageIndex.value == i
                                          ? Colors.white
                                          : Colors.white38,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Obx(() {
                              final bool isLast =
                                  controller.pageIndex.value ==
                                  _items.length - 1;
                              final bool isBusy = controller.isCompleting.value;

                              return Row(
                                children: <Widget>[
                                  Expanded(
                                    flex: 15,
                                    child: OutlinedButton(
                                      onPressed: isBusy
                                          ? null
                                          : controller.skipOnboarding,
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                          color: Colors.white70,
                                        ),
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size.fromHeight(50),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Skip',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Spacer(flex: 1),
                                  Expanded(
                                    flex: 15,
                                    child: ElevatedButton(
                                      onPressed: isBusy
                                          ? null
                                          : () => controller.nextOrComplete(
                                              _items.length,
                                            ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: const Color(
                                          0xFF111111,
                                        ),
                                        minimumSize: const Size.fromHeight(50),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                      child: isBusy
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Color(0xFF111111)),
                                              ),
                                            )
                                          : Text(
                                              isLast ? 'Continue' : 'Next',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({required this.item});

  final _OnboardingItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: item.colors,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned(
            top: -40,
            right: -30,
            child: _SoftGlow(
              size: 180,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Positioned(
            left: -20,
            bottom: 120,
            child: _SoftGlow(
              size: 140,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          Center(
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.45),
                  width: 1.4,
                ),
              ),
              child: Icon(item.icon, color: Colors.white, size: 88),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftGlow extends StatelessWidget {
  const _SoftGlow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: <BoxShadow>[
            BoxShadow(color: color, blurRadius: 90, spreadRadius: 16),
          ],
        ),
      ),
    );
  }
}

class _OnboardingItem {
  const _OnboardingItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
}
