import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:zeytin/src/models/board_post.dart';
import 'package:zeytin/src/models/response.dart';
import 'package:zeytin/src/models/user.dart';
import 'package:zeytin/src/models/message.dart';
import 'package:zeytin/src/models/community.dart';
import 'package:zeytin/src/services/client.dart';

class ZeytinCommunity {
  final ZeytinClient zeytin;

  ZeytinCommunity(this.zeytin);

  Future<ZeytinResponse> createCommunity({
    required String name,
    required List<ZeytinUserModel> participants,
    required ZeytinUserModel creator,
    String? description,
    String? photoURL,
    Map<String, dynamic>? moreDataMap,
  }) async {
    try {
      final communityId = const Uuid().v4();
      final now = DateTime.now();
      if (!participants.any((p) => p.uid == creator.uid)) {
        participants.add(creator);
      }

      final newCommunity = ZeytinCommunityModel.empty().copyWith(
        id: communityId,
        name: name,
        description: description,
        photoURL: photoURL,
        createdAt: now,
        participants: participants,
        admins: [creator],
        moreData: moreDataMap?.toString(),
      );

      final response = await zeytin.addData(
        box: "communities",
        tag: communityId,
        value: newCommunity.toJson(),
      );

      if (response.isSuccess) {
        await _indexCommunityForParticipants(communityId, participants);
        return ZeytinResponse(
          isSuccess: true,
          message: "Community created successfully",
          data: newCommunity.toJson(),
        );
      }
      return response;
    } catch (e) {
      return ZeytinResponse(
        isSuccess: false,
        message: "Error creating community: $e",
      );
    }
  }

