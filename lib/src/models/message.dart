import 'package:zeytin/src/models/user.dart';

enum ZeytinChatType {
  private("private"),
  privGroup("privGroup"),
  superGroup("superGroup"),
  channel("channel"),
  voiceChat("voiceChat"),
  muteChat("muteChat"),
  group("group");

  final String value;
  const ZeytinChatType(this.value);
}

enum ZeytinMessageType {
  text("text"),
  image("image"),
  video("video"),
  audio("audio"),
  file("file"),
  location("location"),
  contact("contact"),
  sticker("sticker"),
  system("system");

  final String value;
  const ZeytinMessageType(this.value);
}

enum ZeytinMessageStatus {
  sending("sending"),
  sent("sent"),
  delivered("delivered"),
  read("read"),
  failed("failed");

  final String value;
  const ZeytinMessageStatus(this.value);
}

enum ZeytinSystemMessageType {
  userJoined("user_joined"),
  userLeft("user_left"),
  groupCreated("group_created"),
  nameChanged("name_changed"),
  photoChanged("photo_changed"),
  adminAdded("admin_added"),
  adminRemoved("admin_removed"),
  callStarted("call_started"),
  callEnded("call_ended"),
  callMissed("call_missed"),
  callRejected("call_rejected"),
  callBusy("call_busy"),
  callCanceled("call_canceled"),
  videoCallStarted("video_call_started"),
  audioCallStarted("audio_call_started"),
  messagePinned("message_pinned"),
  messageUnpinned("message_unpinned"),
  chatSecured("chat_secured"),
  disappearingTimerChanged("disappearing_timer_changed"),
  none("none");

  final String value;
  const ZeytinSystemMessageType(this.value);
}

class ZeytinMediaDimensionsModel {
  final int width;
  final int height;

  ZeytinMediaDimensionsModel({required this.width, required this.height});

  Map<String, dynamic> toJson() => {'width': width, 'height': height};
  factory ZeytinMediaDimensionsModel.fromJson(Map<String, dynamic> json) {
    return ZeytinMediaDimensionsModel(
      width: json['width'] ?? 0,
      height: json['height'] ?? 0,
    );
  }
}

class ZeytinMediaModel {
  final String url;
  final String? thumbnailUrl;
  final int? fileSize;
  final String fileName;
  final String mimeType;
  final Duration? duration;
  final ZeytinMediaDimensionsModel? dimensions;

  ZeytinMediaModel({
    required this.url,
    this.thumbnailUrl,
    this.fileSize,
    required this.fileName,
    required this.mimeType,
    this.duration,
    this.dimensions,
  });

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'thumbnailUrl': thumbnailUrl,
      'fileSize': fileSize,
      'fileName': fileName,
      'mimeType': mimeType,
      'duration': duration?.inMilliseconds,
      'dimensions': dimensions?.toJson(),
    };
  }

  factory ZeytinMediaModel.fromJson(Map<String, dynamic> json) {
    return ZeytinMediaModel(
      url: json['url'] ?? '',
      thumbnailUrl: json['thumbnailUrl'],
      fileSize: json['fileSize'],
      fileName: json['fileName'] ?? '',
      mimeType: json['mimeType'] ?? '',
      duration: json['duration'] != null
          ? Duration(milliseconds: json['duration'])
          : null,
      dimensions: json['dimensions'] != null
          ? ZeytinMediaDimensionsModel.fromJson(json['dimensions'])
          : null,
    );
  }
}

class ZeytinLocationModel {
  final double latitude;
  final double longitude;
  final String? name;
  final String? address;

  ZeytinLocationModel({
    required this.latitude,
    required this.longitude,
    this.name,
    this.address,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'name': name,
      'address': address,
    };
  }

  factory ZeytinLocationModel.fromJson(Map<String, dynamic> json) {
    return ZeytinLocationModel(
      latitude: json['latitude'] ?? 0.0,
      longitude: json['longitude'] ?? 0.0,
      name: json['name'],
      address: json['address'],
    );
  }
}

class ZeytinContactModel {
  final String name;
  final String? phoneNumber;
  final String? email;

  ZeytinContactModel({required this.name, this.phoneNumber, this.email});

