import 'package:uuid/uuid.dart';
import 'package:zeytin/src/models/notification.dart';
import 'package:zeytin/src/models/response.dart';
import 'package:zeytin/src/services/client.dart';

class ZeytinNotificationService {
  final ZeytinClient zeytin;

  ZeytinNotificationService(this.zeytin);
  Future<ZeytinResponse> sendNotification({
    required String title,
    required String description,
    required List<String> targetUserIds,
    String type = 'general',
    List<ZeytinNotificationMediaModel>? media,
    bool isInApp = false,
    String? inAppTag,
    Map<String, dynamic>? moreData,
  }) async {
    try {
      final id = const Uuid().v4();
      final now = DateTime.now();
      final notification = ZeytinNotificationModel(
        id: id,
        title: title,
        description: description,
        createdAt: now,
        targetUserIds: targetUserIds,
        media: media ?? [],
        type: type,
        seenBy: [],
        isInApp: isInApp,
        inAppTag: inAppTag,
        moreData: moreData ?? {},
      );
      final res = await zeytin.addData(
        box: "notifications",
        tag: id,
        value: notification.toJson(),
      );

      if (res.isSuccess) {
        await _indexNotificationForUsers(id, targetUserIds);

        return ZeytinResponse(
          isSuccess: true,
          message: "Notification sent successfully",
          data: notification.toJson(),
        );
      }
      return res;
    } catch (e) {
      return ZeytinResponse(
        isSuccess: false,
        message: "Error sending notification: $e",
      );
    }
  }

  Future<void> _indexNotificationForUsers(
    String notificationId,
    List<String> userIds,
  ) async {
    for (var uid in userIds) {
      var userBox = await zeytin.getData(box: "my_notifications", tag: uid);
      List<String> currentIds = [];

      if (userBox.isSuccess && userBox.data != null) {
        currentIds = List<String>.from(userBox.data!["notificationIds"] ?? []);
      }
      if (!currentIds.contains(notificationId)) {
        currentIds.add(notificationId);
        await zeytin.addData(
          box: "my_notifications",
          tag: uid,
          value: {"notificationIds": currentIds},
        );
      }
    }
  }

  Future<List<ZeytinNotificationModel>> _fetchUserNotificationsRaw(
    String userId,
  ) async {
    try {
      final indexRes = await zeytin.getData(
        box: "my_notifications",
        tag: userId,
      );
      if (!indexRes.isSuccess || indexRes.data == null) return [];

      List<String> ids = List<String>.from(
        indexRes.data!["notificationIds"] ?? [],
      );
      if (ids.isEmpty) return [];

      List<ZeytinNotificationModel> notifications = [];
      for (var id in ids) {
        final dataRes = await zeytin.getData(box: "notifications", tag: id);
        if (dataRes.isSuccess && dataRes.data != null) {
          notifications.add(ZeytinNotificationModel.fromJson(dataRes.data!));
        }
      }
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifications;
    } catch (e) {
      return [];
    }
  }

  Future<List<ZeytinNotificationModel>> getLastHourNotifications(
    String userId,
  ) async {
    final all = await _fetchUserNotificationsRaw(userId);
    final deadline = DateTime.now().subtract(const Duration(hours: 1));
    return all.where((n) => n.createdAt.isAfter(deadline)).toList();
  }

  Future<List<ZeytinNotificationModel>> getLastDayNotifications(
    String userId,
  ) async {
    final all = await _fetchUserNotificationsRaw(userId);
    final deadline = DateTime.now().subtract(const Duration(days: 1));
    return all.where((n) => n.createdAt.isAfter(deadline)).toList();
  }

  Future<List<ZeytinNotificationModel>> getLastMonthNotifications(
    String userId,
  ) async {
    final all = await _fetchUserNotificationsRaw(userId);
    final deadline = DateTime.now().subtract(const Duration(days: 30));
    return all.where((n) => n.createdAt.isAfter(deadline)).toList();
  }

  Future<List<ZeytinNotificationModel>> getAllSentNotifications() async {
    try {
      final res = await zeytin.getBox(box: "notifications");
      if (!res.isSuccess || res.data == null) return [];

      List<ZeytinNotificationModel> list = [];
      for (var key in res.data!.keys) {
        list.add(ZeytinNotificationModel.fromJson(res.data![key]));
      }
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      return [];
    }
  }

  Future<ZeytinResponse> deleteNotification({
    required String notificationId,
  }) async {
    return await zeytin.deleteData(box: "notifications", tag: notificationId);
  }

  Future<ZeytinResponse> sendInAppNotification({
    required String title,
    required String description,
    required String tag,
    required List<String> targetUserIds,
    List<ZeytinNotificationMediaModel>? media,
    Map<String, dynamic>? moreData,
  }) async {
    return await sendNotification(
      title: title,
      description: description,
      targetUserIds: targetUserIds,
      type: 'in_app',
      isInApp: true,
      inAppTag: tag,
      media: media,
      moreData: moreData,
    );
  }

  Future<List<ZeytinNotificationModel>> getPendingInAppNotifications(
    String userId,
  ) async {
    final all = await _fetchUserNotificationsRaw(userId);

    return all.where((n) {
      return n.isInApp && !n.seenBy.contains(userId);
    }).toList();
  }

  Future<ZeytinResponse> markAsSeen({
    required String notificationId,
    required String userId,
  }) async {
    try {
      final res = await zeytin.getData(
        box: "notifications",
        tag: notificationId,
      );
      if (res.data == null) {
        return ZeytinResponse(
          isSuccess: false,
          message: "Notification not found",
        );
      }

      var notification = ZeytinNotificationModel.fromJson(res.data!);

      if (!notification.seenBy.contains(userId)) {
        final updatedSeenBy = List<String>.from(notification.seenBy)
          ..add(userId);

        final updatedNotification = notification.copyWith(
          seenBy: updatedSeenBy,
        );

        return await zeytin.addData(
          box: "notifications",
          tag: notificationId,
          value: updatedNotification.toJson(),
        );
      }

      return ZeytinResponse(isSuccess: true, message: "Already seen");
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }
}
