import 'package:zeytin/src/models/response.dart';
import 'package:zeytin/src/services/client.dart';
import 'package:zeytin/src/services/tokener.dart';

class ZeytinMail {
  final ZeytinClient zeytin;

  ZeytinMail(this.zeytin);
  Future<ZeytinResponse> sendEmail({
    required String to,
    required String subject,
    required String htmlContent,
  }) async {
    try {
      if (zeytin.token.isEmpty) {
        return ZeytinResponse(
          isSuccess: false,
          message: "Opss...",
          error: "Auth token required. Please login first.",
        );
      }
      var tokener = ZeytinTokener(zeytin.password);
      var encryptedData = tokener.encryptMap({
        "to": to,
        "subject": subject,
        "html": htmlContent,
      });
      final response = await zeytin.postRaw("/mail/send", {
        "token": zeytin.token,
        "data": encryptedData,
      });
      return response;
    } catch (e) {
      return ZeytinResponse(
        isSuccess: false,
        message: "Email error",
        error: e.toString(),
      );
    }
  }
}
