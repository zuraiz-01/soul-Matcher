import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soul_matcher/app/core/constants/app_constants.dart';
import 'package:soul_matcher/app/modules/profile/profile_controller.dart';
import 'package:soul_matcher/app/modules/profile/widgets/photo_grid_picker.dart';
import 'package:soul_matcher/app/widgets/app_loader.dart';
import 'package:soul_matcher/app/widgets/app_text_field.dart';
import 'package:soul_matcher/app/widgets/primary_button.dart';

class ProfileSetupPage extends GetView<ProfileController> {
  const ProfileSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.isEditMode ? 'Edit Profile' : 'Create Profile'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) return const AppLoader();
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Photos', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                if (ProfileController.photoUploadEnabled)
                  Obx(() {
                    final List<String> photos = controller.photoUrls.toList(
                      growable: false,
                    );
                    return PhotoGridPicker(
                      photos: photos,
                      onAdd: controller.pickPhoto,
                      onDelete: controller.removePhoto,
                    );
                  })
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Theme.of(context).cardColor,
                    ),
                    child: const Text(
                      'Photo upload temporarily disabled hai. Aap profile bina photos ke save kar sakte hain.',
                    ),
                  ),
                const SizedBox(height: 18),
                AppTextField(
                  controller: controller.nameController,
                  hint: 'Display name',
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: controller.bioController,
                  hint: 'Bio',
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: controller.ageController,
                  hint: 'Age',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: controller.locationController,
                  hint: 'Location',
                ),
                const SizedBox(height: 12),
                Obx(
                  () => DropdownButtonFormField<String>(
                    key: ValueKey<String?>(
                      'gender_${controller.selectedGender.value}',
                    ),
                    initialValue: controller.selectedGender.value,
                    hint: const Text('Your gender'),
                    items: AppConstants.genderOptions
                        .map(
                          (String option) => DropdownMenuItem<String>(
                            value: option,
                            child: Text(option),
                          ),
                        )
                        .toList(),
                    onChanged: (String? value) =>
                        controller.selectedGender.value = value,
                  ),
                ),
                const SizedBox(height: 12),
                Obx(
                  () => DropdownButtonFormField<String>(
                    key: ValueKey<String?>(
                      'interest_${controller.selectedInterestedIn.value}',
                    ),
                    initialValue: controller.selectedInterestedIn.value,
                    hint: const Text('Interested in'),
                    items: AppConstants.genderOptions
                        .map(
                          (String option) => DropdownMenuItem<String>(
                            value: option,
                            child: Text(option),
                          ),
                        )
                        .toList(),
                    onChanged: (String? value) {
                      controller.selectedInterestedIn.value = value;
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Obx(
                  () => PrimaryButton(
                    label: controller.isEditMode ? 'Save Changes' : 'Continue',
                    isLoading: controller.isSaving.value,
                    onTap: controller.saveProfile,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
