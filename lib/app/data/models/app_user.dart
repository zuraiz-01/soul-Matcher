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
    this.subscriptionPlan = 'free',
    this.referralCode = '',
    this.referredByUid,
    this.referredByCode,
    this.referralPoints = 0,
    this.totalReferralPointsEarned = 0,
    this.totalReferralPayoutPoints = 0,
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
  final String subscriptionPlan;
  final String referralCode;
  final String? referredByUid;
  final String? referredByCode;
  final int referralPoints;
  final int totalReferralPointsEarned;
  final int totalReferralPayoutPoints;
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
      subscriptionPlan: map['subscriptionPlan'] as String? ?? 'free',
      referralCode: map['referralCode'] as String? ?? '',
      referredByUid: map['referredByUid'] as String?,
      referredByCode: map['referredByCode'] as String?,
      referralPoints: (map['referralPoints'] as num?)?.toInt() ?? 0,
      totalReferralPointsEarned:
          (map['totalReferralPointsEarned'] as num?)?.toInt() ?? 0,
      totalReferralPayoutPoints:
          (map['totalReferralPayoutPoints'] as num?)?.toInt() ?? 0,
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
    'subscriptionPlan': subscriptionPlan,
    'referralCode': referralCode,
    'referredByUid': referredByUid,
    'referredByCode': referredByCode,
    'referralPoints': referralPoints,
    'totalReferralPointsEarned': totalReferralPointsEarned,
    'totalReferralPayoutPoints': totalReferralPayoutPoints,
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
    String? subscriptionPlan,
    String? referralCode,
    String? referredByUid,
    String? referredByCode,
    int? referralPoints,
    int? totalReferralPointsEarned,
    int? totalReferralPayoutPoints,
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
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      referralCode: referralCode ?? this.referralCode,
      referredByUid: referredByUid ?? this.referredByUid,
      referredByCode: referredByCode ?? this.referredByCode,
      referralPoints: referralPoints ?? this.referralPoints,
      totalReferralPointsEarned:
          totalReferralPointsEarned ?? this.totalReferralPointsEarned,
      totalReferralPayoutPoints:
          totalReferralPayoutPoints ?? this.totalReferralPayoutPoints,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
