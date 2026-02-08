import 'package:zeytin/src/services/client.dart';
import 'package:zeytin/src/services/tokener.dart';

class ZeytinResponse {
  final bool isSuccess;
  final String message;
  final String? error;
  final Map<String, dynamic>? data;

  ZeytinResponse({
    required this.isSuccess,
    required this.message,
    this.error,
    this.data,
  });

  factory ZeytinResponse.fromMap(Map<String, dynamic> map, {String? password}) {
    var rawData = map['data'];
    Map<String, dynamic>? processedData;

    if (rawData != null) {
      if (rawData is Map) {
        processedData = Map<String, dynamic>.from(rawData);
      } else if (rawData is String && password != null) {
        try {
          processedData = ZeytinTokener(password).decryptMap(rawData);
        } catch (e) {
          ZeytinPrint.errorPrint("decryption error: $e");
          processedData = null;
        }
      }
    }

    return ZeytinResponse(
      isSuccess: map['isSuccess'] ?? false,
      message: map['message'] ?? '',
      error: map['error']?.toString(),
      data: processedData,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "isSuccess": isSuccess,
      "message": message,
      if (error != null) "error": error,
      if (data != null) "data": data,
    };
  }
}

class ZeytinPrint {
  static void successPrint(String data) {
    if (isDebug) {
      print('\x1B[32m[✅]: $data\x1B[0m');
    }
  }

  static void errorPrint(String data) {
    if (isDebug) {
      print('\x1B[31m[❌]: $data\x1B[0m');
    }
  }

  static void warningPrint(String data) {
    if (isDebug) {
      print('\x1B[33m[❗]: $data\x1B[0m');
    }
  }
}
