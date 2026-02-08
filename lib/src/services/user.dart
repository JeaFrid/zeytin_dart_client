import 'package:uuid/uuid.dart';
import 'package:zeytin/zeytin.dart';

class ZeytinUser {
  ZeytinClient zeytin;
  ZeytinUser(this.zeytin);
  Future<ZeytinResponse> create(
    String name,
    String email,
    String password,
  ) async {
    try {
      if (!ZeytinValidators.isValidEmail(email)) {
        return ZeytinResponse(
          isSuccess: false,
          message: "Invalid format",
          error: "Please enter a valid email address.",
        );
      }
      if (!ZeytinValidators.isValidPassword(password)) {
        return ZeytinResponse(
          isSuccess: false,
          message: "Weak password",
          error: "Your password must be at least 6 characters long.",
        );
      }
      bool existEmail = await exist(email);
      if (existEmail) {
        return ZeytinResponse(
          isSuccess: false,
          message: "Email available",
          error: "This email is already registered.",
        );
      } else {
        String uid = const Uuid().v1();
        var emptyUser = ZeytinUserModel.empty();
        var newUser = emptyUser.copyWith(
          uid: uid,
          username: name,
          email: email,
          password: password,
          accountCreation: DateTime.now().toIso8601String(),
        );
        var res = await zeytin.addData(
          box: "users",
          tag: uid,
          value: newUser.toJson(),
        );

        if (res.isSuccess) {
          return ZeytinResponse(
            isSuccess: true,
            message: "ok",
            data: newUser.toJson(),
          );
        }
        return res;
      }
    } catch (e) {
      return ZeytinResponse(
        isSuccess: false,
        message: "Error",
        error: e.toString(),
      );
    }
  }

  Future<bool> isActive(
    ZeytinUserModel user, {
    int thresholdSeconds = 10,
  }) async {
    final response = await zeytin.getData(box: "users", tag: user.uid);
    if (response.isSuccess && response.data != null) {
      final currentData = ZeytinUserModel.fromJson(response.data!);
      if (currentData.lastLoginTimestamp.isEmpty) return false;

      final lastSeenTime = DateTime.parse(currentData.lastLoginTimestamp);
      final difference = DateTime.now().difference(lastSeenTime).inSeconds;

      return difference <= thresholdSeconds;
    }
    return false;
  }

  Future<ZeytinResponse> updateUserActive(ZeytinUserModel user) async {
    final updatedUser = user.copyWith(
      lastLoginTimestamp: DateTime.now().toIso8601String(),
    );
    return await zeytin.addData(
      box: "users",
      tag: user.uid,
      value: updatedUser.toJson(),
    );
  }

  Future<ZeytinResponse> followUser({
    required String myUid,
    required String targetUid,
  }) async {
    try {
      ZeytinUserModel? me = await getProfile(userId: myUid);
      ZeytinUserModel? targetUser = await getProfile(userId: targetUid);

      if (me == null || targetUser == null) {
        return ZeytinResponse(isSuccess: false, message: "User not found");
      }

      List<String> myFollowing = List<String>.from(me.following);
      if (!myFollowing.contains(targetUid)) myFollowing.add(targetUid);

      List<String> targetFollowers = List<String>.from(targetUser.followers);
      if (!targetFollowers.contains(myUid)) targetFollowers.add(myUid);

      await zeytin.addData(
        box: "users",
        tag: me.uid,
        value: me.copyWith(following: myFollowing).toJson(),
      );
      await zeytin.addData(
        box: "users",
        tag: targetUid,
        value: targetUser.copyWith(followers: targetFollowers).toJson(),
      );

      return ZeytinResponse(isSuccess: true, message: "Followed successfully");
    } catch (e) {
      return ZeytinResponse(
        isSuccess: false,
        message: "Follow error",
        error: e.toString(),
      );
    }
  }

  Future<bool> isFollow({
    required String myUid,
    required String targetUid,
  }) async {
    final userData = await zeytin.getData(box: "users", tag: myUid);
    if (userData.isSuccess && userData.data != null) {
      final me = ZeytinUserModel.fromJson(userData.data!);
      return me.following.contains(targetUid);
    }
    return false;
  }

  Future<ZeytinResponse> unfollowUser({
    required String myUid,
    required String targetUid,
  }) async {
    try {
      ZeytinUserModel? me = await getProfile(userId: myUid);
      ZeytinUserModel? targetUser = await getProfile(userId: targetUid);

      if (me == null || targetUser == null) {
        return ZeytinResponse(isSuccess: false, message: "User not found");
      }

      List<String> myFollowing = List<String>.from(me.following);
      myFollowing.remove(targetUid);

      List<String> targetFollowers = List<String>.from(targetUser.followers);
      targetFollowers.remove(myUid);

      await zeytin.addData(
        box: "users",
        tag: me.uid,
        value: me.copyWith(following: myFollowing).toJson(),
      );
      await zeytin.addData(
        box: "users",
        tag: targetUid,
        value: targetUser.copyWith(followers: targetFollowers).toJson(),
      );

      return ZeytinResponse(
        isSuccess: true,
        message: "Unfollowed successfully",
      );
    } catch (e) {
      return ZeytinResponse(
        isSuccess: false,
        message: "Unfollow error",
        error: e.toString(),
      );
    }
  }

