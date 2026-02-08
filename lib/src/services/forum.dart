import 'package:zeytin/src/models/response.dart';
import 'package:zeytin/src/models/forum.dart';
import 'package:zeytin/src/models/user.dart';
import 'package:zeytin/src/services/client.dart';
import 'package:uuid/uuid.dart';

class ZeytinForum {
  ZeytinClient zeytin;
  ZeytinForum(this.zeytin);

  Future<ZeytinResponse> createCategory({
    required ZeytinForumCategoryModel categoryModel,
  }) async {
    String id = const Uuid().v1();
    return await zeytin.addData(
      box: "forum_categories",
      tag: id,
      value: categoryModel.copyWith(id: id).toJson(),
    );
  }

  Future<ZeytinResponse> deleteCategory({required String id}) async {
    return await zeytin.deleteData(box: "forum_categories", tag: id);
  }

  Future<ZeytinResponse> updateCategory({
    required String id,
    required ZeytinForumCategoryModel categoryModel,
  }) async {
    return await zeytin.addData(
      box: "forum_categories",
      tag: id,
      value: categoryModel.copyWith(id: id).toJson(),
    );
  }

  Future<List<ZeytinForumCategoryModel>> getAllCategories() async {
    List<ZeytinForumCategoryModel> list = [];
    var res = await zeytin.getBox(box: "forum_categories");
    if (res.data != null) {
      for (var element in res.data!.keys) {
        list.add(ZeytinForumCategoryModel.fromJson(res.data![element]));
      }
    }
    list.sort((a, b) => a.order.compareTo(b.order));
    return list;
  }

  Future<ZeytinResponse> createThread({
    required ZeytinForumThreadModel threadModel,
  }) async {
    String id = const Uuid().v1();
    DateTime now = DateTime.now();
    return await zeytin.addData(
      box: "forum_threads",
      tag: id,
      value: threadModel
          .copyWith(id: id, createdAt: now, lastActivityAt: now)
          .toJson(),
    );
  }

  Future<ZeytinResponse> deleteThread({required String id}) async {
    return await zeytin.deleteData(box: "forum_threads", tag: id);
  }

  Future<ZeytinResponse> updateThread({
    required String id,
    required ZeytinForumThreadModel threadModel,
  }) async {
    return await zeytin.addData(
      box: "forum_threads",
      tag: id,
      value: threadModel.copyWith(id: id).toJson(),
    );
  }

  Future<ZeytinForumThreadModel> getThread({required String id}) async {
    var res = await zeytin.getData(box: "forum_threads", tag: id);
    return ZeytinForumThreadModel.fromJson(res.data ?? {});
  }

  Future<List<ZeytinForumThreadModel>> getAllThreads() async {
    List<ZeytinForumThreadModel> list = [];
    var res = await zeytin.getBox(box: "forum_threads");
    if (res.data != null) {
      for (var element in res.data!.keys) {
        list.add(ZeytinForumThreadModel.fromJson(res.data![element]));
      }
    }
    list.sort((a, b) {
      DateTime dateA = a.lastActivityAt ?? DateTime(1970);
      DateTime dateB = b.lastActivityAt ?? DateTime(1970);
      return dateB.compareTo(dateA);
    });
    return list;
  }

  Future<List<ZeytinForumThreadModel>> getThreadsByCategory(
    String categoryId,
  ) async {
    List<ZeytinForumThreadModel> allThreads = await getAllThreads();
    return allThreads.where((t) => t.categoryId == categoryId).toList();
  }

  Future<ZeytinResponse> addThreadLike({
    required ZeytinUserModel user,
    required String threadId,
  }) async {
    ZeytinForumThreadModel thread = await getThread(id: threadId);
    List<String> likes = List<String>.from(thread.likes);
    if (!likes.contains(user.uid)) {
      likes.add(user.uid);
      return await updateThread(
        id: threadId,
        threadModel: thread.copyWith(likes: likes),
      );
    }
    return ZeytinResponse(isSuccess: true, message: "Already liked");
  }

  Future<ZeytinResponse> removeThreadLike({
    required ZeytinUserModel user,
    required String threadId,
  }) async {
    ZeytinForumThreadModel thread = await getThread(id: threadId);
    List<String> likes = List<String>.from(thread.likes);
    if (likes.contains(user.uid)) {
      likes.remove(user.uid);
      return await updateThread(
        id: threadId,
        threadModel: thread.copyWith(likes: likes),
      );
    }
    return ZeytinResponse(isSuccess: true, message: "Not liked");
  }

