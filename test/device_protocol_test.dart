import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_speaker/services/device_protocol.dart';

void main() {
  test('encodes commands as versioned JSON envelopes', () {
    const command = DeviceCommand(
      id: 'app-000123',
      type: DeviceCommandType.playbackSetVolume,
      payload: <String, Object?>{'volume': 0.65},
    );

    final json = jsonDecode(utf8.decode(command.encode()));

    expect(json['v'], 1);
    expect(json['kind'], 'command');
    expect(json['id'], 'app-000123');
    expect(json['type'], 'playback.setVolume');
    expect(json['payload'], <String, Object?>{'volume': 0.65});
  });

  test('decodes successful responses', () {
    final response = DeviceProtocolCodec.decodeResponse(
      utf8.encode(
        jsonEncode(<String, Object?>{
          'v': 1,
          'kind': 'response',
          'id': 'app-000001',
          'type': 'status.get',
          'ok': true,
          'payload': <String, Object?>{
            'batteryPercent': 84,
            'storageUsedPercent': 62,
          },
        }),
      ),
    );

    expect(response.id, 'app-000001');
    expect(response.type, 'status.get');
    expect(response.ok, isTrue);
    expect(response.payload['batteryPercent'], 84);
    expect(response.error, isNull);
  });

  test('decodes error responses', () {
    final response = DeviceProtocolCodec.decodeResponse(
      utf8.encode(
        jsonEncode(<String, Object?>{
          'v': 1,
          'kind': 'response',
          'id': 'app-000002',
          'type': 'wifi.provision',
          'ok': false,
          'payload': <String, Object?>{},
          'error': <String, Object?>{
            'code': 'wifi_failed',
            'message': 'Could not join network',
          },
        }),
      ),
    );

    expect(response.isError, isTrue);
    expect(response.error?.code, 'wifi_failed');
    expect(response.error?.message, 'Could not join network');
  });

  test('decodes events separately from responses', () {
    final message = DeviceProtocolCodec.decodeIncoming(
      utf8.encode(
        jsonEncode(<String, Object?>{
          'v': 1,
          'kind': 'event',
          'id': 'evt-000001',
          'type': 'motion.detected',
          'payload': <String, Object?>{'ruleId': 'entry'},
        }),
      ),
    );

    expect(message.response, isNull);
    expect(message.event?.type, 'motion.detected');
    expect(message.event?.payload['ruleId'], 'entry');
  });

  test('high-level protocol increments command IDs', () async {
    final transport = _FakeTransport();
    final protocol = DeviceProtocol(transport);

    await protocol.requestStatus();
    await protocol.setVolume(0.4);
    await protocol.next();
    await protocol.previous();

    expect(transport.commands[0].id, 'app-000001');
    expect(transport.commands[0].type, DeviceCommandType.statusGet);
    expect(transport.commands[1].id, 'app-000002');
    expect(transport.commands[1].payload['volume'], 0.4);
    expect(transport.commands[2].id, 'app-000003');
    expect(transport.commands[2].type, DeviceCommandType.playbackNext);
    expect(transport.commands[3].id, 'app-000004');
    expect(transport.commands[3].type, DeviceCommandType.playbackPrevious);
  });
}

class _FakeTransport implements DeviceTransport {
  final List<DeviceCommand> commands = <DeviceCommand>[];

  @override
  Future<void> connect(String deviceId) async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<DeviceResponse> send(DeviceCommand command) async {
    commands.add(command);
    return DeviceResponse(
      id: command.id,
      type: command.type.wireName,
      ok: true,
    );
  }
}
