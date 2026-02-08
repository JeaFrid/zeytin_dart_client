class ZeytinUserModel {
  final String username;
  final String uid;
  final String email;
  final String emailVerified;
  final String password;
  final String role;
  final String firstName;
  final String lastName;
  final String displayName;
  final String avatarUrl;
  final String gender;
  final String dateOfBirth;
  final String biography;
  final String preferredLanguage;
  final String timezone;
  final String school;
  final List<String> following;
  final List<String> followers;
  final String accountStatus;
  final String accountUpdated;
  final String accountCreation;
  final String accountType;
  final String lastLoginTimestamp;
  final String lastLoginIp;
  final List<String> socialMedias;
  final String theme;
  final String street;
  final String city;
  final String postalCode;
  final String country;
  final String locale;
  final List<String> posts;
  final List<String> blockedUsers;
  final String createdBy;
  final String job;
  final String updatedBy;
  final String version;
  final Map<String, dynamic> data;

  ZeytinUserModel({
    required this.username,
    required this.uid,
    required this.email,
    required this.job,
    required this.emailVerified,
    required this.password,
    required this.school,
    required this.role,
    required this.firstName,
    required this.lastName,
    required this.displayName,
    required this.avatarUrl,
    required this.gender,
    required this.dateOfBirth,
    required this.biography,
    required this.preferredLanguage,
    required this.timezone,
    required this.accountStatus,
    required this.accountUpdated,
    required this.accountCreation,
    required this.accountType,
    required this.lastLoginTimestamp,
    required this.lastLoginIp,
    required this.socialMedias,
    required this.theme,
    required this.street,
    required this.city,
    required this.postalCode,
    required this.country,
    required this.locale,
    required this.posts,
    required this.createdBy,
    required this.updatedBy,
    required this.version,
    required this.data,
    required this.following,
    required this.followers,
    required this.blockedUsers,
  });

  factory ZeytinUserModel.empty() {
    return ZeytinUserModel(
      username: '',
      uid: '',
      school: "",
      followers: [],
      following: [],
      email: '',
      blockedUsers: [],
      emailVerified: '',
      password: '',
      role: '',
      job: '',
      firstName: '',
      lastName: '',
      displayName: '',
      avatarUrl: '',
      gender: '',
      dateOfBirth: '',
      biography: '',
      preferredLanguage: '',
      timezone: '',
      accountStatus: '',
      accountUpdated: '',
      accountCreation: '',
      accountType: '',
      lastLoginTimestamp: '',
      lastLoginIp: '',
      socialMedias: [],
      theme: '',
      street: '',
      city: '',
      postalCode: '',
      country: '',
      locale: '',
      posts: [],
      createdBy: '',
      updatedBy: '',
      version: '',
      data: {},
    );
  }

  factory ZeytinUserModel.fromJson(Map<String, dynamic> json) {
    String s(dynamic v) {
      if (v == null) return '';
      return v.toString();
    }

    List<String> l(dynamic v) {
      if (v == null || v is! List) return <String>[];
      return v.map((e) => e.toString()).toList().cast<String>();
    }

    return ZeytinUserModel(
      username: s(json['username']),
      uid: s(json['uid']),
      email: s(json['email']),
      school: s(json['school']),
      job: s(json['job']),
      emailVerified: s(json['email_verified']),
      password: s(json['password']),
      blockedUsers: l(json['blockedUsers']),
      role: s(json['role']),
      firstName: s(json['first_name']),
      lastName: s(json['last_name']),
      displayName: s(json['display_name']),
      avatarUrl: s(json['avatar_url']),
      gender: s(json['gender']),
      dateOfBirth: s(json['date_of_birth']),
      biography: s(json['biography']),
      preferredLanguage: s(json['preferred_language']),
      timezone: s(json['timezone']),
      accountStatus: s(json['account_status']),
      accountUpdated: s(json['account_updated']),
      accountCreation: s(json['account_creation']),
      accountType: s(json['account_type']),
      lastLoginTimestamp: s(json['last_login_timestamp']),
      lastLoginIp: s(json['last_login_ip']),
      socialMedias: l(json['social_medias']),
      followers: l(json['followers']),
      following: l(json['following']),
      theme: s(json['theme']),
      street: s(json['street']),
      city: s(json['city']),
      postalCode: s(json['postal_code']),
      country: s(json['country']),
      locale: s(json['locale']),
      posts: l(json['posts']),
      createdBy: s(json['created_by']),
      updatedBy: s(json['updated_by']),
      version: s(json['version']),
      data: json['data'] is Map ? Map<String, dynamic>.from(json['data']) : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'uid': uid,
      'email': email,
      'email_verified': emailVerified,
      'password': password,
      'followers': followers,
      'following': following,
      'role': role,
      'first_name': firstName,
      'last_name': lastName,
      'blockedUsers': blockedUsers,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'gender': gender,
      'date_of_birth': dateOfBirth,
      'biography': biography,
      'preferred_language': preferredLanguage,
      'timezone': timezone,
      'account_status': accountStatus,
      'job': job,
      'school': school,
      'account_updated': accountUpdated,
      'account_creation': accountCreation,
      'account_type': accountType,
      'last_login_timestamp': lastLoginTimestamp,
      'last_login_ip': lastLoginIp,
      'social_medias': socialMedias,
      'theme': theme,
      'street': street,
      'city': city,
      'postal_code': postalCode,
      'country': country,
      'locale': locale,
      'posts': posts,
      'created_by': createdBy,
      'updated_by': updatedBy,
      'version': version,
      'data': data,
    };
  }

  ZeytinUserModel copyWith({
    String? username,
    String? uid,
    String? email,
    String? emailVerified,
    String? password,
    String? role,
    String? firstName,
    String? job,
    String? lastName,
    String? displayName,
    String? avatarUrl,
    List<String>? blockedUsers,
    String? gender,
    String? dateOfBirth,
    String? biography,
    String? preferredLanguage,
    String? timezone,
    String? accountStatus,
    String? accountUpdated,
    String? accountCreation,
    String? accountType,
    String? lastLoginTimestamp,
    String? lastLoginIp,
    List<String>? socialMedias,
    String? theme,
    String? street,
    String? city,
    List<String>? following,
    List<String>? followers,
    String? postalCode,
    String? country,
    String? school,
    String? locale,
    List<String>? posts,
    String? createdBy,
    String? updatedBy,
    String? version,
    Map<String, dynamic>? data,
  }) {
    return ZeytinUserModel(
      uid: uid ?? this.uid,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      username: username ?? this.username,
      email: email ?? this.email,
      job: job ?? this.job,
      emailVerified: emailVerified ?? this.emailVerified,
      school: school ?? this.school,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      password: password ?? this.password,
      role: role ?? this.role,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      biography: biography ?? this.biography,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      timezone: timezone ?? this.timezone,
      accountStatus: accountStatus ?? this.accountStatus,
      accountUpdated: accountUpdated ?? this.accountUpdated,
      accountCreation: accountCreation ?? this.accountCreation,
      accountType: accountType ?? this.accountType,
      lastLoginTimestamp: lastLoginTimestamp ?? this.lastLoginTimestamp,
      lastLoginIp: lastLoginIp ?? this.lastLoginIp,
      socialMedias: socialMedias ?? this.socialMedias,
      theme: theme ?? this.theme,
      street: street ?? this.street,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      locale: locale ?? this.locale,
      posts: posts ?? this.posts,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      version: version ?? this.version,
      data: data != null
          ? Map<String, dynamic>.from(data)
          : Map<String, dynamic>.from(this.data),
    );
  }
}
