import 'package:zeytin/src/models/books.dart';
import 'package:zeytin/src/models/response.dart';
import 'package:zeytin/src/models/user.dart';
import 'package:zeytin/src/services/client.dart';
import 'package:uuid/uuid.dart';

class ZeytinLibrary {
  ZeytinClient zeytin;
  ZeytinLibrary(this.zeytin);

  Future<ZeytinResponse> createBook({
    required ZeytinBookModel bookModel,
  }) async {
    String id = const Uuid().v1();
    return await zeytin.addData(
      box: "books",
      tag: id,
      value: bookModel.copyWith(id: id).toJson(),
    );
  }

  Future<ZeytinResponse> deleteBook({required String id}) async {
    return await zeytin.deleteData(box: "books", tag: id);
  }

  Future<ZeytinResponse> editBook({
    required String id,
    required ZeytinBookModel bookModel,
  }) async {
    return await zeytin.addData(
      box: "books",
      tag: id,
      value: bookModel.copyWith(id: id).toJson(),
    );
  }

  Future<ZeytinBookModel> getBook({required String id}) async {
    var res = await zeytin.getData(box: "books", tag: id);
    return ZeytinBookModel.fromJson(res.data ?? {});
  }

  Future<ZeytinResponse> addChapter({
    required ZeytinChapterModel chapter,
  }) async {
    String id = const Uuid().v1();
    return await zeytin.addData(
      box: "chapters",
      tag: id,
      value: chapter.copyWith(id: id).toJson(),
    );
  }

  Future<ZeytinResponse> deleteChapter({required String id}) async {
    return await zeytin.deleteData(box: "chapters", tag: id);
  }

  Future<List<ZeytinChapterModel>> getBookChapters({
    required String bookID,
  }) async {
    List<ZeytinChapterModel> list = [];
    var res = await zeytin.getBox(box: "chapters");
    if (res.data != null) {
      for (var key in res.data!.keys) {
        var model = ZeytinChapterModel.fromJson(res.data![key]);
        if (model.bookId == bookID) {
          list.add(model);
        }
      }
      list.sort((a, b) => a.order.compareTo(b.order));
    }
    return list;
  }

  Future<ZeytinResponse> updateChapter({
    required String id,
    required ZeytinChapterModel chapter,
  }) async {
    return await zeytin.addData(
      box: "chapters",
      tag: id,
      value: chapter.toJson(),
    );
  }

  Future<List<ZeytinBookModel>> getAllBooks() async {
    List<ZeytinBookModel> list = [];
    var res = await zeytin.getBox(box: "books");
    if (res.data != null) {
      for (var element in res.data!.keys) {
        list.add(ZeytinBookModel.fromJson(res.data![element]));
      }
    }
    return list;
  }

  Future<ZeytinResponse> addLike({
    required ZeytinUserModel user,
    required String bookID,
  }) async {
    ZeytinBookModel book = await getBook(id: bookID);
    List<String> likes = List<String>.from(book.likes);
    if (!likes.contains(user.uid)) {
      likes.add(user.uid);
      return await editBook(
        id: bookID,
        bookModel: book.copyWith(likes: likes),
      );
    }
    return ZeytinResponse(isSuccess: true, message: "Already liked");
  }

  Future<ZeytinResponse> removeLike({
    required ZeytinUserModel user,
    required String bookID,
  }) async {
    ZeytinBookModel book = await getBook(id: bookID);
    List<String> likes = List<String>.from(book.likes);
    if (likes.contains(user.uid)) {
      likes.remove(user.uid);
      return await editBook(
        id: bookID,
        bookModel: book.copyWith(likes: likes),
      );
    }
    return ZeytinResponse(isSuccess: true, message: "Not liked");
  }

  Future<ZeytinResponse> addComment({
    required ZeytinBookCommentModel comment,
    required String bookID,
  }) async {
    ZeytinBookModel book = await getBook(id: bookID);
    var moreData = Map<String, dynamic>.from(book.moreData ?? {});
    List<dynamic> commentsRaw = moreData["comments"] ?? [];
    List<ZeytinBookCommentModel> comments = commentsRaw
        .map((e) => ZeytinBookCommentModel.fromJson(e))
        .toList();

    comments.add(comment.copyWith(id: const Uuid().v1(), bookID: bookID));
    moreData["comments"] = comments.map((e) => e.toJson()).toList();

    return await editBook(
      id: bookID,
      bookModel: book.copyWith(moreData: moreData),
    );
  }

  Future<ZeytinResponse> deleteComment({
    required String commentID,
    required String bookID,
  }) async {
    ZeytinBookModel book = await getBook(id: bookID);
    var moreData = Map<String, dynamic>.from(book.moreData ?? {});
    List<dynamic> commentsRaw = moreData["comments"] ?? [];

    List<ZeytinBookCommentModel> comments = commentsRaw
        .map((e) => ZeytinBookCommentModel.fromJson(e))
        .toList();

    comments.removeWhere((element) => element.id == commentID);
    moreData["comments"] = comments.map((e) => e.toJson()).toList();

    return await editBook(
      id: bookID,
      bookModel: book.copyWith(moreData: moreData),
    );
  }

  Future<List<ZeytinBookCommentModel>> getComments({
    required String bookID,
  }) async {
    ZeytinBookModel book = await getBook(id: bookID);
    List<dynamic> commentsRaw = book.moreData?["comments"] ?? [];
    return commentsRaw.map((e) => ZeytinBookCommentModel.fromJson(e)).toList();
  }

  Future<List<ZeytinBookModel>> searchByISBN(String isbn) async {
    var res = await zeytin.search(box: "books", field: "isbn", prefix: isbn);
    List<ZeytinBookModel> results = [];
    if (res.data != null) {
      for (var key in res.data!.keys) {
        results.add(ZeytinBookModel.fromJson(res.data![key]));
      }
    }
    return results;
  }
}
