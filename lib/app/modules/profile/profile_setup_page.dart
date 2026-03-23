import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:soul_matcher/app/core/constants/app_constants.dart';
import 'package:soul_matcher/app/data/models/location_suggestion.dart';
import 'package:soul_matcher/app/modules/profile/profile_controller.dart';
import 'package:soul_matcher/app/modules/profile/widgets/photo_grid_picker.dart';
import 'package:soul_matcher/app/widgets/app_loader.dart';
import 'package:soul_matcher/app/widgets/premium_background.dart';
import 'package:soul_matcher/app/widgets/app_text_field.dart';
import 'package:soul_matcher/app/widgets/primary_button.dart';

class ProfileSetupPage extends GetView<ProfileController> {
  const ProfileSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bool isLoading = controller.isLoading.value;
      final bool isSaving = controller.isSaving.value;
      final ThemeData theme = Theme.of(context);

      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(
            controller.isEditMode ? 'Edit Profile' : 'Create Profile',
          ),
        ),
        body: PremiumBackground(
          child: isLoading
              ? const AppLoader()
              : GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: SafeArea(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 132),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            controller.isEditMode
                                ? 'Update your profile'
                                : 'Complete your profile',
                            style: theme.textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Better profiles get better matches. Add photos and a clear intro.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withValues(alpha: 0.76),
                            ),
                          ),
                          const SizedBox(height: 18),
                          _SectionCard(
                            title: 'Photos',
                            subtitle:
                                'Add at least 1 photo. Best results with 3+ photos.',
                            trailing: Obx(
                              () => Text(
                                '${controller.photoUrls.length}/${AppConstants.maxProfilePhotos}',
                                style: theme.textTheme.labelLarge,
                              ),
                            ),
                            child: ProfileController.photoUploadEnabled
                                ? Obx(() {
                                    final List<String> photos = controller
                                        .photoUrls
                                        .toList(growable: false);
                                    return PhotoGridPicker(
                                      photos: photos,
                                      isBusy: controller.isSaving.value,
                                      onAdd: controller.pickPhoto,
                                      onDelete: controller.removePhoto,
                                    );
                                  })
                                : _DisabledUploadCard(theme: theme),
                          ),
                          const SizedBox(height: 16),
                          _SectionCard(
                            title: 'About You',
                            subtitle:
                                'Keep details simple and genuine. This appears on your card.',
                            child: Column(
                              children: <Widget>[
                                AppTextField(
                                  controller: controller.nameController,
                                  label: 'Display name',
                                  hint: 'e.g., Alex',
                                  prefixIcon: const Icon(
                                    Icons.person_outline_rounded,
                                  ),
                                  textInputAction: TextInputAction.next,
                                  maxLength: 24,
                                ),
                                const SizedBox(height: 12),
                                AppTextField(
                                  controller: controller.bioController,
                                  label: 'Bio',
                                  hint: 'Write 1-2 lines about yourself',
                                  helperText: 'Keep it short and specific.',
                                  maxLines: 4,
                                  maxLength: 180,
                                  prefixIcon: const Padding(
                                    padding: EdgeInsets.only(bottom: 52),
                                    child: Icon(Icons.edit_note_rounded),
                                  ),
                                  textInputAction: TextInputAction.newline,
                                ),
                                const SizedBox(height: 12),
                                AppTextField(
                                  controller: controller.ageController,
                                  label: 'Age',
                                  hint: '18+',
                                  keyboardType: TextInputType.number,
                                  inputFormatters: <TextInputFormatter>[
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(2),
                                  ],
                                  prefixIcon: const Icon(Icons.cake_outlined),
                                  textInputAction: TextInputAction.next,
                                  textCapitalization: TextCapitalization.none,
                                ),
                                const SizedBox(height: 12),
                                const _LocationAutocompleteField(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SectionCard(
                            title: 'Preferences',
                            subtitle:
                                'Tell us who you are and who you want to see.',
                            child: Column(
                              children: <Widget>[
                                Obx(
                                  () => _ProfileDropdown(
                                    label: 'Your gender',
                                    value: controller.selectedGender.value,
                                    icon: Icons.person_pin_circle_outlined,
                                    options: AppConstants.genderOptions,
                                    onChanged: (String? value) =>
                                        controller.selectedGender.value = value,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Obx(
                                  () => _ProfileDropdown(
                                    label: 'Interested in',
                                    value:
                                        controller.selectedInterestedIn.value,
                                    icon: Icons.favorite_border_rounded,
                                    options: AppConstants.genderOptions,
                                    onChanged: (String? value) =>
                                        controller.selectedInterestedIn.value =
                                            value,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
        bottomNavigationBar: isLoading
            ? null
            : SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor.withValues(
                      alpha: 0.95,
                    ),
                    border: Border(
                      top: BorderSide(
                        color: theme.dividerColor.withValues(alpha: 0.18),
                      ),
                    ),
                  ),
                  child: PrimaryButton(
                    label: controller.isEditMode ? 'Save Changes' : 'Continue',
                    isLoading: isSaving,
                    onTap: controller.saveProfile,
                  ),
                ),
              ),
      );
    });
  }
}

class _LocationAutocompleteField extends GetView<ProfileController> {
  const _LocationAutocompleteField();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Obx(() {
      final bool isSearching = controller.isLocationSearching.value;
      final bool showSuggestions = controller.showLocationSuggestions.value;
      final List<LocationSuggestion> suggestions = controller
          .locationSuggestions
          .toList(growable: false);
      final bool shouldShowCard =
          showSuggestions && (isSearching || suggestions.isNotEmpty);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppTextField(
            controller: controller.locationController,
            focusNode: controller.locationFocusNode,
            label: 'Location',
            hint: 'Type your city or full address',
            helperText: 'Type 3+ letters and pick from suggestions.',
            prefixIcon: const Icon(Icons.location_on_outlined),
            suffixIcon: isSearching
                ? const Padding(
                    padding: EdgeInsets.all(13),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
            textInputAction: TextInputAction.done,
            onChanged: controller.onLocationQueryChanged,
            onTap: () => controller.onLocationQueryChanged(
              controller.locationController.text,
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: shouldShowCard
                ? Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.24),
                      ),
                    ),
                    child: isSearching && suggestions.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: Row(
                              children: <Widget>[
                                SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text('Searching locations...'),
                              ],
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: suggestions.length,
                            separatorBuilder: (_, int index) => Divider(
                              height: 1,
                              thickness: 0.7,
                              color: theme.dividerColor.withValues(alpha: 0.2),
                            ),
                            itemBuilder: (_, int index) {
                              final LocationSuggestion suggestion =
                                  suggestions[index];
                              return InkWell(
                                onTap: () => controller.pickLocationSuggestion(
                                  suggestion,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Icon(
                                        Icons.place_outlined,
                                        size: 18,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Text(
                                              suggestion.primaryText,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                            if (suggestion
                                                .secondaryText
                                                .isNotEmpty) ...<Widget>[
                                              const SizedBox(height: 2),
                                              Text(
                                                suggestion.secondaryText,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      color: theme
                                                          .textTheme
                                                          .bodySmall
                                                          ?.color
                                                          ?.withValues(
                                                            alpha: 0.72,
                                                          ),
                                                    ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      );
    });
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(fontSize: 18),
                  ),
                ),
                if (trailing case final Widget trailingWidget) trailingWidget,
              ],
            ),
            if (subtitle != null) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(
                    alpha: 0.74,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _DisabledUploadCard extends StatelessWidget {
  const _DisabledUploadCard({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.26),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.info_outline_rounded, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Photo upload ke liye Cloudinary upload preset required hai. Abhi preset missing hai, is liye aap profile bina photos ke save kar sakte hain.',
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileDropdown extends StatelessWidget {
  const _ProfileDropdown({
    required this.label,
    required this.icon,
    required this.options,
    required this.onChanged,
    this.value,
  });

  final String label;
  final IconData icon;
  final List<String> options;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      hint: Text(label),
      isExpanded: true,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      items: options
          .map(
            (String option) =>
                DropdownMenuItem<String>(value: option, child: Text(option)),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
