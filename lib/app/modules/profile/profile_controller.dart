import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:soul_matcher/app/core/constants/app_constants.dart';
import 'package:soul_matcher/app/data/models/app_user.dart';
import 'package:soul_matcher/app/data/repositories/auth_repository.dart';
import 'package:soul_matcher/app/data/repositories/user_repository.dart';
import 'package:soul_matcher/app/routes/app_routes.dart';

class ProfileController extends GetxController {
  // Disabled temporarily because Firebase Storage is not enabled on project plan.
  static const bool photoUploadEnabled = false;

  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final UserRepository _userRepository = Get.find<UserRepository>();
  final ImagePicker _imagePicker = ImagePicker();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  final RxnString selectedGender = RxnString();
  final RxnString selectedInterestedIn = RxnString();
  final RxList<String> photoUrls = <String>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;

  late final bool isEditMode;

  @override
  void onInit() {
    super.onInit();
    isEditMode =
        Get.currentRoute == AppRoutes.profileEdit ||
        ((Get.arguments as Map<String, dynamic>?)?['isEdit'] == true);
    loadCurrentProfile();
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
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickPhoto() async {
    if (!photoUploadEnabled) {
      Get.snackbar(
        'Photo upload disabled',
        'Image upload temporarily band hai.',
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
    } on FirebaseException catch (e) {
      Get.snackbar('Upload failed', _friendlyUploadError(e));
    } catch (e) {
      Get.snackbar('Upload failed', e.toString());
    } finally {
      isSaving.value = false;
    }
  }

  void removePhoto(String url) {
    photoUrls.remove(url);
  }

  String _friendlyUploadError(FirebaseException e) {
    final String code = e.code.toLowerCase();
    final String message = (e.message ?? '').toLowerCase();

    if (e.plugin == 'firebase_storage') {
      if (code == 'no-default-bucket' ||
          code == 'bucket-not-found' ||
          message.contains('storage has not been set up')) {
        return 'Firebase Storage setup pending hai. Firebase Console > Storage > Get Started karo.';
      }
      if (code == 'unauthorized') {
        return 'Storage rules upload allow nahi kar rahi. Rules deploy/check karo.';
      }
      if (code == 'network-request-failed' || code == 'retry-limit-exceeded') {
        return 'Network issue ki wajah se upload fail hua. Internet check karke retry karo.';
      }
      if (code == 'canceled') {
        return 'Upload cancel ho gaya.';
      }
    }

    return e.message ?? e.code;
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
    nameController.dispose();
    bioController.dispose();
    ageController.dispose();
    locationController.dispose();
    super.onClose();
  }
}
