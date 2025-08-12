// In your user.dart file
enum Gender {
  male,
  female,
  preferNotToSay;

  String toDatabaseString() {
    switch (this) {
      case Gender.male:
        return 'male';
      case Gender.female:
        return 'female';
      case Gender.preferNotToSay:
        return 'prefer_not_to_say';
    }
  }
}

class UserModel {
  final String uid;
  final String username;
  final String name;
  final Gender gender;
  final String? email;
  final String? phoneNumber;
  final String? profileImageUrl;
  final String? state;
  final String? city;
  final DateTime createdAt;
  final DateTime? birthdate;
  final bool isVIP;
  final bool isPrivate;
  final bool isOnline;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final String? bio;
  final String? token;
  final List<String> followers;
  final List<String> following;
  final List<String> requests;
  final List<String> interests;
  final int postCount;
  final int guideCount;
  final int totalLikes;
  final int guideCountMnt;
  final double avgGuideReview;
  final bool isDev;
  final List<String> bookmarkedPlaces;
  final String? coverImageUrl;
  final bool allowRequests;
  final bool publicMessage;
  final bool termsAccepted;

  UserModel({
    required this.uid,
    required this.username,
    String? name,
    this.gender = Gender.preferNotToSay,
    this.email,
    this.phoneNumber,
    this.profileImageUrl,
    this.coverImageUrl,
    required this.createdAt,
    this.birthdate,
    this.state,
    this.city,
    this.isVIP = false,
    this.isPrivate = false,
    this.isOnline = false,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.bio,
    this.token,
    List<String>? followers,
    List<String>? following,
    List<String>? requests,
    List<String>? interests,
    this.postCount = 0,
    this.totalLikes = 0,
    this.guideCountMnt = 0,
    this.guideCount = 0,
    this.avgGuideReview = 0,
    this.isDev = false,
    List<String>? bookmarkedPlaces,
    this.allowRequests = true,
    this.publicMessage = true,
    this.termsAccepted = false,
  })  : bookmarkedPlaces = bookmarkedPlaces ?? [],
        name = name ?? username,
        followers = followers ?? [],
        requests = requests ?? [],
        interests = interests ?? [],
        following = following ?? [];

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      username: map['username'] ?? '',
      name: map['name'],
      gender: _parseGender(map['gender']),
      email: map['email'],
      phoneNumber: map['phone_number'],
      profileImageUrl: map['profile_image_url'],
      coverImageUrl: map['cover_image_url'],
      state: map['state'],
      city: map['city'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      birthdate:
          map['birthdate'] != null ? DateTime.parse(map['birthdate']) : null,
      isVIP: map['is_vip'] ?? false,
      isPrivate: map['is_private'] ?? false,
      isOnline: map['is_online'] ?? false,
      isEmailVerified: map['is_email_verified'] ?? false,
      isPhoneVerified: map['is_phone_verified'] ?? false,
      bio: map['bio'],
      token: map['token'],
      followers: List<String>.from(map['followers'] ?? []),
      requests: List<String>.from(map['requests'] ?? []),
      following: List<String>.from(map['following'] ?? []),
      interests: List<String>.from(map['interests'] ?? []),
      postCount: map['post_count'] ?? 0,
      guideCount: map['guide_count'] ?? 0,
      totalLikes: map['total_likes'] ?? 0,
      guideCountMnt: map['guide_count_mnt'] ?? 0,
      avgGuideReview: (map['avg_guide_review'] ?? 0).toDouble(),
      isDev: map['is_dev'] ?? false,
      bookmarkedPlaces: List<String>.from(map['bookmarked_places'] ?? []),
      allowRequests: map['allow_requests'] ?? true,
      publicMessage: map['public_message'] ?? true,
      termsAccepted: map['terms_accepted'] ?? false,
    );
  }

  static Gender _parseGender(String? value) {
    switch (value?.toLowerCase()) {
      case 'male':
        return Gender.male;
      case 'female':
        return Gender.female;
      default:
        return Gender.preferNotToSay;
    }
  }

  String get genderString {
    switch (gender) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
      case Gender.preferNotToSay:
        return 'Prefer not to say';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'name': name,
      'gender': genderString.toLowerCase(),
      'email': email,
      'phone_number': phoneNumber,
      'profile_image_url': profileImageUrl,
      'cover_image_url': coverImageUrl,
      'state': state,
      'city': city,
      'created_at': createdAt.toIso8601String(),
      'birthdate': birthdate?.toIso8601String(),
      'is_vip': isVIP,
      'is_private': isPrivate,
      'is_online': isOnline,
      'is_email_verified': isEmailVerified,
      'is_phone_verified': isPhoneVerified,
      'bio': bio,
      'token': token,
      'followers': followers,
      'requests': requests,
      'following': following,
      'interests': interests,
      'post_count': postCount,
      'guide_count': guideCount,
      'total_likes': totalLikes,
      'guide_count_mnt': guideCountMnt,
      'avg_guide_review': avgGuideReview,
      'is_dev': isDev,
      'bookmarked_places': bookmarkedPlaces,
      'allow_requests': allowRequests,
      'public_message': publicMessage,
      'terms_accepted': termsAccepted,
    };
  }

  UserModel copyWith({
    String? username,
    String? name,
    Gender? gender,
    String? email,
    String? phoneNumber,
    String? profileImageUrl,
    String? coverImageUrl,
    String? state,
    String? city,
    DateTime? birthdate,
    bool? isVIP,
    bool? isPrivate,
    bool? isOnline,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    String? bio,
    String? token,
    List<String>? followers,
    List<String>? requests,
    List<String>? following,
    List<String>? interests,
    int? postCount,
    int? guideCount,
    int? totalLikes,
    int? guideCountMnt,
    double? avgGuideReview,
    bool? isDev,
    List<String>? bookmarkedPlaces,
    bool? allowRequests,
    bool? publicMessage,
    bool? termsAccepted,
  }) {
    return UserModel(
      uid: uid,
      username: username ?? this.username,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      state: state ?? this.state,
      city: city ?? this.city,
      createdAt: createdAt,
      birthdate: birthdate ?? this.birthdate,
      isVIP: isVIP ?? this.isVIP,
      isPrivate: isPrivate ?? this.isPrivate,
      isOnline: isOnline ?? this.isOnline,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      bio: bio ?? this.bio,
      token: token ?? this.token,
      followers: followers ?? this.followers,
      requests: requests ?? this.requests,
      following: following ?? this.following,
      interests: interests ?? this.interests,
      postCount: postCount ?? this.postCount,
      guideCount: guideCount ?? this.guideCount,
      guideCountMnt: guideCountMnt ?? this.guideCountMnt,
      totalLikes: totalLikes ?? this.totalLikes,
      avgGuideReview: avgGuideReview ?? this.avgGuideReview,
      isDev: isDev ?? this.isDev,
      bookmarkedPlaces: bookmarkedPlaces ?? this.bookmarkedPlaces,
      allowRequests: allowRequests ?? this.allowRequests,
      publicMessage: publicMessage ?? this.publicMessage,
      termsAccepted: termsAccepted ?? this.termsAccepted,
    );
  }

  bool isPlaceBookmarked(String placeId) => bookmarkedPlaces.contains(placeId);

  bool isFollowing(String userId) => following.contains(userId);
  bool isFollowedBy(String userId) => followers.contains(userId);
  int get followersCount => followers.length;
  int get followingCount => following.length;
}
