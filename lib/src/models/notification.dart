enum ZeytinNotificationMediaType {
  small("small"),
  big("big");

  final String value;
  const ZeytinNotificationMediaType(this.value);
}

class ZeytinNotificationMediaModel {
  final String url;
  final ZeytinNotificationMediaType type;

  ZeytinNotificationMediaModel({
    required this.url,
    this.type = ZeytinNotificationMediaType.small,
  });

  Map<String, dynamic> toJson() {
    return {'url': url, 'type': type.value};
  }

  factory ZeytinNotificationMediaModel.fromJson(Map<String, dynamic> json) {
    return ZeytinNotificationMediaModel(
      url: json['url'] ?? '',
      type: ZeytinNotificationMediaType.values.firstWhere(
        (e) => e.value == json['type'],
        orElse: () => ZeytinNotificationMediaType.small,
      ),
    );
  }
}

class ZeytinNotificationModel {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final List<String> targetUserIds;
  final List<ZeytinNotificationMediaModel> media;
  final String type;
  final List<String> seenBy;
  final bool isInApp;
  final String? inAppTag;
  final Map<String, dynamic> moreData;

  ZeytinNotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.targetUserIds,
    this.media = const [],
    required this.type,
    this.seenBy = const [],
    this.isInApp = false,
    this.inAppTag,
    this.moreData = const {},
  });

  factory ZeytinNotificationModel.empty() {
    return ZeytinNotificationModel(
      id: '',
      title: '',
      description: '',
      createdAt: DateTime.now(),
      targetUserIds: [],
      type: 'general',
    );
  }

  bool isSeen(String userId) => seenBy.contains(userId);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'targetUserIds': targetUserIds,
      'media': media.map((e) => e.toJson()).toList(),
      'type': type,
      'seenBy': seenBy,
      'isInApp': isInApp,
      'inAppTag': inAppTag,
      'moreData': moreData,
    };
  }

  factory ZeytinNotificationModel.fromJson(Map<String, dynamic> json) {
    return ZeytinNotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      targetUserIds: List<String>.from(json['targetUserIds'] ?? []),
      media:
          (json['media'] as List?)
              ?.map((e) => ZeytinNotificationMediaModel.fromJson(e))
              .toList() ??
          [],
      type: json['type'] ?? 'general',
      seenBy: List<String>.from(json['seenBy'] ?? []),
      isInApp: json['isInApp'] ?? false,
      inAppTag: json['inAppTag'],
      moreData: json['moreData'] ?? {},
    );
  }

  ZeytinNotificationModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
    List<String>? targetUserIds,
    List<ZeytinNotificationMediaModel>? media,
    String? type,
    List<String>? seenBy,
    bool? isInApp,
    String? inAppTag,
    Map<String, dynamic>? moreData,
  }) {
    return ZeytinNotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      targetUserIds: targetUserIds ?? this.targetUserIds,
      media: media ?? this.media,
      type: type ?? this.type,
      seenBy: seenBy ?? this.seenBy,
      isInApp: isInApp ?? this.isInApp,
      inAppTag: inAppTag ?? this.inAppTag,
      moreData: moreData ?? this.moreData,
    );
  }
}
