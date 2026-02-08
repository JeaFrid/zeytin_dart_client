import 'package:zeytin/src/models/response.dart';
import 'package:zeytin/src/models/product.dart';
import 'package:zeytin/src/models/user.dart';
import 'package:zeytin/src/services/client.dart';
import 'package:uuid/uuid.dart';

class ZeytinProducts {
  ZeytinClient zeytin;
  ZeytinProducts(this.zeytin);

  Future<ZeytinResponse> createProduct({
    required ZeytinProductModel productModel,
  }) async {
    String id = const Uuid().v1();
    return await zeytin.addData(
      box: "products",
      tag: id,
      value: productModel.copyWith(id: id, createdAt: DateTime.now()).toJson(),
    );
  }

  Future<ZeytinResponse> deleteProduct({required String id}) async {
    return await zeytin.deleteData(box: "products", tag: id);
  }

  Future<ZeytinResponse> updateProduct({
    required String id,
    required ZeytinProductModel productModel,
  }) async {
    return await zeytin.addData(
      box: "products",
      tag: id,
      value: productModel.copyWith(id: id).toJson(),
    );
  }

  Future<ZeytinProductModel> getProduct({required String id}) async {
    var res = await zeytin.getData(box: "products", tag: id);
    return ZeytinProductModel.fromJson(res.data ?? {});
  }

  Future<List<ZeytinProductModel>> getAllProducts() async {
    List<ZeytinProductModel> list = [];
    var res = await zeytin.getBox(box: "products");
    if (res.data != null) {
      for (var element in res.data!.keys) {
        list.add(ZeytinProductModel.fromJson(res.data![element]));
      }
    }
    return list;
  }

  Future<ZeytinResponse> addLike({
    required ZeytinUserModel user,
    required String productID,
  }) async {
    ZeytinProductModel product = await getProduct(id: productID);
    List<String> likes = List<String>.from(product.likes);
    if (!likes.contains(user.uid)) {
      likes.add(user.uid);
      return await updateProduct(
        id: productID,
        productModel: product.copyWith(likes: likes),
      );
    }
    return ZeytinResponse(isSuccess: true, message: "Already liked");
  }

  Future<ZeytinResponse> removeLike({
    required ZeytinUserModel user,
    required String productID,
  }) async {
    ZeytinProductModel product = await getProduct(id: productID);
    List<String> likes = List<String>.from(product.likes);
    if (likes.contains(user.uid)) {
      likes.remove(user.uid);
      return await updateProduct(
        id: productID,
        productModel: product.copyWith(likes: likes),
      );
    }
    return ZeytinResponse(isSuccess: true, message: "Not liked");
  }

  Future<ZeytinResponse> addView({required String productID}) async {
    ZeytinProductModel product = await getProduct(id: productID);
    return await updateProduct(
      id: productID,
      productModel: product.copyWith(viewCount: product.viewCount + 1),
    );
  }

  Future<ZeytinResponse> addComment({
    required ZeytinProductCommentModel comment,
    required String productID,
  }) async {
    ZeytinProductModel product = await getProduct(id: productID);
    List<ZeytinProductCommentModel> comments = List.from(product.comments);

    comments.add(
      comment.copyWith(
        id: const Uuid().v1(),
        productId: productID,
        createdAt: DateTime.now(),
      ),
    );

    return await updateProduct(
      id: productID,
      productModel: product.copyWith(comments: comments),
    );
  }

  Future<ZeytinResponse> deleteComment({
    required String commentID,
    required String productID,
  }) async {
    ZeytinProductModel product = await getProduct(id: productID);
    List<ZeytinProductCommentModel> comments = List.from(product.comments);

    comments.removeWhere((element) => element.id == commentID);

    return await updateProduct(
      id: productID,
      productModel: product.copyWith(comments: comments),
    );
  }

  Future<List<ZeytinProductCommentModel>> getComments({
    required String productID,
  }) async {
    ZeytinProductModel product = await getProduct(id: productID);
    return product.comments;
  }
}
