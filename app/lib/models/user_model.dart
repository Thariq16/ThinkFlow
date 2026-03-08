import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String photoURL;
  final String plan; // 'free' | 'pro' | 'team'
  final String? stripeCustomerId;
  final String? stripeSubId;
  final Timestamp? planExpiresAt;
  final int voiceInputsThisMonth;
  final int projectCount;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoURL,
    this.plan = 'free',
    this.stripeCustomerId,
    this.stripeSubId,
    this.planExpiresAt,
    this.voiceInputsThisMonth = 0,
    this.projectCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoURL: data['photoURL'] ?? '',
      plan: data['plan'] ?? 'free',
      stripeCustomerId: data['stripeCustomerId'],
      stripeSubId: data['stripeSubId'],
      planExpiresAt: data['planExpiresAt'],
      voiceInputsThisMonth: data['voiceInputsThisMonth'] ?? 0,
      projectCount: data['projectCount'] ?? 0,
      createdAt: data['createdAt'],
      updatedAt: data['updatedAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'plan': plan,
      'stripeCustomerId': stripeCustomerId,
      'stripeSubId': stripeSubId,
      'planExpiresAt': planExpiresAt,
      'voiceInputsThisMonth': voiceInputsThisMonth,
      'projectCount': projectCount,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  UserModel copyWith({
    String? email,
    String? displayName,
    String? photoURL,
    String? plan,
    String? stripeCustomerId,
    String? stripeSubId,
    Timestamp? planExpiresAt,
    int? voiceInputsThisMonth,
    int? projectCount,
  }) {
    return UserModel(
      uid: uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      plan: plan ?? this.plan,
      stripeCustomerId: stripeCustomerId ?? this.stripeCustomerId,
      stripeSubId: stripeSubId ?? this.stripeSubId,
      planExpiresAt: planExpiresAt ?? this.planExpiresAt,
      voiceInputsThisMonth: voiceInputsThisMonth ?? this.voiceInputsThisMonth,
      projectCount: projectCount ?? this.projectCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  bool get isFree => plan == 'free';
  bool get isPro => plan == 'pro';
  bool get isTeam => plan == 'team';
  bool get hasProAccess => isPro || isTeam;
}
