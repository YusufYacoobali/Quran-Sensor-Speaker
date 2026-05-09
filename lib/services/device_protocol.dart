import 'dart:convert';

class QuranSpeakerBleUuids {
  const QuranSpeakerBleUuids._();

  static const String service = '8f7a1000-4d3f-4a9f-9f2a-91e3b7c5a001';
  static const String commandRx = '8f7a1001-4d3f-4a9f-9f2a-91e3b7c5a001';
  static const String eventTx = '8f7a1002-4d3f-4a9f-9f2a-91e3b7c5a001';
}

enum DeviceCommandType {
  statusGet('status.get'),
  playbackPlayRange('playback.playRange'),
  playbackPlayUpload('playback.playUpload'),
  playbackPause('playback.pause'),
  playbackResume('playback.resume'),
  playbackNext('playback.next'),
  playbackPrevious('playback.previous'),
  playbackSetVolume('playback.setVolume'),
  motionRuleUpsert('motionRule.upsert'),
  motionRuleDelete('motionRule.delete'),
  wifiProvision('wifi.provision'),
  uploadPrepare('upload.prepare');

  const DeviceCommandType(this.wireName);

  final String wireName;
}

enum DeviceEventType {
  statusChanged('status.changed'),
  playbackChanged('playback.changed'),
  motionDetected('motion.detected'),
  uploadProgress('upload.progress'),
  errorRaised('error.raised');

  const DeviceEventType(this.wireName);

  final String wireName;
}

enum DeviceMessageKind {
  command('command'),
  response('response'),
  event('event');

  const DeviceMessageKind(this.wireName);

  final String wireName;
}

class DeviceProtocolException implements Exception {
  const DeviceProtocolException(this.message);

  final String message;

  @override
  String toString() => 'DeviceProtocolException: $message';
}

class DeviceCommand {
  const DeviceCommand({
    required this.id,
    required this.type,
    this.payload = const <String, Object?>{},
  });

  final String id;
  final DeviceCommandType type;
  final Map<String, Object?> payload;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'v': DeviceProtocolCodec.version,
      'kind': DeviceMessageKind.command.wireName,
      'id': id,
      'type': type.wireName,
      'payload': payload,
    };
  }

  List<int> encode() => DeviceProtocolCodec.encodeJson(toJson());
}

class DeviceResponse {
  const DeviceResponse({
    required this.id,
    required this.type,
    required this.ok,
    this.payload = const <String, Object?>{},
    this.error,
  });

  final String id;
  final String type;
  final bool ok;
  final Map<String, Object?> payload;
  final DeviceProtocolError? error;

  bool get isError => !ok;
}

class DeviceEvent {
  const DeviceEvent({
    required this.id,
    required this.type,
    this.payload = const <String, Object?>{},
  });

  final String id;
  final String type;
  final Map<String, Object?> payload;
}

class DeviceProtocolError {
  const DeviceProtocolError({
    required this.code,
    required this.message,
    this.details = const <String, Object?>{},
  });

  final String code;
  final String message;
  final Map<String, Object?> details;

  factory DeviceProtocolError.fromJson(Map<String, Object?> json) {
    return DeviceProtocolError(
      code: _readString(json, 'code'),
      message: _readString(json, 'message'),
      details: _readObjectMap(json, 'details', allowMissing: true),
    );
  }
}

class DeviceProtocolCodec {
  const DeviceProtocolCodec._();

  static const int version = 1;

  static List<int> encodeJson(Map<String, Object?> json) {
    return utf8.encode(jsonEncode(json));
  }

  static DeviceIncomingMessage decodeIncoming(List<int> bytes) {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, Object?>) {
      throw const DeviceProtocolException('Message must be a JSON object');
    }

    final version = _readInt(decoded, 'v');
    if (version != DeviceProtocolCodec.version) {
      throw DeviceProtocolException('Unsupported protocol version $version');
    }

    final kind = _readString(decoded, 'kind');
    return switch (kind) {
      'response' => DeviceIncomingMessage.response(_decodeResponse(decoded)),
      'event' => DeviceIncomingMessage.event(_decodeEvent(decoded)),
      _ => throw DeviceProtocolException('Unsupported message kind $kind'),
    };
  }

  static DeviceResponse decodeResponse(List<int> bytes) {
    final message = decodeIncoming(bytes);
    if (message.response == null) {
      throw const DeviceProtocolException('Expected response message');
    }
    return message.response!;
  }

  static DeviceResponse _decodeResponse(Map<String, Object?> json) {
    final ok = _readBool(json, 'ok');
    return DeviceResponse(
      id: _readString(json, 'id'),
      type: _readString(json, 'type'),
      ok: ok,
      payload: _readObjectMap(json, 'payload', allowMissing: true),
      error: ok
          ? null
          : DeviceProtocolError.fromJson(_readObjectMap(json, 'error')),
    );
  }

  static DeviceEvent _decodeEvent(Map<String, Object?> json) {
    return DeviceEvent(
      id: _readString(json, 'id'),
      type: _readString(json, 'type'),
      payload: _readObjectMap(json, 'payload', allowMissing: true),
    );
  }
}

