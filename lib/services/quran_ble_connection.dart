import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'device_protocol.dart';

class QuranBleConnection implements DeviceTransport {
  QuranBleConnection._({
    required this.device,
    required this.rx,
    required this.tx,
  });

  final BluetoothDevice device;
  final BluetoothCharacteristic rx;
  final BluetoothCharacteristic tx;

  final Map<String, Completer<DeviceResponse>> _pending =
      <String, Completer<DeviceResponse>>{};
  final StreamController<DeviceEvent> _events =
      StreamController<DeviceEvent>.broadcast();
  StreamSubscription<List<int>>? _notificationSub;
  bool _started = false;

  Stream<DeviceEvent> get events => _events.stream;

  static QuranBleConnection? fromServices({
    required BluetoothDevice device,
    required List<BluetoothService> services,
  }) {
    for (final service in services) {
      if (!_sameUuid(service.uuid, QuranSpeakerBleUuids.service)) {
        continue;
      }

      BluetoothCharacteristic? rx;
      BluetoothCharacteristic? tx;

      for (final characteristic in service.characteristics) {
        if (_sameUuid(characteristic.uuid, QuranSpeakerBleUuids.commandRx)) {
          rx = characteristic;
        }
        if (_sameUuid(characteristic.uuid, QuranSpeakerBleUuids.eventTx)) {
          tx = characteristic;
        }
      }

      if (rx != null && tx != null) {
        return QuranBleConnection._(device: device, rx: rx, tx: tx);
      }
    }

    return null;
  }

  Future<void> start() async {
    if (_started) {
      return;
    }

    _notificationSub = tx.onValueReceived.listen(_handleNotification);
    if (tx.properties.notify || tx.properties.indicate) {
      await tx.setNotifyValue(true);
    }
    _started = true;
  }

  @override
  Future<void> connect(String deviceId) async {
    if (!device.isConnected) {
      await device.connect(
        license: License.free,
        timeout: const Duration(seconds: 18),
        mtu: 512,
      );
    }
    await start();
  }

  @override
  Future<DeviceResponse> send(DeviceCommand command) async {
    await start();

    final completer = Completer<DeviceResponse>();
    _pending[command.id] = completer;

    try {
      await rx.write(
        command.encode(),
        withoutResponse:
            !rx.properties.write && rx.properties.writeWithoutResponse,
      );
      return await completer.future.timeout(const Duration(seconds: 5));
    } on TimeoutException {
      throw DeviceProtocolException(
        'No response for ${command.type.wireName} (${command.id})',
      );
    } finally {
      _pending.remove(command.id);
    }
  }

  @override
  Future<void> disconnect() async {
    await _notificationSub?.cancel();
    _notificationSub = null;
    for (final completer in _pending.values) {
      if (!completer.isCompleted) {
        completer.completeError(
          const DeviceProtocolException('Device disconnected'),
        );
      }
    }
    _pending.clear();
    await _events.close();
    if (device.isConnected) {
      await device.disconnect();
    }
  }

  void _handleNotification(List<int> bytes) {
    try {
      final message = DeviceProtocolCodec.decodeIncoming(bytes);
      final response = message.response;
      if (response != null) {
        final pending = _pending[response.id];
        if (pending != null && !pending.isCompleted) {
          pending.complete(response);
        }
        return;
      }

      final event = message.event;
      if (event != null && !_events.isClosed) {
        _events.add(event);
      }
    } catch (error, stackTrace) {
      for (final completer in _pending.values) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      }
    }
  }
}

bool _sameUuid(Guid uuid, String expected) {
  return uuid.toString().toLowerCase() == expected.toLowerCase();
}
