import '../models/device_models.dart';

class DeviceStatusUpdate {
  const DeviceStatusUpdate({required this.device, required this.playback});

  final DeviceSnapshot device;
  final PlaybackState playback;
}

class DeviceStatusPayloadMapper {
  const DeviceStatusPayloadMapper();

  DeviceStatusUpdate apply({
    required Map<String, Object?> payload,
    required DeviceSnapshot currentDevice,
    required PlaybackState currentPlayback,
  }) {
    final device = currentDevice.copyWith(
      batteryPercent: _readInt(
        payload,
        'batteryPercent',
        currentDevice.batteryPercent,
      ),
      storageUsedPercent: _readInt(
        payload,
        'storageUsedPercent',
        currentDevice.storageUsedPercent,
      ),
      wifiName: _readString(payload, 'wifiName', currentDevice.wifiName),
      signalStrength: _readInt(payload, 'rssi', currentDevice.signalStrength),
      firmwareVersion: _readString(
        payload,
        'firmwareVersion',
        currentDevice.firmwareVersion,
      ),
      status: DeviceLinkStatus.connected,
    );

    final currentTitle = _readString(
      payload,
      'currentTitle',
      currentPlayback.title,
    );
    final currentRange = _readString(payload, 'currentRange', null);
    final repeatCount = _readInt(
      payload,
      'repeatCount',
      currentPlayback.repeatCount,
    );

    final playback = currentPlayback.copyWith(
      title: currentTitle,
      subtitle: currentRange == null
          ? currentPlayback.subtitle
          : '$currentRange - Repeat ${repeatCount}x',
      isPlaying: _readBool(payload, 'isPlaying', currentPlayback.isPlaying),
      volume: _readDouble(
        payload,
        'volume',
        currentPlayback.volume,
      ).clamp(0, 1).toDouble(),
      progress: _readDouble(
        payload,
        'progress',
        currentPlayback.progress,
      ).clamp(0, 1).toDouble(),
      repeatCount: repeatCount,
    );

    return DeviceStatusUpdate(device: device, playback: playback);
  }

  String? _readString(
    Map<String, Object?> payload,
    String key,
    String? fallback,
  ) {
    final value = payload[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return fallback;
  }

  int _readInt(Map<String, Object?> payload, String key, int fallback) {
    final value = payload[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    return fallback;
  }

  double _readDouble(
    Map<String, Object?> payload,
    String key,
    double fallback,
  ) {
    final value = payload[key];
    if (value is num) {
      return value.toDouble();
    }
    return fallback;
  }

  bool _readBool(Map<String, Object?> payload, String key, bool fallback) {
    final value = payload[key];
    if (value is bool) {
      return value;
    }
    return fallback;
  }
}
