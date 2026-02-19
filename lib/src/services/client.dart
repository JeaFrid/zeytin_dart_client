import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:zeytin/src/models/response.dart';
import 'package:zeytin/src/services/tokener.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const bool isRelease = bool.fromEnvironment('dart.vm.product');
const bool isDebug = !isRelease;

class ZeytinClient {
  String _host = "";
  String _email = "";
  String _password = "";
  String _token = "";
  String _truckID = "";
  String get host => _host;
  String get email => _email;
  String get token => _token;
  String get truck => _truckID;
  late Dio _dioInstance;
  bool _isInitialized = false;

  Dio get _dio {
    if (!_isInitialized) {
      _dioInstance = Dio(
        BaseOptions(
          baseUrl: _host,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );
      _isInitialized = true;
    }
    return _dioInstance;
  }

  Future<String?> _getHandshakeKey() async {
    try {
      Response response = await _dio.post("/token/handshake");
      if (response.data["isSuccess"] == true) {
        return response.data["tempKey"];
      } else {
        ZeytinPrint.errorPrint(response.statusCode.toString());
        ZeytinPrint.errorPrint(response.data.toString());
      }
    } catch (e) {
      ZeytinPrint.errorPrint("Handshake failed: $e");
    }
    return null;
  }

  String _prepareSecurePayload(String key, String email, String password) {
    final String plainData = "$email|$password";
    return ZeytinTokener(key).encryptString(plainData);
  }

  Future<void> init({
    required String host,
    required String email,
    required String password,
  }) async {
    _host = host;
    _email = email;
    _password = password;
    _dio.options.baseUrl = host;
    var l = await _login(email: email, password: password);
    if (l.isSuccess) {
      _truckID = l.data?["id"] ?? "";
      ZeytinPrint.successPrint("Hello developer! Connected to Zeytin.");
      Timer.periodic(const Duration(seconds: 35), (timer) async {
        await getToken();
      });
    } else {
      if (l.message == "Account not found" ||
          l.error?.contains("Account not found") == true) {
        ZeytinPrint.warningPrint("Account not found. Creating a new truck...");
        var c = await createAccount(email: email, password: password);

        if (c.isSuccess) {
          await _login(email: email, password: password);
          _truckID = c.data?["id"] ?? "";
          ZeytinPrint.successPrint("New truck created and connected.");

          Timer.periodic(const Duration(seconds: 35), (timer) async {
            await getToken();
          });
        } else {
          ZeytinPrint.errorPrint(
            "Truck creation failed: ${c.error ?? c.message}",
          );
        }
      } else {
        ZeytinPrint.errorPrint("Init Error: ${l.message} - ${l.error ?? ''}");
      }
    }
  }

  Future<ZeytinResponse> createAccount({
    required String email,
    required String password,
  }) async {
    try {
      String? tempKey = await _getHandshakeKey();
      if (tempKey == null) throw Exception("Could not get handshake key");
      String secureData = _prepareSecurePayload(tempKey, email, password);
      Response response = await _dio.post(
        "/truck/create",
        data: {"data": secureData},
      );

      return ZeytinResponse.fromMap(response.data);
    } on DioException catch (e) {
      return ZeytinResponse(
        isSuccess: false,
        message: "Opss...",
        error: e.message,
      );
    }
  }

  Future<ZeytinResponse> _login({
    required String email,
    required String password,
  }) async {
    try {
      String? tempKey = await _getHandshakeKey();
      if (tempKey == null) {
        return ZeytinResponse(
          isSuccess: false,
          message: "Handshake error",
          error: "Connection refused",
        );
      }

      String secureData = _prepareSecurePayload(tempKey, email, password);
      Response response = await _dio.post(
        "/truck/id",
        data: {"data": secureData},
      );

      var responseData = response.data;
      ZeytinResponse zResponse = ZeytinResponse.fromMap(responseData);

      if (zResponse.isSuccess) {
        _email = email;
        _password = password;
        await getToken();
      }
      return zResponse;
    } on DioException catch (e) {
      return ZeytinResponse(
        isSuccess: false,
        message: "Login failed",
        error: e.response?.data?["message"] ?? e.message,
      );
    }
  }

  String getFileUrl({required String fileId}) {
    final String effectiveTruckId = _truckID;
    final String baseUrl = _dio.options.baseUrl;
    final String normalizedBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    return "$normalizedBaseUrl/$effectiveTruckId/$fileId";
  }

  Future<String?> getToken() async {
    try {
      String? tempKey = await _getHandshakeKey();
      if (tempKey == null) return null;

      String secureData = _prepareSecurePayload(tempKey, _email, _password);

      Response response = await _dio.post(
        "/token/create",
        data: {"data": secureData},
      );

      ZeytinResponse data = ZeytinResponse.fromMap(response.data);
      if (data.isSuccess && data.data?["token"] != null) {
        _token = data.data!["token"];
        return _token;
      }
    } catch (e) {
      ZeytinPrint.errorPrint("Token renewal error: $e");
    }
    return null;
  }

  Future<ZeytinResponse> existsBox({required String box}) async {
    try {
      var tokener = ZeytinTokener(_password);
      var encryptedData = tokener.encryptMap({"box": box});
      Response response = await _dio.post(
        "/data/existsBox",
        data: {"token": _token, "data": encryptedData},
      );
      var responseData = response.data is String
          ? jsonDecode(response.data)
          : response.data;
      return ZeytinResponse.fromMap(responseData, password: _password);
    } on DioException catch (e) {
      return ZeytinResponse(
        isSuccess: false,
        message: "Opss...",
        error: e.message,
      );
    }
  }

  Future<ZeytinResponse> existsTag({
    required String box,
    required String tag,
  }) async {
    try {
      var tokener = ZeytinTokener(_password);
      var encryptedData = tokener.encryptMap({"box": box, "tag": tag});
      Response response = await _dio.post(
        "/data/existsTag",
        data: {"token": _token, "data": encryptedData},
      );
      var responseData = response.data is String
          ? jsonDecode(response.data)
          : response.data;
      return ZeytinResponse.fromMap(responseData, password: _password);
    } on DioException catch (e) {
      return ZeytinResponse(
        isSuccess: false,
        message: "Opss...",
        error: e.message,
      );
    }
  }

  Future<ZeytinResponse> contains({
    required String box,
    required String tag,
  }) async {
    try {
      var tokener = ZeytinTokener(_password);
      var encryptedData = tokener.encryptMap({"box": box, "tag": tag});
      Response response = await _dio.post(
        "/data/contains",
        data: {"token": _token, "data": encryptedData},
      );
      var responseData = response.data is String
          ? jsonDecode(response.data)
          : response.data;
      return ZeytinResponse.fromMap(responseData, password: _password);
    } on DioException catch (e) {
      return ZeytinResponse(
        isSuccess: false,
        message: "Opss...",
        error: e.message,
      );
    }
  }

  Future<ZeytinResponse> search({
    required String box,
    required String field,
    required String prefix,
  }) async {
    try {
      var tokener = ZeytinTokener(_password);
      var encryptedData = tokener.encryptMap({
        "box": box,
        "field": field,
        "prefix": prefix,
      });
      Response response = await _dio.post(
        "/data/search",
        data: {"token": _token, "data": encryptedData},
      );
      var responseData = response.data is String
          ? jsonDecode(response.data)
          : response.data;
      return ZeytinResponse.fromMap(responseData, password: _password);
    } on DioException catch (e) {
      return ZeytinResponse(
        isSuccess: false,
        message: "Opss...",
        error: e.message,
      );
    }
  }

  Future<ZeytinResponse> filter({
    required String box,
    required String field,
    required String value,
  }) async {
    try {
      var tokener = ZeytinTokener(_password);
      var encryptedData = tokener.encryptMap({
        "box": box,
        "field": field,
        "value": value,
      });
      Response response = await _dio.post(
        "/data/filter",
        data: {"token": _token, "data": encryptedData},
      );
      var responseData = response.data is String
          ? jsonDecode(response.data)
          : response.data;
      return ZeytinResponse.fromMap(responseData, password: _password);
    } on DioException catch (e) {
      return ZeytinResponse(
        isSuccess: false,
        message: "Opss...",
        error: e.message,
      );
    }
  }

  Future<ZeytinResponse> addData({
    required String box,
    required String tag,
    required Map<String, dynamic> value,
  }) async {
    try {
      var tokener = ZeytinTokener(_password);
      var encryptedData = tokener.encryptMap({
        "box": box,
        "tag": tag,
        "value": value,
      });
      Response response = await _dio.post(
        "/data/add",
        data: {"token": _token, "data": encryptedData},
      );
      var responseData = response.data is String
          ? jsonDecode(response.data)
          : response.data;
      return ZeytinResponse.fromMap(responseData);
    } on DioException catch (e) {
      return ZeytinResponse(
        isSuccess: false,
        message: "Opss...",
        error: e.message,
      );
    }
  }

  Future<ZeytinResponse> getData({
    required String box,
    required String tag,
  }) async {
    try {
      var tokener = ZeytinTokener(_password);
      var encryptedData = tokener.encryptMap({"box": box, "tag": tag});
      Response response = await _dio.post(
        "/data/get",
        data: {"token": _token, "data": encryptedData},
      );
      var responseData = response.data is String
          ? jsonDecode(response.data)
          : response.data;
      var zResponse = ZeytinResponse.fromMap(responseData, password: _password);
      if (zResponse.isSuccess && zResponse.data != null) {
        return ZeytinResponse(
          isSuccess: true,
          message: "Oki doki!",
          data: zResponse.data,
        );
      }
      return zResponse;
    } on DioException catch (e) {
      return ZeytinResponse(
        isSuccess: false,
        message: "Opss...",
        error: e.message,
      );
    }
  }

  Future<ZeytinResponse> deleteData({
    required String box,
    required String tag,
  }) async {
    try {
      var tokener = ZeytinTokener(_password);
      var encryptedData = tokener.encryptMap({"box": box, "tag": tag});
      Response response = await _dio.post(
        "/data/delete",
        data: {"token": _token, "data": encryptedData},
      );
      var responseData = response.data is String
          ? jsonDecode(response.data)
          : response.data;
      return ZeytinResponse.fromMap(responseData);
    } on DioException catch (e) {
      return ZeytinResponse(
        isSuccess: false,
        message: "Opss...",
        error: e.message,
      );
    }
  }

  Future<ZeytinResponse> deleteBox({required String box}) async {
    try {
      var tokener = ZeytinTokener(_password);
      var encryptedData = tokener.encryptMap({"box": box});
      Response response = await _dio.post(
        "/data/deleteBox",
        data: {"token": _token, "data": encryptedData},
      );
      var responseData = response.data is String
          ? jsonDecode(response.data)
          : response.data;
      return ZeytinResponse.fromMap(responseData);
    } on DioException catch (e) {
      return ZeytinResponse(
        isSuccess: false,
        message: "Opss...",
        error: e.message,
      );
    }
  }

  Future<ZeytinResponse> addBatch({
    required String box,
    required Map<String, Map<String, dynamic>> entries,
  }) async {
    try {
      var tokener = ZeytinTokener(_password);
      var encryptedData = tokener.encryptMap({"box": box, "entries": entries});
      Response response = await _dio.post(
        "/data/addBatch",
        data: {"token": _token, "data": encryptedData},
      );
      var responseData = response.data is String
          ? jsonDecode(response.data)
          : response.data;
      return ZeytinResponse.fromMap(responseData);
    } on DioException catch (e) {
      return ZeytinResponse(
        isSuccess: false,
        message: "Opss...",
        error: e.message,
      );
    }
  }

  Future<ZeytinResponse> getBox({required String box}) async {
    try {
      var tokener = ZeytinTokener(_password);
      var encryptedData = tokener.encryptMap({"box": box});
      Response response = await _dio.post(
        "/data/getBox",
        data: {"token": _token, "data": encryptedData},
      );
      var responseData = response.data is String
          ? jsonDecode(response.data)
          : response.data;

      var zResponse = ZeytinResponse.fromMap(responseData, password: _password);
      if (zResponse.isSuccess && zResponse.data != null) {
        return ZeytinResponse(
          isSuccess: true,
          message: "Oki doki!",
          data: zResponse.data,
        );
      }
      return zResponse;
    } on DioException catch (e) {
      return ZeytinResponse(
        isSuccess: false,
        message: "Opss...",
        error: e.message,
      );
    }
  }

  Future<ZeytinResponse> uploadFile(
    String filePath,
    String fileName, {
    List<int>? bytes,
  }) async {
    try {
      MultipartFile multipartFile;

      if (bytes != null) {
        multipartFile = MultipartFile.fromBytes(bytes, filename: fileName);
      } else {
        multipartFile = await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        );
      }

      var formData = FormData.fromMap({"token": _token, "file": multipartFile});

      Response response = await _dio.post("/storage/upload", data: formData);
      var responseData = response.data is String
          ? jsonDecode(response.data)
          : response.data;
      return ZeytinResponse.fromMap(responseData);
    } on DioException catch (e) {
      return ZeytinResponse(
        isSuccess: false,
        message: "Opss...",
        error: e.message,
      );
    }
  }