  Map<String, dynamic> toJson() {
    return {'name': name, 'phoneNumber': phoneNumber, 'email': email};
  }

  factory ZeytinContactModel.fromJson(Map<String, dynamic> json) {
    return ZeytinContactModel(
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'],
      email: json['email'],
    );
  }
}

class ZeytinReactionModel {
  final String emoji;
  final String userId;
  final DateTime timestamp;

  ZeytinReactionModel({
    required this.emoji,
    required this.userId,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'emoji': emoji,
      'userId': userId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ZeytinReactionModel.fromJson(Map<String, dynamic> json) {
    return ZeytinReactionModel(
      emoji: json['emoji'] ?? '',
      userId: json['userId'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class ZeytinMessageReactionsModel {
  final Map<String, List<ZeytinReactionModel>> reactions;

  ZeytinMessageReactionsModel({
    Map<String, List<ZeytinReactionModel>>? reactions,
  }) : reactions = reactions ?? {};

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> result = {};
    reactions.forEach((emoji, reactionList) {
      result[emoji] = reactionList.map((r) => r.toJson()).toList();
    });
    return result;
  }

  factory ZeytinMessageReactionsModel.fromJson(Map<String, dynamic> json) {
    final Map<String, List<ZeytinReactionModel>> reactionsMap = {};
    json.forEach((emoji, reactionData) {
      if (reactionData is List) {
        reactionsMap[emoji] = reactionData
            .map<ZeytinReactionModel>(
              (item) => ZeytinReactionModel.fromJson(item),
            )
            .toList();
      }
    });
    return ZeytinMessageReactionsModel(reactions: reactionsMap);
  }
}

class ZeytinMessageStatusInfoModel {
  final List<String> deliveredTo;
  final List<String> readBy;
  final DateTime? deliveredAt;
  final DateTime? readAt;

  ZeytinMessageStatusInfoModel({
    List<String>? deliveredTo,
    List<String>? readBy,
    this.deliveredAt,
    this.readAt,
  }) : deliveredTo = deliveredTo ?? [],
       readBy = readBy ?? [];

  Map<String, dynamic> toJson() {
    return {
      'deliveredTo': deliveredTo,
      'readBy': readBy,
      'deliveredAt': deliveredAt?.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
    };
  }

  ZeytinMessageStatusInfoModel copyWith({
    List<String>? deliveredTo,
    List<String>? readBy,
    DateTime? deliveredAt,
    DateTime? readAt,
  }) {
    return ZeytinMessageStatusInfoModel(
      deliveredTo: deliveredTo ?? this.deliveredTo,
      readBy: readBy ?? this.readBy,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
    );
  }

  factory ZeytinMessageStatusInfoModel.fromJson(Map<String, dynamic> json) {
    return ZeytinMessageStatusInfoModel(
      deliveredTo: json['deliveredTo'] != null
          ? List<String>.from(json['deliveredTo'])
          : [],
      readBy: json['readBy'] != null ? List<String>.from(json['readBy']) : [],
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.tryParse(json['deliveredAt'])
          : null,
      readAt: json['readAt'] != null ? DateTime.tryParse(json['readAt']) : null,
    );
  }
}

class ZeytinSystemMessageDataModel {
  final ZeytinSystemMessageType type;
  final String? userId;
  final String? userName;
  final String? oldValue;
  final String? value;

  ZeytinSystemMessageDataModel({
    required this.type,
    this.userId,
    this.userName,
    this.oldValue,
    this.value,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.value,
      'userId': userId,
      'userName': userName,
      'oldValue': oldValue,
      'value': value,
    };
  }

  factory ZeytinSystemMessageDataModel.fromJson(Map<String, dynamic> json) {
    return ZeytinSystemMessageDataModel(
      type: ZeytinSystemMessageType.values.firstWhere(
        (e) => e.value == json['type'],
        orElse: () => ZeytinSystemMessageType.none,
      ),
      userId: json['userId'],
      userName: json['userName'],
      oldValue: json['oldValue'],
      value: json['value'],
    );
  }
}

class ZeytinInteractiveButtonModel {
  final String id;
  final String text;
  final String type;
  final String? payload;

  ZeytinInteractiveButtonModel({
    required this.id,
    required this.text,
    required this.type,
    this.payload,
  });

  Map<String, dynamic> toJson() {
    return {'id': id, 'text': text, 'type': type, 'payload': payload};
  }

  factory ZeytinInteractiveButtonModel.fromJson(Map<String, dynamic> json) {
    return ZeytinInteractiveButtonModel(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      type: json['type'] ?? '',
      payload: json['payload'],
    );
  }
}

class ZeytinBotModel {
  final String botId;
  final String botName;

  ZeytinBotModel({required this.botId, required this.botName});

  static ZeytinBotModel empty() => ZeytinBotModel(botId: '', botName: '');

  Map<String, dynamic> toJson() => {'botId': botId, 'botName': botName};

  factory ZeytinBotModel.fromJson(Map<String, dynamic> json) {
    return ZeytinBotModel(
      botId: json['botId'] ?? '',
      botName: json['botName'] ?? '',
    );
  }
}

class ZeytinChatModel {
  final String chatID;
  final ZeytinChatType type;
  final DateTime createdAt;
  final String chatName;
  final String chatPhotoURL;
  final Map<String, dynamic> themeSettings;
  final List<ZeytinUserModel> participants;
  final List<ZeytinUserModel> admins;
  final String lastMessage;
  final DateTime lastMessageTimestamp;
  final ZeytinUserModel lastMessageSender;
  final int unreadCount;
  final List<ZeytinUserModel> typingUsers;
  final List<ZeytinBotModel> bots;
  final bool isMuted;
  final bool isArchived;
  final bool isBlocked;
  final List<String> pinnedMessageIDs;
  final String moreData;

  ZeytinChatModel({
    required this.chatID,
    required this.type,
    required this.createdAt,
    required this.chatName,
    required this.chatPhotoURL,
    required this.themeSettings,
    required this.lastMessage,
    required this.lastMessageTimestamp,
    required this.lastMessageSender,
    required this.unreadCount,
    required this.participants,
    required this.admins,
    required this.typingUsers,
    required this.bots,
    required this.isMuted,
    required this.isArchived,
    required this.isBlocked,
    required this.pinnedMessageIDs,
    required this.moreData,
  });

  static ZeytinChatModel empty() {
    return ZeytinChatModel(
      chatID: '',
      type: ZeytinChatType.private,
      createdAt: DateTime.now(),
      chatName: '',
      chatPhotoURL: '',
      themeSettings: {},
      lastMessage: '',
      lastMessageTimestamp: DateTime.now(),
      lastMessageSender: ZeytinUserModel.empty(),
      unreadCount: 0,
      participants: [],
      admins: [],
      typingUsers: [],
      bots: [],
      isMuted: false,
      isArchived: false,
      isBlocked: false,
      pinnedMessageIDs: [],
      moreData: '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chatID': chatID,
      'type': type.value,
      'createdAt': createdAt.toIso8601String(),
      'chatName': chatName,
      'chatPhotoURL': chatPhotoURL,
      'themeSettings': themeSettings,
      'participants': participants.map((x) => x.toJson()).toList(),
      'admins': admins.map((x) => x.toJson()).toList(),
      'lastMessage': lastMessage,
      'lastMessageTimestamp': lastMessageTimestamp.toIso8601String(),
      'lastMessageSender': lastMessageSender.toJson(),
      'unreadCount': unreadCount,
      'typingUsers': typingUsers.map((x) => x.toJson()).toList(),
      'bots': bots.map((x) => x.toJson()).toList(),
      'isMuted': isMuted,
      'isArchived': isArchived,
      'isBlocked': isBlocked,
      'pinnedMessageIDs': pinnedMessageIDs,
      'moreData': moreData,
    };
  }

  factory ZeytinChatModel.fromJson(Map<String, dynamic> json) {
    return ZeytinChatModel(
      chatID: json['chatID'] ?? '',
      type: ZeytinChatType.values.firstWhere(
        (e) => e.value == json['type'],
        orElse: () => ZeytinChatType.private,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      chatName: json['chatName'] ?? '',
      chatPhotoURL: json['chatPhotoURL'] ?? '',
      themeSettings: Map<String, dynamic>.from(json['themeSettings'] ?? {}),
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
      bots:
          (json['bots'] as List?)
              ?.map((x) => ZeytinBotModel.fromJson(x))
              .toList() ??
          [],
      isMuted: json['isMuted'] ?? false,
      isArchived: json['isArchived'] ?? false,
      isBlocked: json['isBlocked'] ?? false,
      pinnedMessageIDs: List<String>.from(json['pinnedMessageIDs'] ?? []),
      moreData: json['moreData'] ?? '',
    );
  }

  ZeytinChatModel copyWith({
    String? chatID,
    ZeytinChatType? type,
    DateTime? createdAt,
    String? chatName,
    String? chatPhotoURL,
    Map<String, dynamic>? themeSettings,
    List<ZeytinUserModel>? participants,
    List<ZeytinUserModel>? admins,
    String? lastMessage,
    DateTime? lastMessageTimestamp,
    ZeytinUserModel? lastMessageSender,
    int? unreadCount,
    List<ZeytinUserModel>? typingUsers,
    List<ZeytinBotModel>? bots,
    bool? isMuted,
    bool? isArchived,
    bool? isBlocked,
    List<String>? pinnedMessageIDs,
    String? moreData,
  }) {
    return ZeytinChatModel(
      chatID: chatID ?? this.chatID,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      chatName: chatName ?? this.chatName,
      chatPhotoURL: chatPhotoURL ?? this.chatPhotoURL,
      themeSettings: themeSettings ?? this.themeSettings,
      participants: participants ?? this.participants,
      admins: admins ?? this.admins,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTimestamp: lastMessageTimestamp ?? this.lastMessageTimestamp,
      lastMessageSender: lastMessageSender ?? this.lastMessageSender,
      unreadCount: unreadCount ?? this.unreadCount,
      typingUsers: typingUsers ?? this.typingUsers,
      bots: bots ?? this.bots,
      isMuted: isMuted ?? this.isMuted,
      isArchived: isArchived ?? this.isArchived,
      isBlocked: isBlocked ?? this.isBlocked,
      pinnedMessageIDs: pinnedMessageIDs ?? this.pinnedMessageIDs,
      moreData: moreData ?? this.moreData,
    );
  }
}

class ZeytinMessage {
  final String messageId;
  final String chatId;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final ZeytinMessageType messageType;
  final ZeytinMessageStatus status;
  final bool isEdited;
  final DateTime? editedTimestamp;
  final bool isDeleted;
  final bool deletedForEveryone;
  final bool isForwarded;
  final String? forwardedFrom;
  final ZeytinMediaModel? media;
  final ZeytinLocationModel? location;
  final ZeytinContactModel? contact;
  final String? replyToMessageId;
  final List<String> mentions;
  final ZeytinMessageReactionsModel reactions;
  final ZeytinMessageStatusInfoModel statusInfo;
  final List<String> starredBy;
  final bool isPinned;
  final String? pinnedBy;
  final DateTime? pinnedTimestamp;
  final bool isSystemMessage;
  final ZeytinSystemMessageDataModel? systemMessageData;
  final bool encrypted;
  final String? encryptionKey;
  final Duration? selfDestructTimer;
  final DateTime? selfDestructTimestamp;
  final String? localId;
  final String? serverId;
  final int sequenceNumber;
  final String? botId;
  final List<ZeytinInteractiveButtonModel> interactiveButtons;
  final Map<String, dynamic> metadata;

  ZeytinMessage({
    required this.messageId,
    required this.chatId,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.messageType = ZeytinMessageType.text,
    this.status = ZeytinMessageStatus.sent,
    this.isEdited = false,
    this.editedTimestamp,
    this.isDeleted = false,
    this.deletedForEveryone = false,
    this.isForwarded = false,
    this.forwardedFrom,
    this.media,
    this.location,
    this.contact,
    this.replyToMessageId,
    List<String>? mentions,
    ZeytinMessageReactionsModel? reactions,
    ZeytinMessageStatusInfoModel? statusInfo,
    List<String>? starredBy,
    this.isPinned = false,
    this.pinnedBy,
    this.pinnedTimestamp,
    this.isSystemMessage = false,
    this.systemMessageData,
    this.encrypted = false,
    this.encryptionKey,
    this.selfDestructTimer,
    this.selfDestructTimestamp,
    this.localId,
    this.serverId,
    this.sequenceNumber = 0,
    this.botId,
    List<ZeytinInteractiveButtonModel>? interactiveButtons,
    Map<String, dynamic>? metadata,
  }) : mentions = mentions ?? [],
       reactions = reactions ?? ZeytinMessageReactionsModel(),
       statusInfo = statusInfo ?? ZeytinMessageStatusInfoModel(),
       starredBy = starredBy ?? [],
       interactiveButtons = interactiveButtons ?? [],
       metadata = metadata ?? {};

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'messageType': messageType.value,
      'status': status.value,
      'isEdited': isEdited,
      'editedTimestamp': editedTimestamp?.toIso8601String(),
      'isDeleted': isDeleted,
      'deletedForEveryone': deletedForEveryone,
      'isForwarded': isForwarded,
      'forwardedFrom': forwardedFrom,
      'media': media?.toJson(),
      'location': location?.toJson(),
      'contact': contact?.toJson(),
      'replyToMessageId': replyToMessageId,
      'mentions': mentions,
      'reactions': reactions.toJson(),
      'statusInfo': statusInfo.toJson(),
      'starredBy': starredBy,
      'isPinned': isPinned,
      'pinnedBy': pinnedBy,
      'pinnedTimestamp': pinnedTimestamp?.toIso8601String(),
      'isSystemMessage': isSystemMessage,
      'systemMessageData': systemMessageData?.toJson(),
      'encrypted': encrypted,
      'encryptionKey': encryptionKey,
      'selfDestructTimer': selfDestructTimer?.inSeconds,
      'selfDestructTimestamp': selfDestructTimestamp?.toIso8601String(),
      'localId': localId,
      'serverId': serverId,
      'sequenceNumber': sequenceNumber,
      'botId': botId,
      'interactiveButtons': interactiveButtons.map((b) => b.toJson()).toList(),
      'metadata': metadata,
    };
  }

  factory ZeytinMessage.fromJson(Map<String, dynamic> json) {
    return ZeytinMessage(
      messageId: json['messageId'] ?? '',
      chatId: json['chatId'] ?? '',
      senderId: json['senderId'] ?? '',
      text: json['text'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      messageType: ZeytinMessageType.values.firstWhere(
        (e) => e.value == json['messageType'],
        orElse: () => ZeytinMessageType.text,
      ),
      status: ZeytinMessageStatus.values.firstWhere(
        (e) => e.value == json['status'],
        orElse: () => ZeytinMessageStatus.sent,
      ),
      isEdited: json['isEdited'] ?? false,
      editedTimestamp: json['editedTimestamp'] != null
          ? DateTime.tryParse(json['editedTimestamp'])
          : null,
      isDeleted: json['isDeleted'] ?? false,
      deletedForEveryone: json['deletedForEveryone'] ?? false,
      isForwarded: json['isForwarded'] ?? false,
      forwardedFrom: json['forwardedFrom'],
      media: json['media'] != null
          ? ZeytinMediaModel.fromJson(json['media'])
          : null,
      location: json['location'] != null
          ? ZeytinLocationModel.fromJson(json['location'])
          : null,
      contact: json['contact'] != null
          ? ZeytinContactModel.fromJson(json['contact'])
          : null,
      replyToMessageId: json['replyToMessageId'],
      mentions: json['mentions'] != null
          ? List<String>.from(json['mentions'])
          : [],
      reactions: json['reactions'] != null
          ? ZeytinMessageReactionsModel.fromJson(json['reactions'])
          : ZeytinMessageReactionsModel(),
      statusInfo: json['statusInfo'] != null
          ? ZeytinMessageStatusInfoModel.fromJson(json['statusInfo'])
          : ZeytinMessageStatusInfoModel(),
      starredBy: json['starredBy'] != null
          ? List<String>.from(json['starredBy'])
          : [],
      isPinned: json['isPinned'] ?? false,
      pinnedBy: json['pinnedBy'],
      pinnedTimestamp: json['pinnedTimestamp'] != null
          ? DateTime.tryParse(json['pinnedTimestamp'])
          : null,
      isSystemMessage: json['isSystemMessage'] ?? false,
      systemMessageData: json['systemMessageData'] != null
          ? ZeytinSystemMessageDataModel.fromJson(json['systemMessageData'])
          : null,
      encrypted: json['encrypted'] ?? false,
      encryptionKey: json['encryptionKey'],
      selfDestructTimer: json['selfDestructTimer'] != null
          ? Duration(seconds: json['selfDestructTimer'])
          : null,
      selfDestructTimestamp: json['selfDestructTimestamp'] != null
          ? DateTime.tryParse(json['selfDestructTimestamp'])
          : null,
      localId: json['localId'],
      serverId: json['serverId'],
      sequenceNumber: json['sequenceNumber'] ?? 0,
      botId: json['botId'],
      interactiveButtons: json['interactiveButtons'] != null
          ? (json['interactiveButtons'] as List)
                .map((item) => ZeytinInteractiveButtonModel.fromJson(item))
                .toList()
          : [],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : {},
    );
  }

  ZeytinMessage copyWith({
    String? messageId,
    String? chatId,
    String? senderId,
    String? text,
    DateTime? timestamp,
    ZeytinMessageType? messageType,
    ZeytinMessageStatus? status,
    bool? isEdited,
    DateTime? editedTimestamp,
    bool? isDeleted,
    bool? deletedForEveryone,
    bool? isForwarded,
    String? forwardedFrom,
    ZeytinMediaModel? media,
    ZeytinLocationModel? location,
    ZeytinContactModel? contact,
    String? replyToMessageId,
    List<String>? mentions,
    ZeytinMessageReactionsModel? reactions,
    ZeytinMessageStatusInfoModel? statusInfo,
    List<String>? starredBy,
    bool? isPinned,
    String? pinnedBy,
    DateTime? pinnedTimestamp,
    bool? isSystemMessage,
    ZeytinSystemMessageDataModel? systemMessageData,
    bool? encrypted,
    String? encryptionKey,
    Duration? selfDestructTimer,
    DateTime? selfDestructTimestamp,
    String? localId,
    String? serverId,
    int? sequenceNumber,
    String? botId,
    List<ZeytinInteractiveButtonModel>? interactiveButtons,
    Map<String, dynamic>? metadata,
  }) {
    return ZeytinMessage(
      messageId: messageId ?? this.messageId,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      messageType: messageType ?? this.messageType,
      status: status ?? this.status,
      isEdited: isEdited ?? this.isEdited,
      editedTimestamp: editedTimestamp ?? this.editedTimestamp,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedForEveryone: deletedForEveryone ?? this.deletedForEveryone,
      isForwarded: isForwarded ?? this.isForwarded,
      forwardedFrom: forwardedFrom ?? this.forwardedFrom,
      media: media ?? this.media,
      location: location ?? this.location,
      contact: contact ?? this.contact,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      mentions: mentions ?? this.mentions,
      reactions: reactions ?? this.reactions,
      statusInfo: statusInfo ?? this.statusInfo,
      starredBy: starredBy ?? this.starredBy,
      isPinned: isPinned ?? this.isPinned,
      pinnedBy: pinnedBy ?? this.pinnedBy,
      pinnedTimestamp: pinnedTimestamp ?? this.pinnedTimestamp,
      isSystemMessage: isSystemMessage ?? this.isSystemMessage,
      systemMessageData: systemMessageData ?? this.systemMessageData,
      encrypted: encrypted ?? this.encrypted,
      encryptionKey: encryptionKey ?? this.encryptionKey,
      selfDestructTimer: selfDestructTimer ?? this.selfDestructTimer,
      selfDestructTimestamp:
          selfDestructTimestamp ?? this.selfDestructTimestamp,
      localId: localId ?? this.localId,
      serverId: serverId ?? this.serverId,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      botId: botId ?? this.botId,
      interactiveButtons: interactiveButtons ?? this.interactiveButtons,
      metadata: metadata ?? this.metadata,
    );
  }
}
