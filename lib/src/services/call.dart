import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:zeytin/src/models/call.dart';
import 'package:zeytin/src/models/response.dart';
import 'package:zeytin/src/models/user.dart';
import 'package:zeytin/src/services/client.dart';

class ZeytinMediaDevice {
  final String deviceId;
  final String label;
  final String kind;

  ZeytinMediaDevice({
    required this.deviceId,
    required this.label,
    required this.kind,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ZeytinMediaDevice &&
          runtimeType == other.runtimeType &&
          deviceId == other.deviceId;

  @override
  int get hashCode => deviceId.hashCode;
}

class ZeytinCall {
  final ZeytinClient zeytin;
  Room? _room;
  EventsListener<RoomEvent>? _listener;
  bool _isIntentionalDisconnect = false;

  final StreamController<List<ZeytinCallParticipant>> _participantsController =
      StreamController<List<ZeytinCallParticipant>>.broadcast();

  final StreamController<ZeytinCallStatus> _statusController =
      StreamController<ZeytinCallStatus>.broadcast();

  Stream<List<ZeytinCallParticipant>> get onParticipantsChanged =>
      _participantsController.stream;

  Stream<ZeytinCallStatus> get onStatusChanged => _statusController.stream;

  Room? get currentRoom => _room;

  ZeytinCall(this.zeytin);

  StreamSubscription<List<ZeytinCallParticipant>> listenParticipants(
    Function(List<ZeytinCallParticipant> participants) onParticipantsChanged,
  ) {
    if (_participantsController.hasListener && _room != null) {
      _emitParticipants();
    }
    return _participantsController.stream.listen(onParticipantsChanged);
  }

  StreamSubscription<ZeytinCallStatus> listenStatus(
    Function(ZeytinCallStatus status) onStatusChanged,
  ) {
    return _statusController.stream.listen(onStatusChanged);
  }

  Future<ZeytinResponse> joinRoom({
    required String roomName,
    required ZeytinUserModel user,
    ZeytinCallConfig? config,
  }) async {
    try {
      _isIntentionalDisconnect = false;
      _statusController.add(ZeytinCallStatus.connecting);

      final credentialResponse = await zeytin.joinLiveCall(
        roomName: roomName,
        userUID: user.uid,
      );

      if (!credentialResponse.isSuccess || credentialResponse.data == null) {
        _statusController.add(ZeytinCallStatus.disconnected);
        return credentialResponse;
      }

      final String liveKitUrl = credentialResponse.data!["serverUrl"];
      final String liveKitToken = credentialResponse.data!["token"];

      await _connectToLiveKit(
        url: liveKitUrl,
        token: liveKitToken,
        config: config ?? ZeytinCallConfig(),
      );

      return ZeytinResponse(isSuccess: true, message: "Connected to room");
    } catch (e) {
      _statusController.add(ZeytinCallStatus.disconnected);
      return ZeytinResponse(isSuccess: false, message: e.toString());
    }
  }

  Future<bool> checkRoomActive(String roomName) async {
    try {
      var res = await zeytin.checkLiveCall(roomName: roomName);
      if (res.isSuccess && res.data != null) {
        return res.data!["isActive"] ?? false;
      }
      return false;
    } catch (e) {
      ZeytinPrint.errorPrint("Check room error: $e");
      return false;
    }
  }

  Future<void> _connectToLiveKit({
    required String url,
    required String token,
    required ZeytinCallConfig config,
  }) async {
    final options = RoomOptions(
      defaultCameraCaptureOptions: const CameraCaptureOptions(
        params: VideoParametersPresets.h720_169,
      ),
      defaultAudioCaptureOptions: const AudioCaptureOptions(),
      adaptiveStream: true,
      dynacast: true,
      stopLocalTrackOnUnpublish: true,
    );

    _room = Room(roomOptions: options);
    _listener = _room!.createListener();
    _setupListeners();

    try {
      await _room!.connect(url, token);

      if (config.videoEnabled) {
        await _room!.localParticipant?.setCameraEnabled(true);
      }
      if (config.audioEnabled) {
        await _room!.localParticipant?.setMicrophoneEnabled(true);
      }

      _emitParticipants();
      _statusController.add(ZeytinCallStatus.connected);
    } catch (e) {
      ZeytinPrint.errorPrint("Bağlantı hatası: $e");
      _statusController.add(ZeytinCallStatus.disconnected);
    }
  }

  void _setupListeners() {
    if (_listener == null) return;

    _listener!
      ..on<ParticipantConnectedEvent>((e) => _emitParticipants())
      ..on<ParticipantDisconnectedEvent>((e) => _emitParticipants())
      ..on<ActiveSpeakersChangedEvent>((e) => _emitParticipants())
      ..on<TrackMutedEvent>((e) => _emitParticipants())
      ..on<TrackUnmutedEvent>((e) => _emitParticipants())
      ..on<LocalTrackPublishedEvent>((e) => _emitParticipants())
      ..on<LocalTrackUnpublishedEvent>((e) => _emitParticipants())
      ..on<RoomDisconnectedEvent>((e) async {
        if (_isIntentionalDisconnect) {
          _statusController.add(ZeytinCallStatus.disconnected);
          _participantsController.add([]);
        } else {
          _statusController.add(ZeytinCallStatus.reconnecting);
          ZeytinPrint.errorPrint("Bağlantı koptu! Tekrar bağlanılıyor...");
        }
      })
      ..on<RoomReconnectingEvent>((e) {
        _statusController.add(ZeytinCallStatus.reconnecting);
      })
      ..on<RoomReconnectedEvent>((e) {
        _statusController.add(ZeytinCallStatus.connected);
        _emitParticipants();
      });
  }

  void _emitParticipants() {
    if (_room == null) return;
    try {
      List<ZeytinCallParticipant> participants = [];

      if (_room!.localParticipant != null) {
        participants.add(
          _mapToZeytinParticipant(_room!.localParticipant!, isLocal: true),
        );
      }

      for (var p in _room!.remoteParticipants.values) {
        participants.add(_mapToZeytinParticipant(p, isLocal: false));
      }

      if (!_participantsController.isClosed) {
        _participantsController.add(participants);
      }
    } catch (e) {
      ZeytinPrint.errorPrint("Emit participants error: $e");
    }
  }

  ZeytinCallParticipant _mapToZeytinParticipant(
    Participant p, {
    required bool isLocal,
  }) {
    String cleanUid = p.identity;
    if (cleanUid.contains('-')) {
      final parts = cleanUid.split('-');
      if (parts.length > 5) {
        cleanUid = parts.sublist(0, 5).join('-');
      }
    }

    final userModel = ZeytinUserModel.empty().copyWith(
      uid: cleanUid,
      username: p.name,
      displayName: p.name,
    );

    return ZeytinCallParticipant(
      user: userModel,
      isTalking: p.isSpeaking,
      isAudioEnabled: p.isMicrophoneEnabled(),
      isVideoEnabled: p.isCameraEnabled(),
      isLocal: isLocal,
      rawParticipant: p,
    );
  }

  Stream<bool> streamRoomStatus(String roomName) {
    return zeytin.watchLiveCall(roomName: roomName);
  }

  Future<void> leaveRoom() async {
    _isIntentionalDisconnect = true;
    var dirtyListener = _listener;
    _listener = null;

    if (_room != null) {
      if (dirtyListener != null) {
        try {
          await dirtyListener.dispose();
        } catch (_) {}
      }

      try {
        await _room?.disconnect();
      } catch (e) {
        ZeytinPrint.errorPrint("Room disconnect error: $e");
      }

      try {
        await _room?.dispose();
      } catch (e) {
        ZeytinPrint.errorPrint("Room dispose error: $e");
      } finally {
        _room = null;
        _isIntentionalDisconnect = false;
        if (!_statusController.isClosed) {
          _statusController.add(ZeytinCallStatus.disconnected);
        }
        if (!_participantsController.isClosed) {
          _participantsController.add([]);
        }
      }
    }
  }

  Future<List<ZeytinMediaDevice>> getVideoInputs() async {
    var devices = await Hardware.instance.enumerateDevices(type: 'videoinput');
    return devices
        .map(
          (d) => ZeytinMediaDevice(
            deviceId: d.deviceId,
            label: d.label,
            kind: d.kind,
          ),
        )
        .toList();
  }

  Future<void> selectVideoInput(ZeytinMediaDevice device) async {
    if (_room?.localParticipant != null) {
      await _room!.localParticipant!.setCameraEnabled(false);

      await _room!.localParticipant!.setCameraEnabled(
        true,
        cameraCaptureOptions: CameraCaptureOptions(
          deviceId: device.deviceId,
          params: const VideoParameters(
            dimensions: VideoDimensions(1280, 720),
            encoding: VideoEncoding(maxBitrate: 1700000, maxFramerate: 30),
          ),
        ),
      );
    }
  }

  Future<void> toggleCamera(bool enabled) async {
    if (_room?.localParticipant != null) {
      await _room!.localParticipant!.setCameraEnabled(enabled);
    }
  }

  Future<void> selectScreenSource(ZeytinMediaDevice? device) async {
    if (_room?.localParticipant == null) return;

    if (kIsWeb) {
      await _room!.localParticipant!.setScreenShareEnabled(true);
    } else {
      try {
        await _stopScreenShareInternal();

        var options = ScreenShareCaptureOptions(
          sourceId: device?.deviceId,
          captureScreenAudio: false,
        );

        var track = await LocalVideoTrack.createScreenShareTrack(options);

        await _room!.localParticipant!.publishVideoTrack(
          track,
          publishOptions: const VideoPublishOptions(
            videoEncoding: VideoEncoding(
              maxBitrate: 1500 * 1000,
              maxFramerate: 24,
            ),
          ),
        );
      } catch (e) {
        ZeytinPrint.errorPrint(e.toString());
      }
    }
  }

  Future<void> _stopScreenShareInternal() async {
    final local = _room?.localParticipant;
    if (local == null) return;

    final screenPubs = local.videoTrackPublications
        .where((pub) => pub.source == TrackSource.screenShareVideo)
        .toList();

    for (final pub in screenPubs) {
      try {
        await local.removePublishedTrack(pub.sid, notify: true);
        await pub.track?.stop();
      } catch (_) {}
    }
  }

  Future<void> toggleScreenShare(bool enabled) async {
    if (_room?.localParticipant == null) return;

    if (enabled) {
      if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
        await _room!.localParticipant!.setScreenShareEnabled(true);
      } else {
        await selectScreenSource(null);
      }
    } else {
      await _stopScreenShareInternal();
      await _room!.localParticipant!.setScreenShareEnabled(false);
    }
  }

  Future<void> toggleMicrophone(bool enabled) async {
    if (_room?.localParticipant != null) {
      await _room!.localParticipant!.setMicrophoneEnabled(enabled);
    }
  }

  Future<void> toggleIncomingAudio(bool enabled) async {
    if (_room == null) return;
    for (var p in _room!.remoteParticipants.values) {
      for (var t in p.audioTrackPublications) {
        if (t.track != null) {
          if (enabled) {
            await t.track!.start();
          } else {
            await t.track!.stop();
          }
        }
      }
    }
  }

  Future<void> toggleSpeakerphone(bool enabled) async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      await Hardware.instance.setSpeakerphoneOn(enabled);
    }
  }

  Future<List<ZeytinMediaDevice>> getAudioOutputs() async {
    var devices = await Hardware.instance.enumerateDevices(type: 'audiooutput');
    return devices
        .map(
          (d) => ZeytinMediaDevice(
            deviceId: d.deviceId,
            label: d.label,
            kind: d.kind,
          ),
        )
        .toList();
  }

  Future<void> selectAudioOutput(ZeytinMediaDevice device) async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) return;

    var devices = await Hardware.instance.enumerateDevices(type: 'audiooutput');
    try {
      var targetDevice = devices.firstWhere(
        (d) => d.deviceId == device.deviceId,
      );
      await Hardware.instance.selectAudioOutput(targetDevice);
    } catch (_) {}
  }

  Future<List<ZeytinMediaDevice>> getAudioInputs() async {
    var devices = await Hardware.instance.enumerateDevices(type: 'audioinput');
    return devices
        .map(
          (d) => ZeytinMediaDevice(
            deviceId: d.deviceId,
            label: d.label,
            kind: d.kind,
          ),
        )
        .toList();
  }

  Future<void> selectAudioInput(ZeytinMediaDevice device) async {
    var devices = await Hardware.instance.enumerateDevices(type: 'audioinput');
    try {
      var targetDevice = devices.firstWhere(
        (d) => d.deviceId == device.deviceId,
      );
      await Hardware.instance.selectAudioInput(targetDevice);
    } catch (_) {}
  }

  void dispose() {
    _participantsController.close();
    _statusController.close();
    leaveRoom();
  }
}
