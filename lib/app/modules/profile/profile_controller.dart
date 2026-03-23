import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:soul_matcher/app/core/constants/app_constants.dart';
import 'package:soul_matcher/app/core/constants/cloudinary_config.dart';
import 'package:soul_matcher/app/data/models/app_user.dart';
import 'package:soul_matcher/app/data/models/location_suggestion.dart';
import 'package:soul_matcher/app/data/repositories/auth_repository.dart';
import 'package:soul_matcher/app/data/repositories/user_repository.dart';
import 'package:soul_matcher/app/routes/app_routes.dart';
import 'package:soul_matcher/app/services/cloudinary_upload_service.dart';
import 'package:soul_matcher/app/services/location_search_service.dart';

class ProfileController extends GetxController {
  static bool get photoUploadEnabled => CloudinaryConfig.isConfigured;

  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final UserRepository _userRepository = Get.find<UserRepository>();
  final LocationSearchService _locationSearchService =
      Get.find<LocationSearchService>();
  final ImagePicker _imagePicker = ImagePicker();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final FocusNode locationFocusNode = FocusNode();

  final RxnString selectedGender = RxnString();
  final RxnString selectedInterestedIn = RxnString();
  final RxList<String> photoUrls = <String>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxList<LocationSuggestion> locationSuggestions =
      <LocationSuggestion>[].obs;
  final RxBool isLocationSearching = false.obs;
  final RxBool showLocationSuggestions = false.obs;

  final RxString _locationQuery = ''.obs;
  Worker? _locationDebounceWorker;
  int _locationRequestSequence = 0;

  late final bool isEditMode;

  @override
  void onInit() {
    super.onInit();
    isEditMode =
        Get.currentRoute == AppRoutes.profileEdit ||
        ((Get.arguments as Map<String, dynamic>?)?['isEdit'] == true);
    _locationDebounceWorker = debounce<String>(
      _locationQuery,
      _searchLocationSuggestions,
      time: const Duration(milliseconds: 420),
    );
    locationFocusNode.addListener(_handleLocationFocusChange);
    loadCurrentProfile();
  }