class DeviceIncomingMessage {
  const DeviceIncomingMessage._({this.response, this.event});

  factory DeviceIncomingMessage.response(DeviceResponse response) {
    return DeviceIncomingMessage._(response: response);
  }

  factory DeviceIncomingMessage.event(DeviceEvent event) {
    return DeviceIncomingMessage._(event: event);
  }

  final DeviceResponse? response;
  final DeviceEvent? event;
}

abstract class DeviceTransport {
  Future<void> connect(String deviceId);

  Future<DeviceResponse> send(DeviceCommand command);

  Future<void> disconnect();
}

/// Typed command facade for the BLE JSON protocol.
///
/// UI code calls these methods instead of hand-building wire payloads, which
/// keeps message ids, command names, and protocol versioning in one place.
class DeviceProtocol {
  DeviceProtocol(this.transport);

  final DeviceTransport transport;
  int _nextMessageNumber = 1;

  Future<DeviceResponse> requestStatus() {
    return transport.send(_command(DeviceCommandType.statusGet));
  }

  Future<DeviceResponse> pause() {
    return transport.send(_command(DeviceCommandType.playbackPause));
  }

  Future<DeviceResponse> resume() {
    return transport.send(_command(DeviceCommandType.playbackResume));
  }

  Future<DeviceResponse> next() {
    return transport.send(_command(DeviceCommandType.playbackNext));
  }

  Future<DeviceResponse> previous() {
    return transport.send(_command(DeviceCommandType.playbackPrevious));
  }

  Future<DeviceResponse> playUpload({
    required String fileId,
    int repeatCount = 1,
  }) {
    return transport.send(
      _command(
        DeviceCommandType.playbackPlayUpload,
        payload: <String, Object?>{
          'fileId': fileId,
          'repeatCount': repeatCount,
        },
      ),
    );
  }

  Future<DeviceResponse> playRange({
    required int surah,
    required int fromAyah,
    required int toAyah,
    required int repeatCount,
    required String reciter,
    double? volume,
  }) {
    return transport.send(
      _command(
        DeviceCommandType.playbackPlayRange,
        payload: <String, Object?>{
          'surah': surah,
          'fromAyah': fromAyah,
          'toAyah': toAyah,
          'repeatCount': repeatCount,
          'reciter': reciter,
          if (volume != null) 'volume': volume,
        },
      ),
    );
  }

  Future<DeviceResponse> setVolume(double volume) {
    return transport.send(
      _command(
        DeviceCommandType.playbackSetVolume,
        payload: <String, Object?>{'volume': volume},
      ),
    );
  }

  Future<DeviceResponse> upsertMotionRule({
    required String id,
    required bool enabled,
    required String trigger,
    required Map<String, Object?> action,
  }) {
    return transport.send(
      _command(
        DeviceCommandType.motionRuleUpsert,
        payload: <String, Object?>{
          'id': id,
          'enabled': enabled,
          'trigger': trigger,
          'action': action,
        },
      ),
    );
  }

  Future<DeviceResponse> provisionWifi({
    required String ssid,
    required String password,
  }) {
    return transport.send(
      _command(
        DeviceCommandType.wifiProvision,
        payload: <String, Object?>{'ssid': ssid, 'password': password},
      ),
    );
  }

  Future<DeviceResponse> prepareUpload({
    required String fileName,
    required int sizeBytes,
    required String mimeType,
  }) {
    return transport.send(
      _command(
        DeviceCommandType.uploadPrepare,
        payload: <String, Object?>{
          'fileName': fileName,
          'sizeBytes': sizeBytes,
          'mimeType': mimeType,
        },
      ),
    );
  }

  DeviceCommand _command(
    DeviceCommandType type, {
    Map<String, Object?> payload = const <String, Object?>{},
  }) {
    return DeviceCommand(
      id: 'app-${(_nextMessageNumber++).toString().padLeft(6, '0')}',
      type: type,
      payload: payload,
    );
  }
}

String _readString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is String && value.isNotEmpty) {
    return value;
  }
  throw DeviceProtocolException('Expected non-empty string at "$key"');
}

int _readInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is int) {
    return value;
  }
  throw DeviceProtocolException('Expected integer at "$key"');
}

bool _readBool(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is bool) {
    return value;
  }
  throw DeviceProtocolException('Expected boolean at "$key"');
}

Map<String, Object?> _readObjectMap(
  Map<String, Object?> json,
  String key, {
  bool allowMissing = false,
}) {
  final value = json[key];
  if (value == null && allowMissing) {
    return const <String, Object?>{};
  }
  if (value is Map<String, Object?>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  throw DeviceProtocolException('Expected object at "$key"');
}
