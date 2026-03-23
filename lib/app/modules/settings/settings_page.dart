import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soul_matcher/app/modules/settings/settings_controller.dart';

class SettingsPage extends GetView<SettingsController> {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Obx(
        () => ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Card(
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
                ],
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: controller.isLoading.value ? null : controller.logout,
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
}