  Future<ZeytinResponse> deleteCommunityAndContents({
    required String communityId,
    required ZeytinUserModel admin,
  }) async {
    try {
      final comData = await zeytin.getData(
        box: "communities",
        tag: communityId,
      );

      if (comData.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Community not found");
      }

      final community = ZeytinCommunityModel.fromJson(comData.data!);

      if (!community.admins.any((a) => a.uid == admin.uid)) {
        return ZeytinResponse(isSuccess: false, message: "Not authorized");
      }

      final msgFilter = await zeytin.filter(
        box: "messages",
        field: "chatId",
        value: communityId,
      );

      if (msgFilter.isSuccess && msgFilter.data is Map) {
        var rawList = msgFilter.data!["results"];
        if (rawList is List) {
          for (var item in rawList) {
            final msg = ZeytinMessage.fromJson(item);
            await zeytin.deleteData(box: "messages", tag: msg.messageId);
          }
        }
      }

      final rooms = await getCommunityRooms(communityId: communityId);
      for (var room in rooms) {
        await zeytin.deleteData(box: "community_rooms", tag: room.id);
      }

      final posts = await getBoardPosts(communityId: communityId);
      for (var post in posts) {
        await zeytin.deleteData(box: "community_boards", tag: post.id);
      }

      for (var user in community.participants) {
        var userComsRes = await zeytin.getData(
          box: "my_communities",
          tag: user.uid,
        );
        if (userComsRes.isSuccess && userComsRes.data != null) {
          List<String> currentIds = List<String>.from(
            userComsRes.data!["communityIds"] ?? [],
          );
          if (currentIds.contains(communityId)) {
            currentIds.remove(communityId);
            await zeytin.addData(
              box: "my_communities",
              tag: user.uid,
              value: {"communityIds": currentIds},
            );
          }
        }
      }

      return await zeytin.deleteData(box: "communities", tag: communityId);
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<ZeytinResponse> createInviteCode({
    required String communityId,
    required ZeytinUserModel admin,
    String? customCode,
    Duration? duration,
    int? maxUses,
    Map<String, dynamic>? moreData,
  }) async {
    try {
      final comData = await zeytin.getData(
        box: "communities",
        tag: communityId,
      );

      if (comData.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Community not found");
      }

      final community = ZeytinCommunityModel.fromJson(comData.data!);
      if (!community.admins.any((a) => a.uid == admin.uid)) {
        return ZeytinResponse(isSuccess: false, message: "Not authorized");
      }

      final String code = customCode ?? const Uuid().v4().substring(0, 8);
      final DateTime now = DateTime.now();
      final DateTime? expiresAt = duration != null ? now.add(duration) : null;

      final invite = ZeytinCommunityInviteModel(
        code: code,
        communityId: communityId,
        creatorId: admin.uid,
        createdAt: now,
        expiresAt: expiresAt,
        maxUses: maxUses,
        usedCount: 0,
        moreData: moreData ?? {},
      );

      return await zeytin.addData(
        box: "community_invites",
        tag: code,
        value: invite.toJson(),
      );
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<List<ZeytinCommunityInviteModel>> getInviteCodes({
    required String communityId,
  }) async {
    try {
      final filterRes = await zeytin.filter(
        box: "community_invites",
        field: "communityId",
        value: communityId,
      );

      if (!filterRes.isSuccess || filterRes.data == null) return [];

      List<ZeytinCommunityInviteModel> invites = [];
      if (filterRes.data is Map) {
        var rawList = filterRes.data!["results"];
        if (rawList is List) {
          for (var item in rawList) {
            invites.add(ZeytinCommunityInviteModel.fromJson(item));
          }
        }
      }
      return invites;
    } catch (e) {
      return [];
    }
  }

  Future<ZeytinResponse> validateInviteCode({required String code}) async {
    try {
      final res = await zeytin.getData(box: "community_invites", tag: code);

      if (res.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Invalid code");
      }

      final invite = ZeytinCommunityInviteModel.fromJson(res.data!);

      if (invite.isExpired) {
        return ZeytinResponse(isSuccess: false, message: "Code expired");
      }

      if (invite.isQuotaExceeded) {
        return ZeytinResponse(isSuccess: false, message: "Quota exceeded");
      }

      return ZeytinResponse(
        isSuccess: true,
        message: "Valid",
        data: invite.toJson(),
      );
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<ZeytinCommunityInviteModel?> getInvite({required String code}) async {
    try {
      final res = await zeytin.getData(box: "community_invites", tag: code);

      if (res.data == null) {
        return null;
      }

      return ZeytinCommunityInviteModel.fromJson(res.data!);
    } catch (e) {
      return null;
    }
  }

  Future<ZeytinResponse> useInviteCode({required String code}) async {
    try {
      final res = await zeytin.getData(box: "community_invites", tag: code);

      if (res.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Code not found");
      }

      var invite = ZeytinCommunityInviteModel.fromJson(res.data!);

      if (!invite.isValid) {
        return ZeytinResponse(
          isSuccess: false,
          message: "Code is not valid anymore",
        );
      }

      invite = invite.copyWith(usedCount: invite.usedCount + 1);

      return await zeytin.addData(
        box: "community_invites",
        tag: code,
        value: invite.toJson(),
      );
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<ZeytinResponse> deleteInviteCode({
    required String code,
    required String communityId,
    required ZeytinUserModel admin,
  }) async {
    try {
      final comData = await zeytin.getData(
        box: "communities",
        tag: communityId,
      );

      if (comData.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Community not found");
      }

      final community = ZeytinCommunityModel.fromJson(comData.data!);
      if (!community.admins.any((a) => a.uid == admin.uid)) {
        return ZeytinResponse(isSuccess: false, message: "Not authorized");
      }

      return await zeytin.deleteData(box: "community_invites", tag: code);
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<ZeytinResponse> createRoom({
    required String communityId,
    required ZeytinUserModel admin,
    required String roomName,
    ZeytinRoomType type = ZeytinRoomType.text,
  }) async {
    try {
      final comData = await zeytin.getData(
        box: "communities",
        tag: communityId,
      );
      if (comData.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Community not found");
      }

      final community = ZeytinCommunityModel.fromJson(comData.data!);
      if (!community.admins.any((a) => a.uid == admin.uid)) {
        return ZeytinResponse(
          isSuccess: false,
          message: "Only admins can create rooms",
        );
      }

      final roomId = const Uuid().v4();

      final newRoom = ZeytinCommunityRoomModel(
        id: roomId,
        communityId: communityId,
        name: roomName,
        type: type,
        createdAt: DateTime.now(),
      );
      return await zeytin.addData(
        box: "community_rooms",
        tag: roomId,
        value: newRoom.toJson(),
      );
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<ZeytinCommunityRoomModel?> getRoom({required String roomId}) async {
    try {
      final roomData = await zeytin.getData(
        box: "community_rooms",
        tag: roomId,
      );
      if (roomData.data == null) return null;
      return ZeytinCommunityRoomModel.fromJson(roomData.data!);
    } catch (e) {
      return null;
    }
  }

  Future<List<ZeytinCommunityRoomModel>> getCommunityRooms({
    required String communityId,
  }) async {
    try {
      final filterRes = await zeytin.filter(
        box: "community_rooms",
        field: "communityId",
        value: communityId,
      );

      if (!filterRes.isSuccess || filterRes.data == null) return [];

      List<ZeytinCommunityRoomModel> rooms = [];
      if (filterRes.data is Map) {
        var rawList = filterRes.data!["results"];
        if (rawList is List) {
          for (var item in rawList) {
            rooms.add(ZeytinCommunityRoomModel.fromJson(item));
          }
        }
      }
      rooms.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return rooms;
    } catch (e) {
      return [];
    }
  }

  Future<ZeytinResponse> editCommunity({
    required String communityId,
    required ZeytinUserModel admin,
    required ZeytinCommunityModel updatedCommunity,
  }) async {
    try {
      final comData = await zeytin.getData(
        box: "communities",
        tag: communityId,
      );

      if (comData.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Community not found");
      }

      final currentCommunity = ZeytinCommunityModel.fromJson(comData.data!);

      if (!currentCommunity.admins.any((a) => a.uid == admin.uid)) {
        return ZeytinResponse(isSuccess: false, message: "Not authorized");
      }

      if (updatedCommunity.id != communityId) {
        return ZeytinResponse(
          isSuccess: false,
          message: "Community ID mismatch",
        );
      }

      return await zeytin.addData(
        box: "communities",
        tag: communityId,
        value: updatedCommunity.toJson(),
      );
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<List<ZeytinCommunityModel>> getAllCommunities() async {
    try {
      final res = await zeytin.getBox(box: "communities");
      if (!res.isSuccess || res.data == null) return [];

      List<ZeytinCommunityModel> list = [];
      for (var key in res.data!.keys) {
        list.add(ZeytinCommunityModel.fromJson(res.data![key]));
      }

      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      return [];
    }
  }

  Future<void> _indexCommunityForParticipants(
    String communityId,
    List<ZeytinUserModel> participants,
  ) async {
    for (var user in participants) {
      var userCommunitiesRes = await zeytin.getData(
        box: "my_communities",
        tag: user.uid,
      );
      List<String> currentCommunityIds = [];

      if (userCommunitiesRes.isSuccess && userCommunitiesRes.data != null) {
        currentCommunityIds = List<String>.from(
          userCommunitiesRes.data!["communityIds"] ?? [],
        );
      }

      if (!currentCommunityIds.contains(communityId)) {
        currentCommunityIds.add(communityId);
        await zeytin.addData(
          box: "my_communities",
          tag: user.uid,
          value: {"communityIds": currentCommunityIds},
        );
      }
    }
  }

  Future<ZeytinResponse> setRules({
    required String communityId,
    required ZeytinUserModel admin,
    required String rules,
  }) async {
    try {
      final comData = await zeytin.getData(
        box: "communities",
        tag: communityId,
      );
      if (comData.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Community not found");
      }

      var community = ZeytinCommunityModel.fromJson(comData.data!);
      if (!community.admins.any((a) => a.uid == admin.uid)) {
        return ZeytinResponse(isSuccess: false, message: "Not authorized");
      }

      community = community.copyWith(rules: rules);

      return await zeytin.addData(
        box: "communities",
        tag: communityId,
        value: community.toJson(),
      );
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<String?> getRules({required String communityId}) async {
    try {
      final comData = await zeytin.getData(
        box: "communities",
        tag: communityId,
      );
      if (comData.data == null) return null;
      final community = ZeytinCommunityModel.fromJson(comData.data!);
      return community.rules;
    } catch (e) {
      return null;
    }
  }

  Future<ZeytinResponse> setStickers({
    required String communityId,
    required ZeytinUserModel admin,
    required List<String> stickers,
  }) async {
    try {
      final comData = await zeytin.getData(
        box: "communities",
        tag: communityId,
      );
      if (comData.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Community not found");
      }

      var community = ZeytinCommunityModel.fromJson(comData.data!);
      if (!community.admins.any((a) => a.uid == admin.uid)) {
        return ZeytinResponse(isSuccess: false, message: "Not authorized");
      }

      community = community.copyWith(stickers: stickers);

      return await zeytin.addData(
        box: "communities",
        tag: communityId,
        value: community.toJson(),
      );
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<List<String>> getStickers({required String communityId}) async {
    try {
      final comData = await zeytin.getData(
        box: "communities",
        tag: communityId,
      );
      if (comData.data == null) return [];
      final community = ZeytinCommunityModel.fromJson(comData.data!);
      return community.stickers;
    } catch (e) {
      return [];
    }
  }

  Future<ZeytinResponse> setPinnedPost({
    required String communityId,
    required ZeytinUserModel admin,
    required String postId,
  }) async {
    try {
      final comData = await zeytin.getData(
        box: "communities",
        tag: communityId,
      );
      if (comData.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Community not found");
      }

      var community = ZeytinCommunityModel.fromJson(comData.data!);
      if (!community.admins.any((a) => a.uid == admin.uid)) {
        return ZeytinResponse(isSuccess: false, message: "Not authorized");
      }

      final postData = await zeytin.getData(
        box: "community_boards",
        tag: postId,
      );
      if (postData.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Post not found");
      }

      community = community.copyWith(pinnedPostID: postId);

      return await zeytin.addData(
        box: "communities",
        tag: communityId,
        value: community.toJson(),
      );
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<ZeytinResponse> deletePinnedPost({
    required String communityId,
    required ZeytinUserModel admin,
  }) async {
    try {
      final comData = await zeytin.getData(
        box: "communities",
        tag: communityId,
      );
      if (comData.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Community not found");
      }

      var community = ZeytinCommunityModel.fromJson(comData.data!);
      if (!community.admins.any((a) => a.uid == admin.uid)) {
        return ZeytinResponse(isSuccess: false, message: "Not authorized");
      }

      community = community.copyWith(pinnedPostID: null);

      return await zeytin.addData(
        box: "communities",
        tag: communityId,
        value: community.toJson(),
      );
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<ZeytinCommunityBoardPostModel?> getPinnedPost({
    required String communityId,
  }) async {
    try {
      final comData = await zeytin.getData(
        box: "communities",
        tag: communityId,
      );
      if (comData.data == null) return null;

      final community = ZeytinCommunityModel.fromJson(comData.data!);
      if (community.pinnedPostID == null) return null;

      final postData = await zeytin.getData(
        box: "community_boards",
        tag: community.pinnedPostID!,
      );
      if (postData.data == null) return null;

      return ZeytinCommunityBoardPostModel.fromJson(postData.data!);
    } catch (e) {
      return null;
    }
  }

  Future<List<ZeytinCommunityModel>> getCommunitiesForUser({
    required ZeytinUserModel user,
  }) async {
    try {
      final indexRes = await zeytin.getData(
        box: "my_communities",
        tag: user.uid,
      );
      if (!indexRes.isSuccess || indexRes.data == null) return [];

      List<String> communityIds = List<String>.from(
        indexRes.data!["communityIds"] ?? [],
      );
      if (communityIds.isEmpty) return [];

      List<ZeytinCommunityModel> userCommunities = [];
      for (var id in communityIds) {
        final communityData = await zeytin.getData(box: "communities", tag: id);
        if (communityData.isSuccess && communityData.data != null) {
          userCommunities.add(
            ZeytinCommunityModel.fromJson(communityData.data!),
          );
        }
      }
      userCommunities.sort(
        (a, b) => b.lastMessageTimestamp.compareTo(a.lastMessageTimestamp),
      );
      return userCommunities;
    } catch (e) {
      return [];
    }
  }

  Future<ZeytinCommunityModel?> getCommunity({required String id}) async {
    try {
      final data = await zeytin.getData(box: "communities", tag: id);
      if (data.data == null) return null;
      return ZeytinCommunityModel.fromJson(data.data!);
    } catch (e) {
      return null;
    }
  }

  Future<bool?> isParticipant({
    required String communityId,
    required ZeytinUserModel user,
  }) async {
    try {
      final comData = await zeytin.getData(
        box: "communities",
        tag: communityId,
      );
      if (comData.data == null) return null;
      final community = ZeytinCommunityModel.fromJson(comData.data!);
      return community.participants.any((p) => p.uid == user.uid);
    } catch (e) {
      return null;
    }
  }

  Future<bool?> isAdmin({
    required String communityId,
    required ZeytinUserModel user,
  }) async {
    try {
      final comData = await zeytin.getData(
        box: "communities",
        tag: communityId,
      );
      if (comData.data == null) return null;
      final community = ZeytinCommunityModel.fromJson(comData.data!);
      return community.admins.any((p) => p.uid == user.uid);
    } catch (e) {
      return null;
    }
  }

  Future<ZeytinResponse> joinCommunity({
    required String communityId,
    required ZeytinUserModel user,
  }) async {
    try {
      final comData = await zeytin.getData(
        box: "communities",
        tag: communityId,
      );
      if (comData.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Community not found");
      }

      final community = ZeytinCommunityModel.fromJson(comData.data!);
      final participants = community.participants;

      if (participants.any((p) => p.uid == user.uid)) {
        return ZeytinResponse(isSuccess: true, message: "Already a member");
      }

      participants.add(user);
      final updatedCommunity = community.copyWith(participants: participants);

      final res = await zeytin.addData(
        box: "communities",
        tag: communityId,
        value: updatedCommunity.toJson(),
      );

      if (res.isSuccess) {
        await _indexCommunityForParticipants(communityId, [user]);
      }
      return res;
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<List<ZeytinUserModel>> getParticipants({
    required String communityId,
  }) async {
    try {
      final comData = await zeytin.getData(
        box: "communities",
        tag: communityId,
      );
      if (comData.data == null) return [];
      final community = ZeytinCommunityModel.fromJson(comData.data!);
      return community.participants;
    } catch (e) {
      return [];
    }
  }

  Future<List<ZeytinUserModel>> getAdmins({required String communityId}) async {
    try {
      final comData = await zeytin.getData(
        box: "communities",
        tag: communityId,
      );
      if (comData.data == null) return [];
      final community = ZeytinCommunityModel.fromJson(comData.data!);
      return community.admins;
    } catch (e) {
      return [];
    }
  }

  Future<ZeytinResponse> leaveCommunity({
    required String communityId,
    required ZeytinUserModel user,
  }) async {
    try {
      final comData = await zeytin.getData(
        box: "communities",
        tag: communityId,
      );
      if (comData.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Community not found");
      }

      final community = ZeytinCommunityModel.fromJson(comData.data!);
      final participants = community.participants
          .where((p) => p.uid != user.uid)
          .toList();
      final updatedCommunity = community.copyWith(participants: participants);

      final res = await zeytin.addData(
        box: "communities",
        tag: communityId,
        value: updatedCommunity.toJson(),
      );

      if (res.isSuccess) {
        var userComsRes = await zeytin.getData(
          box: "my_communities",
          tag: user.uid,
        );
        if (userComsRes.isSuccess && userComsRes.data != null) {
          List<String> currentIds = List<String>.from(
            userComsRes.data!["communityIds"] ?? [],
          );
          currentIds.remove(communityId);
          await zeytin.addData(
            box: "my_communities",
            tag: user.uid,
            value: {"communityIds": currentIds},
          );
        }
      }
      return res;
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<ZeytinResponse> sendMessage({
    required String communityId,
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
        chatId: communityId,
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
        await _updateCommunityLastMessage(communityId, message, sender);
      }

      return response;
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<void> _updateCommunityLastMessage(
    String communityId,
    ZeytinMessage message,
    ZeytinUserModel sender,
  ) async {
    try {
      final comData = await zeytin.getData(
        box: "communities",
        tag: communityId,
      );
      if (comData.data == null) return;

      var community = ZeytinCommunityModel.fromJson(comData.data!);
      community = community.copyWith(
        lastMessage: message.messageType == ZeytinMessageType.text
            ? message.text
            : message.messageType.value,
        lastMessageTimestamp: message.timestamp,
        lastMessageSender: sender,
      );

      await zeytin.addData(
        box: "communities",
        tag: communityId,
        value: community.toJson(),
      );
    } catch (e) {
      rethrow;
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

  Future<List<ZeytinMessage>> getMessages({
    required String communityId,
    int? limit,
    int? offset,
  }) async {
    try {
      final filterRes = await zeytin.filter(
        box: "messages",
        field: "chatId",
        value: communityId,
      );

      if (!filterRes.isSuccess || filterRes.data == null) return [];

      List<ZeytinMessage> messages = [];
      if (filterRes.data is Map) {
        var rawList = filterRes.data!["results"];
        if (rawList is List) {
          for (var item in rawList) {
            messages.add(ZeytinMessage.fromJson(item));
          }
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
      return [];
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
    required String targetCommunityId,
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
        chatId: targetCommunityId,
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
        await _updateCommunityLastMessage(
          targetCommunityId,
          forwardedMessage,
          sender,
        );
      }
      return response;
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<List<ZeytinMessage>> searchMessages({
    required String communityId,
    required String query,
  }) async {
    try {
      final allMessages = await getMessages(
        communityId: communityId,
        limit: 1000,
      );
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
    required String communityId,
  }) async {
    try {
      final messageData = await zeytin.getData(box: "messages", tag: messageId);
      if (messageData.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Message not found");
      }

      var message = ZeytinMessage.fromJson(messageData.data!);
      if (message.chatId != communityId) {
        return ZeytinResponse(
          isSuccess: false,
          message: "Message not in this community",
        );
      }

      message = message.copyWith(
        isPinned: true,
        pinnedBy: pinnedBy,
        pinnedTimestamp: DateTime.now(),
      );

      final comData = await zeytin.getData(
        box: "communities",
        tag: communityId,
      );
      if (comData.data != null) {
        var community = ZeytinCommunityModel.fromJson(comData.data!);
        final pinnedIDs = community.pinnedMessageIDs;
        if (!pinnedIDs.contains(messageId)) {
          pinnedIDs.add(messageId);
          community = community.copyWith(pinnedMessageIDs: pinnedIDs);
          await zeytin.addData(
            box: "communities",
            tag: communityId,
            value: community.toJson(),
          );
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
    required String communityId,
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

      final comData = await zeytin.getData(
        box: "communities",
        tag: communityId,
      );
      if (comData.data != null) {
        var community = ZeytinCommunityModel.fromJson(comData.data!);
        final pinnedIDs = community.pinnedMessageIDs;
        pinnedIDs.remove(messageId);
        community = community.copyWith(pinnedMessageIDs: pinnedIDs);
        await zeytin.addData(
          box: "communities",
          tag: communityId,
          value: community.toJson(),
        );
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
    required String communityId,
  }) async {
    try {
      final comData = await zeytin.getData(
        box: "communities",
        tag: communityId,
      );
      if (comData.data == null) return [];

      final community = ZeytinCommunityModel.fromJson(comData.data!);
      List<ZeytinMessage> pinnedMessages = [];

      for (var id in community.pinnedMessageIDs) {
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

  StreamSubscription<Map<String, dynamic>> listenMessages({
    required String communityId,
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
        if (message.chatId.trim() == communityId.trim()) {
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

  StreamSubscription listenCommunity({
    required ZeytinUserModel user,
    required Function(ZeytinCommunityModel community) onCreated,
    required Function(ZeytinCommunityModel community) onUpdated,
    required Function(String communityId) onDeleted,
  }) {
    return zeytin.watchBox(box: "communities").listen((event) {
      final op = event["op"];
      final tag = event["tag"];
      final rawData = event["data"];

      if (op == "DELETE") {
        onDeleted(tag.toString());
        return;
      }

      if (rawData != null) {
        final community = ZeytinCommunityModel.fromJson(rawData);
        if (community.participants.any((p) => p.uid == user.uid)) {
          if (op == "PUT") {
            onCreated(community);
          } else if (op == "UPDATE") {
            onUpdated(community);
          }
        }
      }
    });
  }

  Future<ZeytinResponse> sendBoardPost({
    required String communityId,
    required ZeytinUserModel sender,
    required String text,
    String? imageURL,
    Map<String, dynamic>? moreData,
  }) async {
    try {
      final comData = await zeytin.getData(
        box: "communities",
        tag: communityId,
      );

      if (comData.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Community not found");
      }

      final community = ZeytinCommunityModel.fromJson(comData.data!);
      if (!community.admins.any((admin) => admin.uid == sender.uid)) {
        return ZeytinResponse(
          isSuccess: false,
          message: "Only admins can post to board",
        );
      }

      final postId = const Uuid().v4();
      final post = ZeytinCommunityBoardPostModel(
        id: postId,
        communityId: communityId,
        sender: sender,
        text: text,
        imageURL: imageURL,
        seenBy: [],
        createdAt: DateTime.now(),
        moreData: moreData ?? {},
      );

      return await zeytin.addData(
        box: "community_boards",
        tag: postId,
        value: post.toJson(),
      );
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<ZeytinResponse> markBoardPostSeen({
    required String postId,
    required ZeytinUserModel user,
  }) async {
    try {
      final postData = await zeytin.getData(
        box: "community_boards",
        tag: postId,
      );
      if (postData.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Post not found");
      }

      final post = ZeytinCommunityBoardPostModel.fromJson(postData.data!);
      if (post.seenBy.contains(user.uid)) {
        return ZeytinResponse(isSuccess: true, message: "Already seen");
      }

      final updatedSeenBy = List<String>.from(post.seenBy)..add(user.uid);
      final updatedPost = post.copyWith(seenBy: updatedSeenBy);

      return await zeytin.addData(
        box: "community_boards",
        tag: postId,
        value: updatedPost.toJson(),
      );
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<int> getBoardPostSeenCount({required String postId}) async {
    try {
      final postData = await zeytin.getData(
        box: "community_boards",
        tag: postId,
      );
      if (postData.data == null) return 0;
      final post = ZeytinCommunityBoardPostModel.fromJson(postData.data!);
      return post.seenBy.length;
    } catch (e) {
      return 0;
    }
  }

  Future<ZeytinResponse> deleteBoardPost({
    required String communityId,
    required String postId,
    required ZeytinUserModel admin,
  }) async {
    try {
      final comData = await zeytin.getData(
        box: "communities",
        tag: communityId,
      );
      if (comData.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Community not found");
      }

      final community = ZeytinCommunityModel.fromJson(comData.data!);
      if (!community.admins.any((a) => a.uid == admin.uid)) {
        return ZeytinResponse(isSuccess: false, message: "Not authorized");
      }

      return await zeytin.deleteData(box: "community_boards", tag: postId);
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<ZeytinResponse> editBoardPost({
    required String communityId,
    required String postId,
    required ZeytinUserModel admin,
    String? newText,
    String? newImageURL,
  }) async {
    try {
      final comData = await zeytin.getData(
        box: "communities",
        tag: communityId,
      );
      if (comData.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Community not found");
      }

      final community = ZeytinCommunityModel.fromJson(comData.data!);
      if (!community.admins.any((a) => a.uid == admin.uid)) {
        return ZeytinResponse(isSuccess: false, message: "Not authorized");
      }

      final postData = await zeytin.getData(
        box: "community_boards",
        tag: postId,
      );
      if (postData.data == null) {
        return ZeytinResponse(isSuccess: false, message: "Post not found");
      }

      var post = ZeytinCommunityBoardPostModel.fromJson(postData.data!);
      post = post.copyWith(
        text: newText ?? post.text,
        imageURL: newImageURL ?? post.imageURL,
        updatedAt: DateTime.now(),
      );

      return await zeytin.addData(
        box: "community_boards",
        tag: postId,
        value: post.toJson(),
      );
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<List<ZeytinCommunityBoardPostModel>> getBoardPosts({
    required String communityId,
  }) async {
    try {
      final filterRes = await zeytin.filter(
        box: "community_boards",
        field: "communityId",
        value: communityId,
      );

      if (!filterRes.isSuccess || filterRes.data == null) return [];

      List<ZeytinCommunityBoardPostModel> posts = [];
      if (filterRes.data is Map) {
        var rawList = filterRes.data!["results"];
        if (rawList is List) {
          for (var item in rawList) {
            posts.add(ZeytinCommunityBoardPostModel.fromJson(item));
          }
        }
      }
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return posts;
    } catch (e) {
      return [];
    }
  }
}