  void _handleLocationFocusChange() {
    if (locationFocusNode.hasFocus) {
      if (locationController.text.trim().length >= 3 &&
          locationSuggestions.isNotEmpty) {
        showLocationSuggestions.value = true;
      }
      return;
    }
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      showLocationSuggestions.value = false;
    });
  }

  Future<void> loadCurrentProfile() async {
    final String? uid = _authRepository.currentUser?.uid;
    if (uid == null) return;
    isLoading.value = true;
    try {
      final AppUser? user = await _userRepository.getUser(uid);
      if (user == null) return;
      nameController.text = user.displayName;
      bioController.text = user.bio;
      ageController.text = user.age?.toString() ?? '';
      locationController.text = user.location;
      selectedGender.value = user.gender;
      selectedInterestedIn.value = user.interestedIn;
      photoUrls.assignAll(user.photos);
      showLocationSuggestions.value = false;
      locationSuggestions.clear();
    } finally {
      isLoading.value = false;
    }
  }

  void onLocationQueryChanged(String value) {
    final String trimmedValue = value.trim();
    _locationQuery.value = trimmedValue;

    if (trimmedValue.length < 3) {
      isLocationSearching.value = false;
      showLocationSuggestions.value = false;
      locationSuggestions.clear();
      return;
    }

    showLocationSuggestions.value = true;
  }

  Future<void> _searchLocationSuggestions(String query) async {
    if (query.length < 3) {
      locationSuggestions.clear();
      isLocationSearching.value = false;
      showLocationSuggestions.value = false;
      return;
    }

    final int requestId = ++_locationRequestSequence;
    isLocationSearching.value = true;
    try {
      final List<LocationSuggestion> suggestions = await _locationSearchService
          .searchAddresses(query);
      if (requestId != _locationRequestSequence) {
        return;
      }
      locationSuggestions.assignAll(suggestions);
      showLocationSuggestions.value =
          locationFocusNode.hasFocus && suggestions.isNotEmpty;
    } catch (_) {
      if (requestId != _locationRequestSequence) {
        return;
      }
      locationSuggestions.clear();
      showLocationSuggestions.value = false;
    } finally {
      if (requestId == _locationRequestSequence) {
        isLocationSearching.value = false;
      }
    }
  }

  void pickLocationSuggestion(LocationSuggestion suggestion) {
    locationController.text = suggestion.displayName;
    locationController.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.displayName.length),
    );
    locationSuggestions.clear();
    showLocationSuggestions.value = false;
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> pickPhoto() async {
    if (!photoUploadEnabled) {
      Get.snackbar(
        'Photo upload disabled',
        'Cloudinary setup missing hai. Upload preset configure karo.',
      );
      return;
    }
    if (photoUrls.length >= AppConstants.maxProfilePhotos) {
      Get.snackbar('Limit reached', 'You can upload up to 6 photos.');
      return;
    }
    final XFile? file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
    );
    if (file == null) return;

    final String? uid = _authRepository.currentUser?.uid;
    if (uid == null) return;
    isSaving.value = true;
    try {
      final String url = await _userRepository.uploadProfilePhoto(
        uid: uid,
        file: file,
      );
      photoUrls.add(url);
    } on CloudinaryUploadException catch (e) {
      Get.snackbar('Upload failed', _friendlyUploadError(e));
    } catch (e) {
      Get.snackbar('Upload failed', _friendlyUploadError(e));
    } finally {
      isSaving.value = false;
    }
  }

  void removePhoto(String url) {
    photoUrls.remove(url);
  }

  String _friendlyUploadError(Object error) {
    final String message = error.toString().toLowerCase();

    if (message.contains('cloudinary config missing') ||
        message.contains('upload preset')) {
      return 'Cloudinary upload preset missing hai. Run with --dart-define=CLOUDINARY_UPLOAD_PRESET=<your_unsigned_preset>.';
    }
    if (message.contains('unsigned') ||
        message.contains('preset') ||
        message.contains('not found')) {
      return 'Cloudinary unsigned upload preset invalid hai. Console > Settings > Upload me preset check karo.';
    }
    if (message.contains('network') ||
        message.contains('socket') ||
        message.contains('timeout')) {
      return 'Network issue ki wajah se upload fail hua. Internet check karke retry karo.';
    }
    if (message.contains('file too large')) {
      return 'Image size zyada hai. Thori choti image select karo.';
    }

    if (error is CloudinaryUploadException && error.message.trim().isNotEmpty) {
      return error.message.trim();
    }

    return error.toString();
  }

  Future<void> saveProfile() async {
    final String? uid = _authRepository.currentUser?.uid;
    if (uid == null) return;

    final String name = nameController.text.trim();
    final String bio = bioController.text.trim();
    final int? age = int.tryParse(ageController.text.trim());
    final String location = locationController.text.trim();
    final String? gender = selectedGender.value;
    final String? interestedIn = selectedInterestedIn.value;

    if (name.isEmpty || bio.isEmpty || age == null || location.isEmpty) {
      Get.snackbar('Validation', 'Please complete all profile fields.');
      return;
    }
    if (age < 18 || age > 99) {
      Get.snackbar('Validation', 'Age must be between 18 and 99.');
      return;
    }
    if (gender == null || interestedIn == null) {
      Get.snackbar('Validation', 'Select gender and interest.');
      return;
    }
    if (photoUploadEnabled && photoUrls.isEmpty) {
      Get.snackbar('Validation', 'Add at least one photo.');
      return;
    }

    isSaving.value = true;
    try {
      await _userRepository.updateProfile(
        uid: uid,
        displayName: name,
        bio: bio,
        age: age,
        gender: gender,
        interestedIn: interestedIn,
        location: location,
        photos: photoUrls.toList(),
      );
      if (isEditMode) {
        Get.back();
      } else {
        Get.offAllNamed(AppRoutes.home);
      }
    } catch (e) {
      Get.snackbar('Save failed', e.toString());
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    _locationDebounceWorker?.dispose();
    nameController.dispose();
    bioController.dispose();
    ageController.dispose();
    locationController.dispose();
    locationFocusNode.dispose();
    super.onClose();
  }
}