  Future<ZeytinResponse> blockUser({
    required String myUid,
    required String targetUid,
  }) async {
    try {
      ZeytinUserModel? me = await getProfile(userId: myUid);
      if (me == null) {
        return ZeytinResponse(isSuccess: false, message: "User not found");
      }

      List<String> myBlocked = List<String>.from(me.blockedUsers);
      if (!myBlocked.contains(targetUid)) myBlocked.add(targetUid);

      List<String> myFollowing = List<String>.from(me.following);
      myFollowing.remove(targetUid);

      var res = await zeytin.addData(
        box: "users",
        tag: me.uid,
        value: me
            .copyWith(blockedUsers: myBlocked, following: myFollowing)
            .toJson(),
      );

      if (res.isSuccess) {
        final chatService = ZeytinChat(zeytin);
        final myChats = await chatService.getChatsForUser(user: me);

        for (var chat in myChats) {
          if (chat.type == ZeytinChatType.private) {
            bool isBetweenUs = chat.participants.any((p) => p.uid == targetUid);
            if (isBetweenUs) {
              await chatService.deleteChatAndAllMessage(chatId: chat.chatID);
            }
          }
        }
      }

      return ZeytinResponse(
        isSuccess: true,
        message: "User blocked and chat destroyed",
      );
    } catch (e) {
      return ZeytinResponse(
        isSuccess: false,
        message: "Block error",
        error: e.toString(),
      );
    }
  }

  Future<ZeytinResponse> unblockUser({
    required String myUid,
    required String targetUid,
  }) async {
    try {
      ZeytinUserModel? me = await getProfile(userId: myUid);
      if (me == null) {
        return ZeytinResponse(isSuccess: false, message: "User not found");
      }

      List<String> myBlocked = List<String>.from(me.blockedUsers);
      myBlocked.remove(targetUid);

      await zeytin.addData(
        box: "users",
        tag: me.uid,
        value: me.copyWith(blockedUsers: myBlocked).toJson(),
      );

      return ZeytinResponse(isSuccess: true, message: "User unblocked");
    } catch (e) {
      return ZeytinResponse(
        isSuccess: false,
        message: "Unblock error",
        error: e.toString(),
      );
    }
  }

  Future<bool> isBlocked({
    required String myUid,
    required String targetUid,
  }) async {
    final userData = await zeytin.getData(box: "users", tag: myUid);
    if (userData.isSuccess && userData.data != null) {
      final me = ZeytinUserModel.fromJson(userData.data!);
      return me.blockedUsers.contains(targetUid);
    }
    return false;
  }

  Future<bool> exist(String email) async {
    var res = await zeytin.getBox(box: "users");
    for (var element in res.data?.keys ?? []) {
      var user = ZeytinUserModel.fromJson(res.data![element]);

      if (user.email.toLowerCase() == email.toLowerCase()) {
        return true;
      }
    }
    return false;
  }

  Future<ZeytinResponse> login(String email, String password) async {
    try {
      bool existE = await exist(email);
      if (existE) {
        var res = await zeytin.getBox(box: "users");

        for (var element in res.data!.keys) {
          var val = res.data![element];
          if (val["email"].toString().toLowerCase() == email.toLowerCase()) {}
          if (val["email"].toString().toLowerCase() == email.toLowerCase() &&
              val["password"].toString().trim() == password.toString().trim()) {
            return ZeytinResponse(isSuccess: true, message: "ok", data: val);
          }
        }
        return ZeytinResponse(isSuccess: false, message: "Wrong password");
      } else {
        return ZeytinResponse(isSuccess: false, message: "Account not found");
      }
    } catch (e) {
      ZeytinPrint.errorPrint(e.toString());
      return ZeytinResponse(
        isSuccess: false,
        message: "Opps...",
        error: e.toString(),
      );
    }
  }

  Future<ZeytinUserModel?> getProfile({required String userId}) async {
    try {
      final userData = await zeytin.getData(box: "users", tag: userId);
      if (!userData.isSuccess) {
        ZeytinPrint.errorPrint(userData.error ?? "Umm...");
      }
      if (userData.data == null) return null;
      return ZeytinUserModel.fromJson(userData.data!);
    } catch (e) {
      return null;
    }
  }

  Future<List<ZeytinUserModel>> getAllProfile() async {
    try {
      final allUsers = await zeytin.getBox(box: "users");
      List<ZeytinUserModel> users = [];
      for (var element in allUsers.data!.keys) {
        users.add(ZeytinUserModel.fromJson(allUsers.data![element]));
      }
      return users;
    } catch (e) {
      return [];
    }
  }

  Future<ZeytinResponse> updateProfile(
    ZeytinUserModel user,
    ZeytinUserModel newUser,
  ) async {
    try {
      var res = await zeytin.addData(
        box: "users",
        tag: user.uid,
        value: newUser.toJson(),
      );
      if (res.isSuccess) {
        return ZeytinResponse(
          isSuccess: true,
          message: "ok",
          data: newUser.toJson(),
        );
      } else {
        return res;
      }
    } catch (e) {
      return ZeytinResponse(
        isSuccess: false,
        message: e.toString(),
        error: e.toString(),
      );
    }
  }
}
