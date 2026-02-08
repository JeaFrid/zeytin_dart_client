import 'package:zeytin/src/models/response.dart';
import 'package:zeytin/src/models/social.dart';
import 'package:zeytin/src/models/user.dart';
import 'package:zeytin/src/services/client.dart';
import 'package:uuid/uuid.dart';

class ZeytinSocial {
  ZeytinClient zeytin;
  ZeytinSocial(this.zeytin);
  Future<ZeytinResponse> createPost({
    required ZeytinSocialModel postModel,
  }) async {
    String id = Uuid().v1();

    return await zeytin.addData(
      box: "social",
      tag: id,
      value: postModel.copyWith(id: id).toJson(),
    );
  }

  Future<ZeytinResponse> deletePost({required String id}) async {
    return await zeytin.deleteData(box: "social", tag: id);
  }

  Future<ZeytinResponse> editPost({
    required String id,
    required ZeytinSocialModel postModel,
  }) async {
    return await zeytin.addData(
      box: "social",
      tag: id,
      value: postModel.copyWith(id: id).toJson(),
    );
  }

  Future<ZeytinResponse> addLike({
    required ZeytinUserModel user,
    required String postID,
  }) async {
    ZeytinSocialModel post = await getPost(id: postID);
    if ((post.likes ?? []).contains(user.uid)) {
      return ZeytinResponse(isSuccess: true, message: "message");
    } else {
      List<dynamic> likes = (post.likes ?? []);
      likes.add(user.uid);
      ZeytinSocialModel newPost = post.copyWith(likes: likes);
      await editPost(id: postID, postModel: newPost);
      return ZeytinResponse(isSuccess: true, message: "message");
    }
  }

  Future<ZeytinResponse> removeLike({
    required ZeytinUserModel user,
    required String postID,
  }) async {
    ZeytinSocialModel post = await getPost(id: postID);
    if ((post.likes ?? []).contains(user.uid)) {
      List<dynamic> likes = (post.likes ?? []);
      likes.remove(user.uid);
      ZeytinSocialModel newPost = post.copyWith(likes: likes);
      await editPost(id: postID, postModel: newPost);
      return ZeytinResponse(isSuccess: true, message: "message");
    } else {
      return ZeytinResponse(isSuccess: true, message: "message");
    }
  }

  Future<ZeytinResponse> addComment({
    required ZeytinSocialCommentsModel comment,
    required String postID,
  }) async {
    ZeytinSocialModel post = await getPost(id: postID);
    List<ZeytinSocialCommentsModel> comments = [];
    comments = post.comments ?? [];
    comments.add(comment.copyWith(id: Uuid().v1()));
    ZeytinSocialModel newPost = post.copyWith(comments: comments);
    await editPost(id: postID, postModel: newPost);
    return ZeytinResponse(isSuccess: true, message: "ok");
  }

  Future<ZeytinResponse> deleteComment({
    required String commentID,
    required String postID,
  }) async {
    ZeytinSocialModel post = await getPost(id: postID);
    List<ZeytinSocialCommentsModel> comments = [];
    comments = post.comments ?? [];
    comments.removeWhere((element) => element.id == commentID);
    ZeytinSocialModel newPost = post.copyWith(comments: comments);
    await editPost(id: postID, postModel: newPost);
    return ZeytinResponse(isSuccess: true, message: "ok");
  }

  Future<ZeytinResponse> addCommentLike({
    required ZeytinUserModel user,
    required String postID,
    required String commentID,
  }) async {
    ZeytinSocialModel post = await getPost(id: postID);

    List<ZeytinSocialCommentsModel> comments = post.comments ?? [];
    bool updated = false;

    for (int i = 0; i < comments.length; i++) {
      if (comments[i].id == commentID) {
        List<String> commentLikes = comments[i].likes ?? [];

        if (!commentLikes.contains(user.uid)) {
          commentLikes.add(user.uid);
          comments[i] = ZeytinSocialCommentsModel(
            user: comments[i].user,
            text: comments[i].text,
            likes: commentLikes,
            postID: comments[i].postID,
            id: comments[i].id,
            moreData: comments[i].moreData,
          );
          updated = true;
        }
        break;
      }
    }

    if (updated) {
      ZeytinSocialModel newPost = post.copyWith(comments: comments);
      await editPost(id: postID, postModel: newPost);
      return ZeytinResponse(isSuccess: true, message: "Comment liked");
    }

    return ZeytinResponse(
      isSuccess: false,
      message: "No comments found or it's already liked.",
    );
  }

  Future<ZeytinResponse> removeCommentLike({
    required ZeytinUserModel user,
    required String postID,
    required String commentID,
  }) async {
    ZeytinSocialModel post = await getPost(id: postID);

    List<ZeytinSocialCommentsModel> comments = post.comments ?? [];
    bool updated = false;

    for (int i = 0; i < comments.length; i++) {
      if (comments[i].id == commentID) {
        List<String> commentLikes = comments[i].likes ?? [];

        if (commentLikes.contains(user.uid)) {
          commentLikes.remove(user.uid);
          comments[i] = ZeytinSocialCommentsModel(
            user: comments[i].user,
            text: comments[i].text,
            likes: commentLikes,
            postID: comments[i].postID,
            id: comments[i].id,
            moreData: comments[i].moreData,
          );
          updated = true;
        }
        break;
      }
    }

    if (updated) {
      ZeytinSocialModel newPost = post.copyWith(comments: comments);
      await editPost(id: postID, postModel: newPost);
      return ZeytinResponse(isSuccess: true, message: "Comment like removed");
    }

    return ZeytinResponse(
      isSuccess: false,
      message: "No comments or likes found.",
    );
  }

  Future<List<ZeytinSocialCommentsModel>> getComments({
    required String postID,
    int? limit,
    int? offset,
  }) async {
    ZeytinSocialModel post = await getPost(id: postID);
    List<ZeytinSocialCommentsModel> allComments = post.comments ?? [];

    if (offset != null && offset >= allComments.length) {
      return [];
    }

    int startIndex = offset ?? 0;
    int endIndex = limit != null ? startIndex + limit : allComments.length;

    if (endIndex > allComments.length) {
      endIndex = allComments.length;
    }

    if (startIndex >= endIndex) {
      return [];
    }

    return allComments.sublist(startIndex, endIndex);
  }

  Future<ZeytinSocialModel> getPost({required String id}) async {
    var post = await zeytin.getData(box: "social", tag: id);

    return ZeytinSocialModel.fromJson(post.data ?? {});
  }

  Future<List<ZeytinSocialModel>> getAllPost() async {
    List<ZeytinSocialModel> list = [];
    var social = await zeytin.getBox(box: "social");
    if (social.data == null) {
      ZeytinPrint.errorPrint(social.error ?? "Error Social");
      return [];
    }
    for (var element in social.data!.keys) {
      list.add(ZeytinSocialModel.fromJson(social.data![element]));
    }

    return list;
  }
}
