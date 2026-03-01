import 'dart:async';

import 'package:uuid/uuid.dart';
import 'package:zeytin/zeytin.dart';

class ZeytinChat {
  final ZeytinClient zeytin;

  ZeytinChat(this.zeytin);
  Future<ZeytinResponse> createChat({
    required String chatName,
    required List<ZeytinUserModel> participants,
    required ZeytinChatType type,
    String? chatPhotoURL,
    List<ZeytinUserModel>? admins,
    Map<String, dynamic>? themeSettings,
    String? moreData,
  }) async {
    try {
      String chatId;
      if (type == ZeytinChatType.private && participants.length == 2) {
        List<String> uids = participants.map((u) => u.uid).toList();
        chatId = "private_${uids[0]}_${uids[1]}";
        final existing = await getChat(chatId: chatId);
        if (existing != null) {
          return ZeytinResponse(
            isSuccess: true,
            message: "Chat already exists",
            data: existing.toJson(),
          );
        }
      } else {
        chatId = const Uuid().v4();
      }

      final now = DateTime.now();
      final newChat = ZeytinChatModel.empty().copyWith(
        chatID: chatId,
        type: type,
        createdAt: now,
        chatName: chatName,
        chatPhotoURL: chatPhotoURL,
        themeSettings: themeSettings,
        participants: participants,
        admins: admins ?? (type == ZeytinChatType.private ? [] : participants),
        moreData: moreData,
      );
      final response = await zeytin.addData(
        box: "chats",
        tag: chatId,
        value: newChat.toJson(),
      );

      if (response.isSuccess) {
        await _indexChatForParticipants(chatId, participants);
        return ZeytinResponse(
          isSuccess: true,
          message: "Chat created successfully",
          data: newChat.toJson(),
        );
      }
      return response;
    } catch (e) {
      return ZeytinResponse(
        isSuccess: false,
        message: "Error in createChat",
        error: e.toString(),
      );
    }
  }

  String getChatId({
    required List<ZeytinUserModel> participants,
    required ZeytinChatType type,
  }) {
    if (type == ZeytinChatType.private && participants.length == 2) {
      List<String> uids = participants.map((u) => u.uid).toList()..sort();
      return "private_${uids[0]}_${uids[1]}";
    } else {
      return const Uuid().v4();
    }
  }

  Future<void> _indexChatForParticipants(
    String chatId,
    List<ZeytinUserModel> participants,
  ) async {
    for (var user in participants) {
      var userChatsRes = await zeytin.getData(box: "my_chats", tag: user.uid);
      List<String> currentChatIds = [];

      if (userChatsRes.isSuccess && userChatsRes.data != null) {
        currentChatIds = List<String>.from(userChatsRes.data!["chatIds"] ?? []);
      }

      if (!currentChatIds.contains(chatId)) {
        currentChatIds.add(chatId);
        await zeytin.addData(
          box: "my_chats",
          tag: user.uid,
          value: {"chatIds": currentChatIds},
        );
      }
    }
  }

  Future<ZeytinResponse> deleteChatAndAllMessage({
    required String chatId,
  }) async {
    try {
      final chatData = await zeytin.getData(box: "chats", tag: chatId);
      if (chatData.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Chat not found");
      }
      final chat = ZeytinChatModel.fromJson(chatData.data!);
      final messages = await getMessages(chatId: chatId, limit: 5000);
      for (var m in messages) {
        await zeytin.deleteData(box: "messages", tag: m.messageId);
      }
      for (var user in chat.participants) {
        var userChatsRes = await zeytin.getData(box: "my_chats", tag: user.uid);
        if (userChatsRes.isSuccess && userChatsRes.data != null) {
          List<String> currentChatIds = List<String>.from(
            userChatsRes.data!["chatIds"] ?? [],
          );
          currentChatIds.remove(chatId);
          await zeytin.addData(
            box: "my_chats",
            tag: user.uid,
            value: {"chatIds": currentChatIds},
          );
        }
      }
      final response = await zeytin.deleteData(box: "chats", tag: chatId);

      return response;
    } catch (e) {
      return ZeytinResponse(
        isSuccess: false,
        message: "Error terminating chat: $e",
      );
    }
  }

