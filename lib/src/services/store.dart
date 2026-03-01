import 'package:zeytin/src/models/response.dart';
import 'package:zeytin/src/models/store.dart';
import 'package:zeytin/src/services/client.dart';
import 'package:uuid/uuid.dart';

class ZeytinStore {
  ZeytinClient zeytin;
  ZeytinStore(this.zeytin);

  Future<ZeytinResponse> createStore({
    required ZeytinStoreModel storeModel,
  }) async {
    String id = const Uuid().v1();
    return await zeytin.addData(
      box: "stores",
      tag: id,
      value: storeModel.copyWith(id: id, createdAt: DateTime.now()).toJson(),
    );
  }

  Future<ZeytinResponse> deleteStore({required String id}) async {
    return await zeytin.deleteData(box: "stores", tag: id);
  }

  Future<ZeytinResponse> updateStore({
    required String id,
    required ZeytinStoreModel storeModel,
  }) async {
    return await zeytin.addData(
      box: "stores",
      tag: id,
      value: storeModel.copyWith(id: id).toJson(),
    );
  }
 
  Future<ZeytinStoreModel> getStore({required String id}) async {
    var res = await zeytin.getData(box: "stores", tag: id);
    return ZeytinStoreModel.fromJson(res.data ?? {});
  }

  Future<List<ZeytinStoreModel>> getAllStores() async {
    List<ZeytinStoreModel> list = [];
    var res = await zeytin.getBox(box: "stores");
    if (res.data != null) {
      for (var element in res.data!.keys) {
        list.add(ZeytinStoreModel.fromJson(res.data![element]));
      }
    }
    return list;
  }
}
