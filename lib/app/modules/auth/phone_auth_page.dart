import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soul_matcher/app/modules/auth/auth_controller.dart';
import 'package:soul_matcher/app/widgets/app_text_field.dart';
import 'package:soul_matcher/app/widgets/primary_button.dart';

class PhoneAuthPage extends GetView<AuthController> {
  const PhoneAuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Phone Sign-In')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Obx(
            () => Column(
              children: <Widget>[
                AppTextField(
                  controller: controller.phoneController,
                  hint: 'Phone number (+1...)',
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone),
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Send OTP',
                  isLoading: controller.isLoading.value,
                  onTap: controller.sendOtp,
                ),
                const SizedBox(height: 18),
                AppTextField(
                  controller: controller.otpController,
                  hint: 'Enter OTP',
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.password_outlined),
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Verify OTP',
                  isLoading: controller.isLoading.value,
                  onTap: controller.verifyOtp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