  Future<List<ZeytinChatModel>> getChatsForUser({
    required ZeytinUserModel user,
  }) async {
    try {
      final indexRes = await zeytin.getData(box: "my_chats", tag: user.uid);
      if (!indexRes.isSuccess || indexRes.data == null) return [];

      List<String> chatIds = List<String>.from(indexRes.data!["chatIds"] ?? []);
      if (chatIds.isEmpty) return [];

      List<ZeytinChatModel> userChats = [];
      for (var id in chatIds) {
        final chatData = await zeytin.getData(box: "chats", tag: id);
        if (chatData.isSuccess && chatData.data != null) {
          userChats.add(ZeytinChatModel.fromJson(chatData.data!));
        }
      }

      userChats.sort(
        (a, b) => b.lastMessageTimestamp.compareTo(a.lastMessageTimestamp),
      );
      return userChats;
    } catch (e) {
      return [];
    }
  }

  Future<ZeytinChatModel?> getChat({required String chatId}) async {
    try {
      final chatData = await zeytin.getData(box: "chats", tag: chatId);
      if (chatData.data == null) return null;
      return ZeytinChatModel.fromJson(chatData.data!);
    } catch (e) {
      return null;
    }
  }

  Future<ZeytinResponse> updateChat({
    required String chatId,
    String? chatName,
    String? chatPhotoURL,
    Map<String, dynamic>? themeSettings,
    bool? isMuted,
    bool? isArchived,
    bool? isBlocked,
    String? moreData,
  }) async {
    try {
      final chatData = await zeytin.getData(box: "chats", tag: chatId);
      if (chatData.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Chat not found");
      }

      var chat = ZeytinChatModel.fromJson(chatData.data!);

      chat = chat.copyWith(
        chatName: chatName,
        chatPhotoURL: chatPhotoURL,
        themeSettings: themeSettings,
        isMuted: isMuted,
        isArchived: isArchived,
        isBlocked: isBlocked,
        moreData: moreData,
      );

      return await zeytin.addData(
        box: "chats",
        tag: chatId,
        value: chat.toJson(),
      );
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<ZeytinResponse> archiveChat({
    required String chatId,
    required bool archive,
  }) async {
    return await updateChat(chatId: chatId, isArchived: archive);
  }

  Future<ZeytinResponse> muteChat({
    required String chatId,
    required bool mute,
  }) async {
    return await updateChat(chatId: chatId, isMuted: mute);
  }

  Future<ZeytinResponse> blockChat({
    required String chatId,
    required bool block,
  }) async {
    return await updateChat(chatId: chatId, isBlocked: block);
  }

  Future<ZeytinResponse> addParticipant({
    required String chatId,
    required ZeytinUserModel user,
  }) async {
    try {
      final chatData = await zeytin.getData(box: "chats", tag: chatId);
      if (chatData.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Chat not found");
      }

      final chat = ZeytinChatModel.fromJson(chatData.data!);
      final participants = chat.participants;

      if (participants.any((p) => p.uid == user.uid)) {
        return ZeytinResponse(
          isSuccess: true,
          message: "Already a participant",
        );
      }

      participants.add(user);
      final updatedChat = chat.copyWith(participants: participants);

      final res = await zeytin.addData(
        box: "chats",
        tag: chatId,
        value: updatedChat.toJson(),
      );

      if (res.isSuccess) {
        await _indexChatForParticipants(chatId, [user]);
      }
      return res;
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<ZeytinResponse> removeParticipant({
    required String chatId,
    required ZeytinUserModel user,
  }) async {
    try {
      final chatData = await zeytin.getData(box: "chats", tag: chatId);
      if (chatData.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Chat not found");
      }

      final chat = ZeytinChatModel.fromJson(chatData.data!);
      final participants = chat.participants
          .where((p) => p.uid != user.uid)
          .toList();
      final updatedChat = chat.copyWith(participants: participants);

      final res = await zeytin.addData(
        box: "chats",
        tag: chatId,
        value: updatedChat.toJson(),
      );

      if (res.isSuccess) {
        var userChatsRes = await zeytin.getData(box: "my_chats", tag: user.uid);
        if (userChatsRes.isSuccess && userChatsRes.data != null) {
          List<String> currentChatIds = List<String>.from(
            userChatsRes.data!["chatIds"] ?? [],
          );
          currentChatIds.remove(chatId);
          await zeytin.addData(
            box: "my_chats",
            tag: user.uid,
            value: {"chatIds": currentChatIds},
          );
        }
      }
      return res;
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<ZeytinResponse> setTyping({
    required String chatId,
    required ZeytinUserModel user,
    required bool isTyping,
  }) async {
    try {
      final chatData = await zeytin.getData(box: "chats", tag: chatId);
      if (chatData.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Chat not found");
      }

      var chat = ZeytinChatModel.fromJson(chatData.data!);
      var typingUsers = chat.typingUsers;

      if (isTyping) {
        if (!typingUsers.any((u) => u.uid == user.uid)) {
          typingUsers.add(user);
        }
      } else {
        typingUsers.removeWhere((u) => u.uid == user.uid);
      }

      chat = chat.copyWith(typingUsers: typingUsers);

      return await zeytin.addData(
        box: "chats",
        tag: chatId,
        value: chat.toJson(),
      );
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<ZeytinResponse> updateUnreadCount({
    required String chatId,
    required int count,
  }) async {
    try {
      final chatData = await zeytin.getData(box: "chats", tag: chatId);
      if (chatData.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Chat not found");
      }

      var chat = ZeytinChatModel.fromJson(chatData.data!);
      chat = chat.copyWith(unreadCount: count);

      return await zeytin.addData(
        box: "chats",
        tag: chatId,
        value: chat.toJson(),
      );
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<ZeytinResponse> sendMessage({
    required String chatId,
    required ZeytinUserModel sender,
    required String text,
    ZeytinMessageType messageType = ZeytinMessageType.text,
    ZeytinMediaModel? media,
    ZeytinLocationModel? location,
    ZeytinContactModel? contact,
    String? replyToMessageId,
    List<String>? mentions,
    Duration? selfDestructTimer,
    String? botId,
    List<ZeytinInteractiveButtonModel>? interactiveButtons,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final messageId = const Uuid().v4();
      final now = DateTime.now();
      final selfDestructTimestamp = selfDestructTimer != null
          ? now.add(selfDestructTimer)
          : null;

      final message = ZeytinMessage(
        messageId: messageId,
        chatId: chatId,
        senderId: sender.uid,
        text: text,
        timestamp: now,
        messageType: messageType,
        status: ZeytinMessageStatus.sent,
        media: media,
        location: location,
        contact: contact,
        replyToMessageId: replyToMessageId,
        mentions: mentions,
        selfDestructTimer: selfDestructTimer,
        selfDestructTimestamp: selfDestructTimestamp,
        botId: botId,
        interactiveButtons: interactiveButtons,
        metadata: metadata,
      );

      final response = await zeytin.addData(
        box: "messages",
        tag: messageId,
        value: message.toJson(),
      );

      if (response.isSuccess) {
        await _updateChatLastMessage(chatId, message, sender);
        final chatData = await zeytin.getData(box: "chats", tag: chatId);
        if (chatData.isSuccess && chatData.data != null) {
          final chat = ZeytinChatModel.fromJson(chatData.data!);
          await _indexChatForParticipants(chatId, chat.participants);
        }
      }

      return response;
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  StreamSubscription listenChats({
    required ZeytinUserModel user,
    required Function(ZeytinChatModel chat) onChatCreated,
    required Function(ZeytinChatModel chat) onChatUpdated,
    required Function(String chatId) onChatDeleted,
  }) {
    return zeytin.watchBox(box: "chats").listen((event) {
      final op = event["op"];
      final tag = event["tag"];
      final rawData = event["data"];

      if (op == "DELETE") {
        onChatDeleted(tag.toString());
        return;
      }

      if (rawData != null) {
        final chat = ZeytinChatModel.fromJson(rawData);
        if (chat.participants.any((p) => p.uid == user.uid)) {
          if (op == "PUT") {
            onChatCreated(chat);
          } else if (op == "UPDATE") {
            onChatUpdated(chat);
          }
        }
      }
    });
  }

  StreamSubscription<Map<String, dynamic>> listen({
    required String chatId,
    required Function(ZeytinMessage message) onMessageReceived,
    required Function(ZeytinMessage message) onMessageUpdated,
    required Function(String messageId) onMessageDeleted,
  }) {
    return zeytin.watchBox(box: "messages").listen((event) {
      final op = event["op"];
      final tag = event["tag"];

      if (op == "DELETE") {
        onMessageDeleted(tag.toString());
        return;
      }

      final rawData = event["data"];
      if (rawData == null) return;

      try {
        final message = ZeytinMessage.fromJson(rawData);
        if (message.chatId.trim() == chatId.trim()) {
          if (message.isDeleted) {
            onMessageDeleted(message.messageId);
          } else if (op == "PUT") {
            onMessageReceived(message);
          } else if (op == "UPDATE") {
            onMessageUpdated(message);
          }
        }
      } catch (e) {
        ZeytinPrint.errorPrint("WS ERROR: $e");
      }
    });
  }

  Future<List<ZeytinMessage>> getMessages({
    required String chatId,
    int? limit,
    int? offset,
  }) async {
    try {
      final res = await zeytin.getBox(box: "messages");
      if (!res.isSuccess || res.data == null) return [];

      List<ZeytinMessage> messages = [];
      for (var item in res.data!.values) {
        final message = ZeytinMessage.fromJson(item);
        if (message.chatId == chatId) {
          messages.add(message);
        }
      }
      messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      final startIndex = offset ?? 0;
      final endIndex = limit != null
          ? (startIndex + limit).clamp(0, messages.length)
          : messages.length;

      if (startIndex >= messages.length) return [];
      return messages.sublist(startIndex, endIndex).reversed.toList();
    } catch (e) {
      ZeytinPrint.errorPrint("getMessages logic error: $e");
      return [];
    }
  }

  Future<ZeytinMessage?> getMessage({required String messageId}) async {
    try {
      final messageData = await zeytin.getData(box: "messages", tag: messageId);
      if (messageData.data == null) return null;
      return ZeytinMessage.fromJson(messageData.data!);
    } catch (e) {
      return null;
    }
  }

  Future<ZeytinResponse> editMessage({
    required String messageId,
    required String newText,
  }) async {
    try {
      final messageData = await zeytin.getData(box: "messages", tag: messageId);
      if (messageData.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Message not found");
      }

      var message = ZeytinMessage.fromJson(messageData.data!);
      if (message.isDeleted) {
        return ZeytinResponse(
          isSuccess: false,
          message: "Cannot edit deleted message",
        );
      }

      message = message.copyWith(
        text: newText,
        isEdited: true,
        editedTimestamp: DateTime.now(),
      );

      return await zeytin.addData(
        box: "messages",
        tag: messageId,
        value: message.toJson(),
      );
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<ZeytinResponse> deleteMessage({
    required String messageId,
    required String userId,
    bool deleteForEveryone = false,
  }) async {
    try {
      final messageData = await zeytin.getData(box: "messages", tag: messageId);
      if (messageData.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Message not found");
      }

      var message = ZeytinMessage.fromJson(messageData.data!);

      if (message.senderId != userId && !deleteForEveryone) {
        return ZeytinResponse(isSuccess: false, message: "Not authorized");
      }

      message = message.copyWith(
        isDeleted: true,
        deletedForEveryone: deleteForEveryone,
      );

      return await zeytin.addData(
        box: "messages",
        tag: messageId,
        value: message.toJson(),
      );
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<ZeytinResponse> forwardMessage({
    required String originalMessageId,
    required String targetChatId,
    required ZeytinUserModel sender,
  }) async {
    try {
      final messageData = await zeytin.getData(
        box: "messages",
        tag: originalMessageId,
      );
      if (messageData.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Message not found");
      }

      final originalMessage = ZeytinMessage.fromJson(messageData.data!);
      final newMessageId = const Uuid().v4();
      final now = DateTime.now();

      final forwardedMessage = ZeytinMessage(
        messageId: newMessageId,
        chatId: targetChatId,
        senderId: sender.uid,
        text: originalMessage.text,
        timestamp: now,
        messageType: originalMessage.messageType,
        status: ZeytinMessageStatus.sent,
        isForwarded: true,
        forwardedFrom: originalMessage.senderId,
        media: originalMessage.media,
        location: originalMessage.location,
        contact: originalMessage.contact,
        mentions: originalMessage.mentions,
      );

      final response = await zeytin.addData(
        box: "messages",
        tag: newMessageId,
        value: forwardedMessage.toJson(),
      );

      if (response.isSuccess) {
        await _updateChatLastMessage(targetChatId, forwardedMessage, sender);
      }
      return response;
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<List<ZeytinMessage>> searchMessages({
    required String chatId,
    required String query,
  }) async {
    try {
      final allMessages = await getMessages(chatId: chatId, limit: 1000);
      return allMessages
          .where(
            (m) =>
                !m.isDeleted &&
                m.text.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<ZeytinResponse> starMessage({
    required String messageId,
    required String userId,
  }) async {
    try {
      final messageData = await zeytin.getData(box: "messages", tag: messageId);
      if (messageData.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Message not found");
      }

      var message = ZeytinMessage.fromJson(messageData.data!);
      final starredBy = message.starredBy;

      if (!starredBy.contains(userId)) {
        starredBy.add(userId);
        message = message.copyWith(starredBy: starredBy);
        return await zeytin.addData(
          box: "messages",
          tag: messageId,
          value: message.toJson(),
        );
      }
      return ZeytinResponse(isSuccess: true, message: "Already starred");
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<ZeytinResponse> unstarMessage({
    required String messageId,
    required String userId,
  }) async {
    try {
      final messageData = await zeytin.getData(box: "messages", tag: messageId);
      if (messageData.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Message not found");
      }

      var message = ZeytinMessage.fromJson(messageData.data!);
      final starredBy = message.starredBy;

      if (starredBy.contains(userId)) {
        starredBy.remove(userId);
        message = message.copyWith(starredBy: starredBy);
        return await zeytin.addData(
          box: "messages",
          tag: messageId,
          value: message.toJson(),
        );
      }
      return ZeytinResponse(isSuccess: true, message: "Not starred");
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<List<ZeytinMessage>> getStarredMessages({
    required String userId,
  }) async {
    try {
      final res = await zeytin.getBox(box: "messages");
      if (!res.isSuccess || res.data == null) return [];

      List<ZeytinMessage> starred = [];
      for (var item in res.data!.values) {
        final message = ZeytinMessage.fromJson(item.value);
        if (message.starredBy.contains(userId) && !message.isDeleted) {
          starred.add(message);
        }
      }
      starred.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return starred;
    } catch (e) {
      return [];
    }
  }

  Future<ZeytinResponse> pinMessage({
    required String messageId,
    required String pinnedBy,
    required String chatId,
  }) async {
    try {
      final messageData = await zeytin.getData(box: "messages", tag: messageId);
      if (messageData.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Message not found");
      }

      var message = ZeytinMessage.fromJson(messageData.data!);
      if (message.chatId != chatId) {
        return ZeytinResponse(
          isSuccess: false,
          message: "Message not in this chat",
        );
      }

      message = message.copyWith(
        isPinned: true,
        pinnedBy: pinnedBy,
        pinnedTimestamp: DateTime.now(),
      );

      final chatData = await zeytin.getData(box: "chats", tag: chatId);
      if (chatData.data != null) {
        var chat = ZeytinChatModel.fromJson(chatData.data!);
        final pinnedIDs = chat.pinnedMessageIDs;
        if (!pinnedIDs.contains(messageId)) {
          pinnedIDs.add(messageId);
          chat = chat.copyWith(pinnedMessageIDs: pinnedIDs);
          await zeytin.addData(box: "chats", tag: chatId, value: chat.toJson());
        }
      }

      return await zeytin.addData(
        box: "messages",
        tag: messageId,
        value: message.toJson(),
      );
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<ZeytinResponse> unpinMessage({
    required String messageId,
    required String chatId,
  }) async {
    try {
      final messageData = await zeytin.getData(box: "messages", tag: messageId);
      if (messageData.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Message not found");
      }

      var message = ZeytinMessage.fromJson(messageData.data!);
      message = message.copyWith(
        isPinned: false,
        pinnedBy: null,
        pinnedTimestamp: null,
      );

      final chatData = await zeytin.getData(box: "chats", tag: chatId);
      if (chatData.data != null) {
        var chat = ZeytinChatModel.fromJson(chatData.data!);
        final pinnedIDs = chat.pinnedMessageIDs;
        pinnedIDs.remove(messageId);
        chat = chat.copyWith(pinnedMessageIDs: pinnedIDs);
        await zeytin.addData(box: "chats", tag: chatId, value: chat.toJson());
      }

      return await zeytin.addData(
        box: "messages",
        tag: messageId,
        value: message.toJson(),
      );
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<List<ZeytinMessage>> getPinnedMessages({
    required String chatId,
  }) async {
    try {
      final chatData = await zeytin.getData(box: "chats", tag: chatId);
      if (chatData.data == null) return [];

      final chat = ZeytinChatModel.fromJson(chatData.data!);
      List<ZeytinMessage> pinnedMessages = [];

      for (var id in chat.pinnedMessageIDs) {
        final mData = await zeytin.getData(box: "messages", tag: id);
        if (mData.data != null) {
          final m = ZeytinMessage.fromJson(mData.data!);
          if (!m.isDeleted) pinnedMessages.add(m);
        }
      }
      return pinnedMessages;
    } catch (e) {
      return [];
    }
  }

  Future<ZeytinResponse> clearChatHistory({
    required String chatId,
    required String userId,
  }) async {
    try {
      final messages = await getMessages(chatId: chatId, limit: 1000);
      for (var message in messages) {
        if (message.senderId == userId) {
          await deleteMessage(messageId: message.messageId, userId: userId);
        }
      }
      return ZeytinResponse(isSuccess: true, message: "Chat history cleared");
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<ZeytinResponse> markAsRead({
    required String messageId,
    required String userId,
  }) async {
    try {
      final messageData = await zeytin.getData(box: "messages", tag: messageId);
      if (messageData.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Message not found");
      }

      var message = ZeytinMessage.fromJson(messageData.data!);
      final readBy = message.statusInfo.readBy;

      if (!readBy.contains(userId)) {
        readBy.add(userId);
        final info = message.statusInfo.copyWith(
          readBy: readBy,
          readAt: DateTime.now(),
        );
        message = message.copyWith(
          statusInfo: info,
          status: ZeytinMessageStatus.read,
        );
        return await zeytin.addData(
          box: "messages",
          tag: messageId,
          value: message.toJson(),
        );
      }
      return ZeytinResponse(isSuccess: true, message: "Already read");
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<ZeytinResponse> markAsDelivered({
    required String messageId,
    required String userId,
  }) async {
    try {
      final messageData = await zeytin.getData(box: "messages", tag: messageId);
      if (messageData.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Message not found");
      }

      var message = ZeytinMessage.fromJson(messageData.data!);
      final deliveredTo = message.statusInfo.deliveredTo;

      if (!deliveredTo.contains(userId)) {
        deliveredTo.add(userId);
        final info = message.statusInfo.copyWith(
          deliveredTo: deliveredTo,
          deliveredAt: DateTime.now(),
        );
        message = message.copyWith(
          statusInfo: info,
          status: ZeytinMessageStatus.delivered,
        );
        return await zeytin.addData(
          box: "messages",
          tag: messageId,
          value: message.toJson(),
        );
      }
      return ZeytinResponse(isSuccess: true, message: "Already delivered");
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<ZeytinResponse> addReaction({
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    try {
      final messageData = await zeytin.getData(box: "messages", tag: messageId);
      if (messageData.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Message not found");
      }

      var message = ZeytinMessage.fromJson(messageData.data!);
      final reactions = message.reactions.reactions;
      final list = reactions[emoji] ?? [];

      if (!list.any((r) => r.userId == userId)) {
        list.add(
          ZeytinReactionModel(
            emoji: emoji,
            userId: userId,
            timestamp: DateTime.now(),
          ),
        );
        reactions[emoji] = list;
        message = message.copyWith(
          reactions: ZeytinMessageReactionsModel(reactions: reactions),
        );
        return await zeytin.addData(
          box: "messages",
          tag: messageId,
          value: message.toJson(),
        );
      }
      return ZeytinResponse(isSuccess: true, message: "Already reacted");
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<ZeytinResponse> removeReaction({
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    try {
      final messageData = await zeytin.getData(box: "messages", tag: messageId);
      if (messageData.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Message not found");
      }

      var message = ZeytinMessage.fromJson(messageData.data!);
      final reactions = message.reactions.reactions;
      final list = reactions[emoji] ?? [];

      list.removeWhere((r) => r.userId == userId);
      if (list.isEmpty) {
        reactions.remove(emoji);
      } else {
        reactions[emoji] = list;
      }

      message = message.copyWith(
        reactions: ZeytinMessageReactionsModel(reactions: reactions),
      );
      return await zeytin.addData(
        box: "messages",
        tag: messageId,
        value: message.toJson(),
      );
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<ZeytinResponse> processSelfDestructMessages() async {
    try {
      final res = await zeytin.getBox(box: "messages");
      if (!res.isSuccess || res.data == null) return res;

      final now = DateTime.now();
      for (var item in res.data!.values) {
        final message = ZeytinMessage.fromJson(item.value);
        if (message.selfDestructTimestamp != null &&
            message.selfDestructTimestamp!.isBefore(now) &&
            !message.isDeleted) {
          await deleteMessage(
            messageId: message.messageId,
            userId: message.senderId,
            deleteForEveryone: true,
          );
        }
      }
      return ZeytinResponse(isSuccess: true, message: "Processed");
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<ZeytinResponse> createSystemMessage({
    required String chatId,
    required ZeytinSystemMessageType type,
    String? userId,
    String? userName,
    String? oldValue,
    String? value,
  }) async {
    try {
      final messageId = const Uuid().v4();
      final now = DateTime.now();

      final systemData = ZeytinSystemMessageDataModel(
        type: type,
        userId: userId,
        userName: userName,
        oldValue: oldValue,
        value: value,
      );

      final message = ZeytinMessage(
        messageId: messageId,
        chatId: chatId,
        senderId: "system",
        text: "System Message",
        timestamp: now,
        messageType: ZeytinMessageType.system,
        status: ZeytinMessageStatus.sent,
        isSystemMessage: true,
        systemMessageData: systemData,
      );

      final response = await zeytin.addData(
        box: "messages",
        tag: messageId,
        value: message.toJson(),
      );

      if (response.isSuccess) {
        final chatData = await zeytin.getData(box: "chats", tag: chatId);
        if (chatData.data != null) {
          var chat = ZeytinChatModel.fromJson(chatData.data!);
          chat = chat.copyWith(
            lastMessage: _getSystemMessageText(type, userName, oldValue, value),
            lastMessageTimestamp: now,
          );
          await zeytin.addData(box: "chats", tag: chatId, value: chat.toJson());
        }
      }
      return response;
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<void> _updateChatLastMessage(
    String chatId,
    ZeytinMessage message,
    ZeytinUserModel sender,
  ) async {
    try {
      final chatData = await zeytin.getData(box: "chats", tag: chatId);
      if (chatData.data == null) return;

      var chat = ZeytinChatModel.fromJson(chatData.data!);
      chat = chat.copyWith(
        lastMessage: message.messageType == ZeytinMessageType.text
            ? message.text
            : message.messageType.value,
        lastMessageTimestamp: message.timestamp,
        lastMessageSender: sender,
      );

      await zeytin.addData(box: "chats", tag: chatId, value: chat.toJson());
    } catch (e) {}
  }

  String _getSystemMessageText(
    ZeytinSystemMessageType type,
    String? userName,
    String? oldValue,
    String? value,
  ) {
    switch (type) {
      case ZeytinSystemMessageType.userJoined:
        return '$userName joined';
      case ZeytinSystemMessageType.userLeft:
        return '$userName left';
      case ZeytinSystemMessageType.groupCreated:
        return 'Group created by $userName';
      case ZeytinSystemMessageType.nameChanged:
        return 'Name changed to $value';
      default:
        return 'System message';
    }
  }
}