  Future<ZeytinResponse> addView({required String threadId}) async {
    ZeytinForumThreadModel thread = await getThread(id: threadId);
    return await updateThread(
      id: threadId,
      threadModel: thread.copyWith(viewCount: thread.viewCount + 1),
    );
  }

  Future<ZeytinResponse> addEntry({
    required ZeytinForumEntryModel entry,
    required String threadId,
  }) async {
    ZeytinForumThreadModel thread = await getThread(id: threadId);
    if (thread.isLocked) {
      return ZeytinResponse(isSuccess: false, message: "Thread is locked");
    }

    List<ZeytinForumEntryModel> entries = List.from(thread.entries);
    DateTime now = DateTime.now();

    entries.add(
      entry.copyWith(id: const Uuid().v1(), threadId: threadId, createdAt: now),
    );

    return await updateThread(
      id: threadId,
      threadModel: thread.copyWith(entries: entries, lastActivityAt: now),
    );
  }

  Future<ZeytinResponse> deleteEntry({
    required String entryId,
    required String threadId,
  }) async {
    ZeytinForumThreadModel thread = await getThread(id: threadId);
    List<ZeytinForumEntryModel> entries = List.from(thread.entries);

    entries.removeWhere((element) => element.id == entryId);

    return await updateThread(
      id: threadId,
      threadModel: thread.copyWith(entries: entries),
    );
  }

  Future<ZeytinResponse> editEntry({
    required String entryId,
    required String threadId,
    required String newText,
  }) async {
    ZeytinForumThreadModel thread = await getThread(id: threadId);
    List<ZeytinForumEntryModel> entries = List.from(thread.entries);

    int index = entries.indexWhere((e) => e.id == entryId);
    if (index != -1) {
      entries[index] = entries[index].copyWith(
        text: newText,
        isEdited: true,
        updatedAt: DateTime.now(),
      );
      return await updateThread(
        id: threadId,
        threadModel: thread.copyWith(entries: entries),
      );
    }
    return ZeytinResponse(isSuccess: false, message: "Entry not found");
  }

  Future<ZeytinResponse> addEntryLike({
    required ZeytinUserModel user,
    required String threadId,
    required String entryId,
  }) async {
    ZeytinForumThreadModel thread = await getThread(id: threadId);
    List<ZeytinForumEntryModel> entries = List.from(thread.entries);
    bool updated = false;

    for (int i = 0; i < entries.length; i++) {
      if (entries[i].id == entryId) {
        List<String> likes = List.from(entries[i].likes);
        if (!likes.contains(user.uid)) {
          likes.add(user.uid);
          entries[i] = entries[i].copyWith(likes: likes);
          updated = true;
        }
        break;
      }
    }

    if (updated) {
      return await updateThread(
        id: threadId,
        threadModel: thread.copyWith(entries: entries),
      );
    }
    return ZeytinResponse(
      isSuccess: true,
      message: "Already liked or entry not found",
    );
  }

  Future<ZeytinResponse> removeEntryLike({
    required ZeytinUserModel user,
    required String threadId,
    required String entryId,
  }) async {
    ZeytinForumThreadModel thread = await getThread(id: threadId);
    List<ZeytinForumEntryModel> entries = List.from(thread.entries);
    bool updated = false;

    for (int i = 0; i < entries.length; i++) {
      if (entries[i].id == entryId) {
        List<String> likes = List.from(entries[i].likes);
        if (likes.contains(user.uid)) {
          likes.remove(user.uid);
          entries[i] = entries[i].copyWith(likes: likes);
          updated = true;
        }
        break;
      }
    }

    if (updated) {
      return await updateThread(
        id: threadId,
        threadModel: thread.copyWith(entries: entries),
      );
    }
    return ZeytinResponse(
      isSuccess: true,
      message: "Not liked or entry not found",
    );
  }

  Future<ZeytinResponse> toggleThreadPin({
    required String threadId,
    required bool isPinned,
  }) async {
    ZeytinForumThreadModel thread = await getThread(id: threadId);
    return await updateThread(
      id: threadId,
      threadModel: thread.copyWith(isPinned: isPinned),
    );
  }

  Future<ZeytinResponse> toggleThreadLock({
    required String threadId,
    required bool isLocked,
  }) async {
    ZeytinForumThreadModel thread = await getThread(id: threadId);
    return await updateThread(
      id: threadId,
      threadModel: thread.copyWith(isLocked: isLocked),
    );
  }

  Future<ZeytinResponse> toggleThreadResolve({
    required String threadId,
    required bool isResolved,
  }) async {
    ZeytinForumThreadModel thread = await getThread(id: threadId);
    return await updateThread(
      id: threadId,
      threadModel: thread.copyWith(isResolved: isResolved),
    );
  }
}
