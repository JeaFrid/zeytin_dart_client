import 'package:zeytin/src/models/user.dart';

enum ZeytinCommunityModelType {
  private("private"),
  privCommunity("privCommunity"),
  superCommunity("superCommunity"),
  channel("channel"),
  voiceChat("voiceChat"),
  muteChat("muteChat"),
  community("community");

  final String value;
  const ZeytinCommunityModelType(this.value);
}

ZeytinCommunityModelType? _typeFromString(String? value) {
  if (value == null) return null;
  return ZeytinCommunityModelType.values.firstWhere(
    (e) => e.value == value,
    orElse: () => ZeytinCommunityModelType.private,
  );
}

enum ZeytinRoomType {
  text("text"),
  voice("voice"),
  announcement("announcement");

  final String value;
  const ZeytinRoomType(this.value);
}

class ZeytinCommunityRoomModel {
  final String id;
  final String communityId;
  final String name;
  final ZeytinRoomType type;
  final List<String> allowedRoles;
  final DateTime createdAt;

  ZeytinCommunityRoomModel({
    required this.id,
    required this.communityId,
    required this.name,
    this.type = ZeytinRoomType.text,
    this.allowedRoles = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'communityId': communityId,
      'name': name,
      'type': type.value,
      'allowedRoles': allowedRoles,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ZeytinCommunityRoomModel.fromJson(Map<String, dynamic> json) {
    return ZeytinCommunityRoomModel(
      id: json['id'] ?? '',
      communityId: json['communityId'] ?? '',
      name: json['name'] ?? '',
      type: ZeytinRoomType.values.firstWhere(
        (e) => e.value == json['type'],
        orElse: () => ZeytinRoomType.text,
      ),
      allowedRoles: List<String>.from(json['allowedRoles'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class ZeytinCommunityInviteModel {
  final String code;
  final String communityId;
  final String creatorId;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final int? maxUses;
  final int usedCount;
  final Map<String, dynamic> moreData;

  ZeytinCommunityInviteModel({
    required this.code,
    required this.communityId,
    required this.creatorId,
    required this.createdAt,
    this.expiresAt,
    this.maxUses,
    this.usedCount = 0,
    this.moreData = const {},
  });

  factory ZeytinCommunityInviteModel.empty() {
    return ZeytinCommunityInviteModel(
      code: '',
      communityId: '',
      creatorId: '',
      createdAt: DateTime.now(),
    );
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get isQuotaExceeded {
    if (maxUses == null) return false;
    return usedCount >= maxUses!;
  }

  bool get isValid => !isExpired && !isQuotaExceeded;

  Map<String, dynamic> toJson() {
    return {
      "code": code,
      "communityId": communityId,
      "creatorId": creatorId,
      "createdAt": createdAt.toIso8601String(),
      "expiresAt": expiresAt?.toIso8601String(),
      "maxUses": maxUses,
      "usedCount": usedCount,
      "moreData": moreData,
    };
  }

  factory ZeytinCommunityInviteModel.fromJson(Map<String, dynamic> json) {
    return ZeytinCommunityInviteModel(
      code: json["code"] ?? "",
      communityId: json["communityId"] ?? "",
      creatorId: json["creatorId"] ?? "",
      createdAt: DateTime.tryParse(json["createdAt"] ?? "") ?? DateTime.now(),
      expiresAt: json["expiresAt"] != null
          ? DateTime.tryParse(json["expiresAt"])
          : null,
      maxUses: json["maxUses"],
      usedCount: json["usedCount"] ?? 0,
      moreData: json["moreData"] ?? {},
    );
  }

  ZeytinCommunityInviteModel copyWith({
    String? code,
    String? communityId,
    String? creatorId,
    DateTime? createdAt,
    DateTime? expiresAt,
    int? maxUses,
    int? usedCount,
    Map<String, dynamic>? moreData,
  }) {
    return ZeytinCommunityInviteModel(
      code: code ?? this.code,
      communityId: communityId ?? this.communityId,
      creatorId: creatorId ?? this.creatorId,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      maxUses: maxUses ?? this.maxUses,
      usedCount: usedCount ?? this.usedCount,
      moreData: moreData ?? this.moreData,
    );
  }
}

class ZeytinCommunityModel {
  final String id;
  final String name;
  final String? description;
  final String? photoURL;
  final ZeytinCommunityModelType? type;
  final DateTime createdAt;
  final List<ZeytinUserModel> participants;
  final List<ZeytinUserModel> admins;
  final String lastMessage;
  final DateTime lastMessageTimestamp;
  final ZeytinUserModel lastMessageSender;
  final int unreadCount;
  final List<ZeytinUserModel> typingUsers;
  final bool isMuted;
  final bool isArchived;
  final List<String> pinnedMessageIDs;
  final String moreData;
  final String? rules;
  final List<String> stickers;
  final String? pinnedPostID;

  ZeytinCommunityModel({
    required this.id,
    required this.name,
    this.description,
    this.type,
    this.photoURL,
    required this.createdAt,
    required this.participants,
    required this.admins,
    required this.lastMessage,
    required this.lastMessageTimestamp,
    required this.lastMessageSender,
    required this.unreadCount,
    required this.typingUsers,
    required this.isMuted,
    required this.isArchived,
    required this.pinnedMessageIDs,
    required this.moreData,
    this.rules,
    this.stickers = const [],
    this.pinnedPostID,
  });

  factory ZeytinCommunityModel.empty() {
    return ZeytinCommunityModel(
      id: '',
      name: '',
      description: null,
      type: null,
      photoURL: null,
      createdAt: DateTime.now(),
      participants: [],
      admins: [],
      lastMessage: '',
      lastMessageTimestamp: DateTime.now(),
      lastMessageSender: ZeytinUserModel.empty(),
      unreadCount: 0,
      typingUsers: [],
      isMuted: false,
      isArchived: false,
      pinnedMessageIDs: [],
      moreData: '',
      rules: null,
      stickers: [],
      pinnedPostID: null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'photoURL': photoURL,
      'type': type?.value,
      'createdAt': createdAt.toIso8601String(),
      'participants': participants.map((x) => x.toJson()).toList(),
      'admins': admins.map((x) => x.toJson()).toList(),
      'lastMessage': lastMessage,
      'lastMessageTimestamp': lastMessageTimestamp.toIso8601String(),
      'lastMessageSender': lastMessageSender.toJson(),
      'unreadCount': unreadCount,
      'typingUsers': typingUsers.map((x) => x.toJson()).toList(),
      'isMuted': isMuted,
      'isArchived': isArchived,
      'pinnedMessageIDs': pinnedMessageIDs,
      'moreData': moreData,
      'rules': rules,
      'stickers': stickers,
      'pinnedPostID': pinnedPostID,
    };
  }

  factory ZeytinCommunityModel.fromJson(Map<String, dynamic> json) {
    return ZeytinCommunityModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: _typeFromString(json['type'] as String?),
      description: json['description'],
      photoURL: json['photoURL'],
      createdAt: DateTime.parse(json['createdAt']),
      participants:
          (json['participants'] as List?)
              ?.map((x) => ZeytinUserModel.fromJson(x))
              .toList() ??
          [],
      admins:
          (json['admins'] as List?)
              ?.map((x) => ZeytinUserModel.fromJson(x))
              .toList() ??
          [],
      lastMessage: json['lastMessage'] ?? '',
      lastMessageTimestamp: DateTime.parse(json['lastMessageTimestamp']),
      lastMessageSender: ZeytinUserModel.fromJson(json['lastMessageSender']),
      unreadCount: json['unreadCount'] ?? 0,
      typingUsers:
          (json['typingUsers'] as List?)
              ?.map((x) => ZeytinUserModel.fromJson(x))
              .toList() ??
          [],
      isMuted: json['isMuted'] ?? false,
      isArchived: json['isArchived'] ?? false,
      pinnedMessageIDs: List<String>.from(json['pinnedMessageIDs'] ?? []),
      moreData: json['moreData'] ?? '',
      rules: json['rules'],
      stickers: List<String>.from(json['stickers'] ?? []),
      pinnedPostID: json['pinnedPostID'],
    );
  }

  ZeytinCommunityModel copyWith({
    String? id,
    String? name,
    String? description,
    ZeytinCommunityModelType? type,
    String? photoURL,
    DateTime? createdAt,
    List<ZeytinUserModel>? participants,
    List<ZeytinUserModel>? admins,
    String? lastMessage,
    DateTime? lastMessageTimestamp,
    ZeytinUserModel? lastMessageSender,
    int? unreadCount,
    List<ZeytinUserModel>? typingUsers,
    bool? isMuted,
    bool? isArchived,
    List<String>? pinnedMessageIDs,
    String? moreData,
    String? rules,
    List<String>? stickers,
    String? pinnedPostID,
  }) {
    return ZeytinCommunityModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt ?? this.createdAt,
      participants: participants ?? this.participants,
      admins: admins ?? this.admins,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTimestamp: lastMessageTimestamp ?? this.lastMessageTimestamp,
      lastMessageSender: lastMessageSender ?? this.lastMessageSender,
      unreadCount: unreadCount ?? this.unreadCount,
      typingUsers: typingUsers ?? this.typingUsers,
      isMuted: isMuted ?? this.isMuted,
      isArchived: isArchived ?? this.isArchived,
      pinnedMessageIDs: pinnedMessageIDs ?? this.pinnedMessageIDs,
      moreData: moreData ?? this.moreData,
      rules: rules ?? this.rules,
      stickers: stickers ?? this.stickers,
      pinnedPostID: pinnedPostID ?? this.pinnedPostID,
    );
  }
}
