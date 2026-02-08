import 'package:zeytin/src/models/user.dart';

enum ZeytinCallStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  disconnectedReason,
}

class ZeytinCallConfig {
  final bool audioEnabled;
  final bool videoEnabled;
  final bool speakerEnabled;

  ZeytinCallConfig({
    this.audioEnabled = true,
    this.videoEnabled = false,
    this.speakerEnabled = true,
  });
}

class ZeytinCallParticipant {
  final ZeytinUserModel user;
  final bool isTalking;
  final bool isVideoEnabled;
  final bool isAudioEnabled;
  final bool isLocal;
  final dynamic rawParticipant;

  ZeytinCallParticipant({
    required this.user,
    required this.isTalking,
    required this.isVideoEnabled,
    required this.isAudioEnabled,
    required this.isLocal,
    this.rawParticipant,
  });
}
