import 'package:zeytin/src/models/user.dart';

class ZeytinCommunityBoardPostModel {
  final String id;
  final String communityId;
  final ZeytinUserModel sender;
  final String text;
  final String? imageURL;
  final List<String> seenBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> moreData;

  ZeytinCommunityBoardPostModel({
    required this.id,
    required this.communityId,
    required this.sender,
    required this.text,
    this.imageURL,
    required this.seenBy,
    required this.createdAt,
    this.updatedAt,
    required this.moreData,
  });

  factory ZeytinCommunityBoardPostModel.empty() {
    return ZeytinCommunityBoardPostModel(
      id: '',
      communityId: '',
      sender: ZeytinUserModel.empty(),
      text: '',
      seenBy: [],
      createdAt: DateTime.now(),
      moreData: {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'communityId': communityId,
      'sender': sender.toJson(),
      'text': text,
      'imageURL': imageURL,
      'seenBy': seenBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'moreData': moreData,
    };
  }

  factory ZeytinCommunityBoardPostModel.fromJson(Map<String, dynamic> json) {
    return ZeytinCommunityBoardPostModel(
      id: json['id'] ?? '',
      communityId: json['communityId'] ?? '',
      sender: ZeytinUserModel.fromJson(json['sender']),
      text: json['text'] ?? '',
      imageURL: json['imageURL'],
      seenBy: List<String>.from(json['seenBy'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      moreData: json['moreData'] ?? {},
    );
  }

  ZeytinCommunityBoardPostModel copyWith({
    String? id,
    String? communityId,
    ZeytinUserModel? sender,
    String? text,
    String? imageURL,
    List<String>? seenBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? moreData,
  }) {
    return ZeytinCommunityBoardPostModel(
      id: id ?? this.id,
      communityId: communityId ?? this.communityId,
      sender: sender ?? this.sender,
      text: text ?? this.text,
      imageURL: imageURL ?? this.imageURL,
      seenBy: seenBy ?? this.seenBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      moreData: moreData ?? this.moreData,
    );
  }
}
