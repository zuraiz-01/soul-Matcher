import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:soul_matcher/app/data/models/app_user.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Future<void> createUserIfNotExists(User firebaseUser) async {
    final DocumentReference<Map<String, dynamic>> ref = _users.doc(
      firebaseUser.uid,
    );
    final DocumentSnapshot<Map<String, dynamic>> snapshot = await ref.get();
    if (snapshot.exists) return;

    await ref.set(<String, dynamic>{
      'uid': firebaseUser.uid,
      'email': firebaseUser.email ?? '',
      'displayName': firebaseUser.displayName ?? '',
      'bio': '',
      'age': null,
      'gender': null,
      'interestedIn': null,
      'location': '',
      'photos': <String>[],
      'onboardingCompleted': false,
      'profileCompleted': false,
      'fcmToken': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<AppUser?> streamUser(String uid) {
    return _users.doc(uid).snapshots().map((
      DocumentSnapshot<Map<String, dynamic>> doc,
    ) {
      final Map<String, dynamic>? data = doc.data();
      if (data == null) return null;
      return AppUser.fromMap(data, doc.id);
    });
  }

  Future<AppUser?> getUser(String uid) async {
    final DocumentSnapshot<Map<String, dynamic>> doc = await _users
        .doc(uid)
        .get();
    final Map<String, dynamic>? data = doc.data();
    if (data == null) return null;
    return AppUser.fromMap(data, doc.id);
  }

  Future<void> markOnboardingComplete(String uid) {
    return _users.doc(uid).update(<String, dynamic>{
      'onboardingCompleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateProfile({
    required String uid,
    required String displayName,
    required String bio,
    required int age,
    required String gender,
    required String interestedIn,
    required String location,
    required List<String> photos,
  }) {
    return _users.doc(uid).set(<String, dynamic>{
      'displayName': displayName,
      'bio': bio,
      'age': age,
      'gender': gender,
      'interestedIn': interestedIn,
      'location': location,
      'photos': photos,
      'profileCompleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<String> uploadProfilePhoto({
    required String uid,
    required XFile file,
  }) async {
    final Uint8List bytes = await file.readAsBytes();
    final Reference ref = _storage.ref(
      'users/$uid/photos/${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    final UploadTask uploadTask = ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    await uploadTask.whenComplete(() => null);
    return ref.getDownloadURL();
  }

  Future<void> updateFcmToken({required String uid, required String token}) {
    return _users.doc(uid).set(<String, dynamic>{
      'fcmToken': token,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteUser(String uid) async {
    await _users.doc(uid).delete();
  }
}
