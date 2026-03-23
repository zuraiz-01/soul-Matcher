import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    this.displayName = '',
    this.bio = '',
    this.age,
    this.gender,
    this.interestedIn,
    this.location = '',
    this.photos = const <String>[],
    this.onboardingCompleted = false,
    this.profileCompleted = false,
    this.fcmToken,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String email;
  final String displayName;
  final String bio;
  final int? age;
  final String? gender;
  final String? interestedIn;
  final String location;
  final List<String> photos;
  final bool onboardingCompleted;
  final bool profileCompleted;
  final String? fcmToken;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AppUser.fromMap(Map<String, dynamic> map, String docId) {
    DateTime? parseTimestamp(dynamic value) {
      if (value is Timestamp) return value.toDate();
      return null;
    }

    return AppUser(
      uid: map['uid'] as String? ?? docId,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      bio: map['bio'] as String? ?? '',
      age: map['age'] as int?,
      gender: map['gender'] as String?,
      interestedIn: map['interestedIn'] as String?,
      location: map['location'] as String? ?? '',
      photos: ((map['photos'] as List<dynamic>?) ?? <dynamic>[])
          .map((dynamic value) => value.toString())
          .toList(),
      onboardingCompleted: map['onboardingCompleted'] as bool? ?? false,
      profileCompleted: map['profileCompleted'] as bool? ?? false,
      fcmToken: map['fcmToken'] as String?,
      createdAt: parseTimestamp(map['createdAt']),
      updatedAt: parseTimestamp(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'uid': uid,
    'email': email,
    'displayName': displayName,
    'bio': bio,
    'age': age,
    'gender': gender,
    'interestedIn': interestedIn,
    'location': location,
    'photos': photos,
    'onboardingCompleted': onboardingCompleted,
    'profileCompleted': profileCompleted,
    'fcmToken': fcmToken,
    'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
    'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
  };

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? bio,
    int? age,
    String? gender,
    String? interestedIn,
    String? location,
    List<String>? photos,
    bool? onboardingCompleted,
    bool? profileCompleted,
    String? fcmToken,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      interestedIn: interestedIn ?? this.interestedIn,
      location: location ?? this.location,
      photos: photos ?? this.photos,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