  Future<ZeytinResponse> deleteToken({
    required String email,
    required String password,
  }) async {
    try {
      Response response = await _dio.delete(
        "/token/delete",
        data: {"email": email, "password": password},
      );
      var responseData = response.data is String
          ? jsonDecode(response.data)
          : response.data;
      return ZeytinResponse.fromMap(responseData);
    } on DioException catch (e) {
      return ZeytinResponse(
        isSuccess: false,
        message: "Opss...",
        error: e.message,
      );
    }
  }

  Stream<Map<String, dynamic>> watchBox({required String box}) async* {
    final ZeytinTokener tokener = ZeytinTokener(_password);
    int retryCount = 0;
    const int maxDelaySeconds = 60;

    while (true) {
      final String cleanHost = _host.trim().endsWith('/')
          ? _host.trim().substring(0, _host.trim().length - 1)
          : _host.trim();
      final String protocol = cleanHost.startsWith("https") ? "wss" : "ws";
      final String domain = cleanHost.replaceFirst(RegExp(r'https?://'), "");
      final String wsUrl = "$protocol://$domain/data/watch/$_token/$box";

      WebSocketChannel? channel;
      try {
        if (_token.isEmpty) {
          ZeytinPrint.errorPrint("Token is empty, stopping watchBox.");
          break;
        }

        ZeytinPrint.warningPrint(
          "Connecting to WebSocket: $wsUrl (Attempt: ${retryCount + 1})",
        );
        channel = WebSocketChannel.connect(Uri.parse(wsUrl));

        await for (final message in channel.stream) {
          retryCount = 0;

          try {
            final decoded = jsonDecode(message);
            if (decoded is Map &&
                decoded.containsKey('error') &&
                (decoded['error'].toString().contains("Unauthorized") ||
                    decoded['error'].toString().contains("Invalid token"))) {
              ZeytinPrint.errorPrint(
                "Critical Auth Error in Stream: ${decoded['error']}",
              );
              channel.sink.close();
              return;
            }

            if (decoded["data"] != null) {
              decoded["data"] = tokener.decryptMap(decoded["data"]);
            }
            if (decoded["entries"] != null) {
              decoded["entries"] = tokener.decryptMap(decoded["entries"]);
            }
            yield decoded as Map<String, dynamic>;
          } catch (e) {
            ZeytinPrint.errorPrint("Data parse error: $e");
          }
        }
        ZeytinPrint.warningPrint("WebSocket closed by server.");
      } catch (e) {
        ZeytinPrint.errorPrint("WebSocket connection error: $e.");
      } finally {
        await channel?.sink.close();
      }
      retryCount++;
      int delaySeconds = (retryCount * 3).clamp(3, maxDelaySeconds);

      ZeytinPrint.warningPrint("Reconnecting in $delaySeconds seconds...");
      await Future.delayed(Duration(seconds: delaySeconds));
    }
  }

