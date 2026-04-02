import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soul_matcher/app/core/subscription/subscription_plan.dart';
import 'package:soul_matcher/app/modules/settings/settings_controller.dart';
import 'package:soul_matcher/app/routes/app_routes.dart';
import 'package:soul_matcher/app/widgets/premium_background.dart';

class SettingsPage extends GetView<SettingsController> {
  const SettingsPage({super.key});

  @override
  SettingsController get controller {
    if (!Get.isRegistered<SettingsController>()) {
      Get.lazyPut<SettingsController>(() => SettingsController(), fenix: true);
    }
    return Get.find<SettingsController>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Settings')),
      body: PremiumBackground(
        child: Obx(
          () => ListView(
            padding: const EdgeInsets.fromLTRB(16, 100, 16, 20),
            children: <Widget>[
              PremiumGlassCard(
                child: Column(
                  children: <Widget>[
                    ListTile(
                      leading: const Icon(Icons.workspace_premium_outlined),
                      title: const Text('Current Plan'),
                      subtitle: Text(controller.currentPlan.value.label),
                    ),
                    if (controller.currentPlan.value != SubscriptionPlan.free)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: controller.isLoading.value
                                ? null
                                : () => _showCancelPlanConfirmation(context),
                            icon: const Icon(Icons.cancel_outlined),
                            label: const Text('Cancel Plan'),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (kDebugMode) ...<Widget>[
                const SizedBox(height: 14),
                _SubscriptionPlanSection(controller: controller),
              ],
              const SizedBox(height: 14),
              _ReferralSection(controller: controller),
              const SizedBox(height: 14),
              PremiumGlassCard(
                child: Column(
                  children: <Widget>[
                    ListTile(
                      title: const Text('Theme'),
                      subtitle: const Text('Light / Dark / System'),
                      trailing: DropdownButton<ThemeMode>(
                        value: controller.themeMode,
                        onChanged: (ThemeMode? mode) {
                          if (mode != null) controller.setThemeMode(mode);
                        },
                        items: const <DropdownMenuItem<ThemeMode>>[
                          DropdownMenuItem<ThemeMode>(
                            value: ThemeMode.system,
                            child: Text('System'),
                          ),
                          DropdownMenuItem<ThemeMode>(
                            value: ThemeMode.light,
                            child: Text('Light'),
                          ),
                          DropdownMenuItem<ThemeMode>(
                            value: ThemeMode.dark,
                            child: Text('Dark'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.favorite_outline_rounded),
                      title: const Text('Liked Users'),
                      subtitle: const Text('Profiles you liked'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Get.toNamed(AppRoutes.likedUsers),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.star_outline_rounded),
                      title: const Text('Super Liked Users'),
                      subtitle: const Text('Profiles you super liked'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Get.toNamed(AppRoutes.superLikedUsers),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.block_outlined),
                      title: const Text('Blocked Users'),
                      subtitle: const Text('Users you blocked'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Get.toNamed(AppRoutes.blockedUsers),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.flag_outlined),
                      title: const Text('Reported Users'),
                      subtitle: const Text('Users you reported'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Get.toNamed(AppRoutes.reportedUsers),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: controller.isLoading.value
                    ? null
                    : controller.logout,
                child: const Text('Logout'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: controller.isLoading.value
                    ? null
                    : () => _showDeleteConfirmation(context),
                icon: const Icon(Icons.delete_forever_outlined),
                label: const Text('Delete Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    await Get.defaultDialog(
      title: 'Delete Account',
      middleText:
          'This action is permanent and removes your profile, chats metadata, and account.',
      textCancel: 'Cancel',
      textConfirm: 'Delete',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        controller.deleteAccount();
      },
    );
  }

  Future<void> _showCancelPlanConfirmation(BuildContext context) async {
    await Get.defaultDialog(
      title: 'Cancel Plan',
      middleText:
          'Do you want to cancel your subscription and move to Free plan?',
      textCancel: 'Keep Plan',
      textConfirm: 'Cancel Plan',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        controller.cancelPlan();
      },
    );
  }
}

class _SubscriptionPlanSection extends StatelessWidget {
  const _SubscriptionPlanSection({required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return PremiumGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'SoulMatcher Plans (Debug)',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'Switch plans with mock checkout for testing. Production should use billing entitlements.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          _PlanCard(
            plan: SubscriptionPlan.free,
            currentPlan: controller.currentPlan.value,
            isLoading: controller.isLoading.value,
            onSelect: controller.switchPlan,
          ),
          const SizedBox(height: 10),
          _PlanCard(
            plan: SubscriptionPlan.gold,
            currentPlan: controller.currentPlan.value,
            isLoading: controller.isLoading.value,
            onSelect: controller.switchPlan,
          ),
          const SizedBox(height: 10),
          _PlanCard(
            plan: SubscriptionPlan.platinum,
            currentPlan: controller.currentPlan.value,
            isLoading: controller.isLoading.value,
            onSelect: controller.switchPlan,
          ),
        ],
      ),
    );
  }
}

class _ReferralSection extends StatelessWidget {
  const _ReferralSection({required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return PremiumGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Referral Wallet', style: theme.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Invite users, earn points, and create mock payout requests.',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Points: ${controller.referralPoints}',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  controller.referralCode.isEmpty
                      ? 'Generating your referral code...'
                      : 'Your referral code: ${controller.referralCode}',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: controller.isReferralLoading.value
                            ? null
                            : controller.copyReferralCode,
                        icon: const Icon(Icons.copy_rounded),
                        label: const Text('Copy Code'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: controller.isReferralLoading.value
                            ? null
                            : controller.claimReferralRewards,
                        icon: const Icon(Icons.redeem_rounded),
                        label: const Text('Claim Rewards'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller.referralCodeController,
            enabled:
                !controller.isReferralLoading.value &&
                !controller.hasUsedReferralCode,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: controller.hasUsedReferralCode
                  ? 'Referral already used'
                  : 'Enter referral code',
              hintText: 'e.g. SOULAB12CD34',
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed:
                  controller.isReferralLoading.value ||
                      controller.hasUsedReferralCode
                  ? null
                  : controller.applyReferralCode,
              child: const Text('Apply Referral Code'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: controller.isReferralLoading.value
                  ? null
                  : controller.requestMockPayout,
              icon: const Icon(Icons.account_balance_wallet_outlined),
              label: Text(
                'Request Mock Payout (min ${controller.minPayoutPoints} points)',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.currentPlan,
    required this.isLoading,
    required this.onSelect,
  });

  final SubscriptionPlan plan;
  final SubscriptionPlan currentPlan;
  final bool isLoading;
  final Future<void> Function(SubscriptionPlan plan) onSelect;

  @override
  Widget build(BuildContext context) {
    final bool active = currentPlan == plan;
    final List<String> features = _featuresForPlan(plan);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: active ? 0.12 : 0.06),
        border: Border.all(
          color: active
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.7)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  plan.label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (active)
                const Chip(
                  label: Text('Current'),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            plan.description,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          ...features.map(
            (String feature) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('- ', style: TextStyle(color: Colors.white70)),
                  Expanded(
                    child: Text(
                      feature,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonal(
              onPressed: active || isLoading ? null : () => onSelect(plan),
              child: Text(active ? 'Selected' : 'Switch to ${plan.label}'),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _featuresForPlan(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.free:
        return const <String>[
          '20-30 swipes/day (configured: 30/day)',
          '1 super like/day',
          '10-15 messages per match (configured: 15/day per match)',
          '30 messages/day total',
          'Basic filters + ads',
        ];
      case SubscriptionPlan.gold:
        return const <String>[
          'Unlimited swipes',
          '5 super likes/day',
          'Unlimited messages',
          'Image sharing (coming soon)',
          'No ads + weekly boost (coming soon)',
          'See who liked you partial (coming soon)',
        ];
      case SubscriptionPlan.platinum:
        return const <String>[
          'Unlimited swipes + unlimited super likes',
          'Unlimited messages',
          'Images + audio (coming soon)',
          'Read receipts + typing indicators (read receipts coming soon)',
          'See who liked you full access (coming soon)',
          'Daily boost + discover priority + badge (coming soon)',
        ];
    }
  }
}
