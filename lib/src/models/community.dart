import 'package:zeytin/src/models/user.dart';

class ZeytinCommunityModel {
  final String id;
  final String name;
  final String? description;
  final String? photoURL;
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
