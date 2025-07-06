// lib/models/user_model.dart
class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? username;
  final String? profilePictureUrl;
  final String? bio;
  final bool onboardingCompleted;

  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.username,
    this.profilePictureUrl,
    this.bio,
    required this.onboardingCompleted,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? 'Unknown User',
      username: json['username']?.toString(),
      profilePictureUrl: json['profile_picture_url']?.toString(),
      bio: json['bio']?.toString(),
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'username': username,
      'profile_picture_url': profilePictureUrl,
      'bio': bio,
      'onboarding_completed': onboardingCompleted,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? username,
    String? profilePictureUrl,
    String? bio,
    bool? onboardingCompleted,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      bio: bio ?? this.bio,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.id == id &&
        other.email == email &&
        other.displayName == displayName &&
        other.username == username &&
        other.profilePictureUrl == profilePictureUrl &&
        other.bio == bio &&
        other.onboardingCompleted == onboardingCompleted;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      email,
      displayName,
      username,
      profilePictureUrl,
      bio,
      onboardingCompleted,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, displayName: $displayName, username: $username, profilePictureUrl: $profilePictureUrl, bio: $bio, onboardingCompleted: $onboardingCompleted)';
  }
}