  Future<ZeytinResponse> joinLiveCall({
    required String roomName,
    required String userUID,
  }) async {
    try {
      if (_token.isEmpty) {
        return ZeytinResponse(
          isSuccess: false,
          message: "Auth token required.",
        );
      }

      var tokener = ZeytinTokener(_password);
      var encryptedData = tokener.encryptMap({
        "roomName": roomName,
        "uid": userUID,
      });

      Response response = await _dio.post(
        "/call/join",
        data: {"token": _token, "data": encryptedData},
      );

      var responseData = response.data is String
          ? jsonDecode(response.data)
          : response.data;

      var zResponse = ZeytinResponse.fromMap(responseData, password: _password);

      if (zResponse.isSuccess && zResponse.data != null) {
        return ZeytinResponse(
          isSuccess: true,
          message: "Ready",
          data: zResponse.data,
        );
      }
      return zResponse;
    } on DioException catch (e) {
      return ZeytinResponse(
        isSuccess: false,
        message: "Network Error",
        error: e.message,
      );
    } catch (e) {
      return ZeytinResponse(
        isSuccess: false,
        message: "Internal Error",
        error: e.toString(),
      );
    }
  }

  Stream<bool> watchLiveCall({required String roomName}) async* {
    String cleanHost = _host.trim();
    if (cleanHost.endsWith('/')) {
      cleanHost = cleanHost.substring(0, cleanHost.length - 1);
    }
    String protocol = cleanHost.startsWith("https") ? "wss" : "ws";
    String domain = cleanHost.replaceFirst(RegExp(r'https?://'), "");
    var tokener = ZeytinTokener(_password);
    var encryptedData = tokener.encryptMap({"roomName": roomName});
    var encodedData = Uri.encodeComponent(encryptedData);

    int retryCount = 0;
    while (true) {
      var wsUrl = "$protocol://$domain/call/stream/$_token?data=$encodedData";

      WebSocketChannel? channel;
      try {
        if (_token.isEmpty) break;
        channel = WebSocketChannel.connect(Uri.parse(wsUrl));
        await for (var message in channel.stream) {
          retryCount = 0;
          try {
            var decoded = jsonDecode(message);
            if (decoded is Map && decoded.containsKey("isActive")) {
              yield decoded["isActive"] as bool;
            } else {
              yield false;
            }
          } catch (e) {
            yield false;
          }
        }
        ZeytinPrint.warningPrint("LiveCall Stream closed.");
      } catch (e) {
        ZeytinPrint.errorPrint("Live call socket error: $e");
      } finally {
        await channel?.sink.close();
      }
      retryCount++;
      int delaySeconds = (retryCount * 3).clamp(3, 60);
      await Future.delayed(Duration(seconds: delaySeconds));
    }
  }

  Future<ZeytinResponse> checkLiveCall({required String roomName}) async {
    try {
      if (_token.isEmpty) {
        return ZeytinResponse(
          isSuccess: false,
          message: "Auth token required.",
        );
      }

      var tokener = ZeytinTokener(_password);
      var encryptedData = tokener.encryptMap({"roomName": roomName});

      Response response = await _dio.post(
        "/call/check",
        data: {"token": _token, "data": encryptedData},
      );

      var responseData = response.data is String
          ? jsonDecode(response.data)
          : response.data;

      var zResponse = ZeytinResponse.fromMap(responseData, password: _password);
      return zResponse;
    } catch (e) {
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }
}
