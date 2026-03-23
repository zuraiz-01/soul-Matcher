import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soul_matcher/app/modules/onboarding/onboarding_controller.dart';
import 'package:soul_matcher/app/widgets/primary_button.dart';

class OnboardingPage extends GetView<OnboardingController> {
  const OnboardingPage({super.key});

  static const List<_OnboardingItem> _items = <_OnboardingItem>[
    _OnboardingItem(
      title: 'Meet Real People',
      subtitle: 'SoulMatch helps you discover people aligned with your vibe.',
      icon: Icons.diversity_1_rounded,
    ),
    _OnboardingItem(
      title: 'Swipe With Intent',
      subtitle: 'Like, pass, or super like with premium profile cards.',
      icon: Icons.swipe_rounded,
    ),
    _OnboardingItem(
      title: 'Build Real Connections',
      subtitle: 'Match instantly and chat in real-time.',
      icon: Icons.forum_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final PageController pageController = PageController();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: <Widget>[
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: controller.completeOnboarding,
                  child: const Text('Skip'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: pageController,
                  itemCount: _items.length,
                  onPageChanged: (int index) =>
                      controller.pageIndex.value = index,
                  itemBuilder: (_, int index) {
                    final _OnboardingItem item = _items[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(item.icon, size: 90),
                              const SizedBox(height: 20),
                              Text(
                                item.title,
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Text(item.subtitle, textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Obx(
                () => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List<Widget>.generate(
                    _items.length,
                    (int i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: controller.pageIndex.value == i ? 28 : 10,
                      height: 10,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: controller.pageIndex.value == i
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade400,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Obx(
                () => PrimaryButton(
                  label: controller.pageIndex.value == _items.length - 1
                      ? 'Continue'
                      : 'Next',
                  isLoading: controller.isCompleting.value,
                  onTap: () {
                    if (controller.pageIndex.value == _items.length - 1) {
                      controller.completeOnboarding();
                      return;
                    }
                    pageController.nextPage(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOut,
                    );
                  },
                ),
              ),
            ],
          ),
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
  });

  final String title;
  final String subtitle;
  final IconData icon;
}
