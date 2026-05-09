import 'dart:async';

import 'package:flutter/material.dart';

import '../models/device_models.dart';
import '../theme/app_theme.dart';
import 'device_protocol.dart';
import 'quran_ble_connection.dart';

class MockDeviceController extends ChangeNotifier {
  QuranBleConnection? _bleConnection;
  DeviceProtocol? _protocol;
  StreamSubscription<DeviceEvent>? _eventSub;
  String? lastProtocolMessage;

  bool get hasLiveBleConnection => _protocol != null;

  DeviceSnapshot device = const DeviceSnapshot(
    name: 'Qari Speaker 01',
    status: DeviceLinkStatus.connected,
    batteryPercent: 84,
    storageUsedPercent: 62,
    wifiName: 'Home Wi-Fi',
    signalStrength: -48,
    firmwareVersion: '0.2.0-dev',
  );

  List<DeviceSnapshot> get knownDevices => <DeviceSnapshot>[
    device,
    ..._savedDevices.where((savedDevice) => savedDevice.name != device.name),
  ];

  static const List<DeviceSnapshot> _savedDevices = <DeviceSnapshot>[
    DeviceSnapshot(
      name: 'Bedroom Speaker',
      status: DeviceLinkStatus.disconnected,
      batteryPercent: 61,
      storageUsedPercent: 48,
      wifiName: 'Home Wi-Fi',
      signalStrength: -72,
      firmwareVersion: '0.1.8',
    ),
    DeviceSnapshot(
      name: 'Workshop Prototype',
      status: DeviceLinkStatus.disconnected,
      batteryPercent: 24,
      storageUsedPercent: 71,
      wifiName: 'Not configured',
      signalStrength: -89,
      firmwareVersion: '0.2.0-dev',
    ),
  ];

  PlaybackState playback = const PlaybackState(
    title: 'Surah Al-Mulk',
    subtitle: 'Ayah 1-10 - Repeat 3x',
    reciter: 'Mishary Rashid Alafasy',
    mode: PlaybackMode.quranRange,
    isPlaying: true,
    volume: 0.72,
    progress: 0.38,
    repeatCount: 3,
  );

  UploadJob upload = const UploadJob(
    fileName: 'test_recitation.mp3',
    progress: 0,
    isUploading: false,
    transferNote: 'Ready to send over Wi-Fi',
  );

  final List<QuranSelection> quranSelections = const <QuranSelection>[
    QuranSelection(
      surahNumber: 1,
      surahName: 'Al-Fatihah',
      translation: 'The Opening',
      fromAyah: 1,
      toAyah: 7,
      repeatCount: 5,
    ),
    QuranSelection(
      surahNumber: 18,
      surahName: 'Al-Kahf',
      translation: 'The Cave',
      fromAyah: 1,
      toAyah: 10,
      repeatCount: 1,
    ),
    QuranSelection(
      surahNumber: 36,
      surahName: 'Ya-Sin',
      translation: 'Ya-Sin',
      fromAyah: 1,
      toAyah: 12,
      repeatCount: 2,
    ),
    QuranSelection(
      surahNumber: 67,
      surahName: 'Al-Mulk',
      translation: 'The Sovereignty',
      fromAyah: 1,
      toAyah: 10,
      repeatCount: 3,
    ),
    QuranSelection(
      surahNumber: 112,
      surahName: 'Al-Ikhlas',
      translation: 'Sincerity',
      fromAyah: 1,
      toAyah: 4,
      repeatCount: 10,
    ),
  ];

  List<MotionRule> rules = <MotionRule>[
    const MotionRule(
      id: 'entry',
      name: 'Entry remembrance',
      triggerLabel: 'Motion near hallway',
      actionLabel: 'Play Al-Fatihah 1-7, repeat 3x',
      enabled: true,
      icon: Icons.door_front_door_outlined,
      accent: AppTheme.emerald,
    ),
    const MotionRule(
      id: 'morning',
      name: 'Morning kitchen',
      triggerLabel: 'First motion after 6:00 AM',
      actionLabel: 'Play Al-Mulk 1-10',
      enabled: true,
      icon: Icons.wb_sunny_outlined,
      accent: AppTheme.gold,
    ),
    const MotionRule(
      id: 'night',
      name: 'Quiet night mode',
      triggerLabel: 'Motion after 10:30 PM',
      actionLabel: 'Play Al-Ikhlas at 35% volume',
      enabled: false,
      icon: Icons.nightlight_outlined,
      accent: AppTheme.teal,
    ),
  ];

  Timer? _uploadTimer;

  Future<void> attachBleConnection(
    QuranBleConnection connection, {
    required String deviceName,
    required int rssi,
  }) async {
    await _eventSub?.cancel();
    if (_bleConnection != null && _bleConnection != connection) {
      await _bleConnection!.disconnect();
    }

    _bleConnection = connection;
    _protocol = DeviceProtocol(connection);
    _eventSub = connection.events.listen(_handleDeviceEvent);
    device = device.copyWith(
      name: deviceName,
      status: DeviceLinkStatus.connected,
      signalStrength: rssi,
    );
    lastProtocolMessage = 'Connected to Quran Speaker BLE service';
    notifyListeners();

    await refreshStatus();
  }

  Future<void> disconnectLiveDevice() async {
    await _eventSub?.cancel();
    _eventSub = null;
    await _bleConnection?.disconnect();
    _bleConnection = null;
    _protocol = null;
    device = device.copyWith(status: DeviceLinkStatus.disconnected);
    lastProtocolMessage = 'BLE device disconnected';
    notifyListeners();
  }

  Future<void> refreshStatus() async {
    final protocol = _protocol;
    if (protocol == null) {
      return;
    }

    try {
      final response = await protocol.requestStatus();
      if (response.ok) {
        _applyStatusPayload(response.payload);
        lastProtocolMessage = 'Device status updated';
      } else {
        lastProtocolMessage =
            response.error?.message ?? 'Device rejected status request';
      }
    } catch (error) {
      lastProtocolMessage = 'Status request failed: $error';
    }
    notifyListeners();
  }

  Future<void> togglePlayback() async {
    final protocol = _protocol;
    final nextPlaying = !playback.isPlaying;
    playback = playback.copyWith(isPlaying: !playback.isPlaying);
    notifyListeners();

    if (protocol == null) {
      return;
    }

    try {
      final response = nextPlaying
          ? await protocol.resume()
          : await protocol.pause();
      if (response.ok) {
        _applyStatusPayload(response.payload);
        lastProtocolMessage = nextPlaying ? 'Resume sent' : 'Pause sent';
      } else {
        playback = playback.copyWith(isPlaying: !nextPlaying);
        lastProtocolMessage =
            response.error?.message ?? 'Playback command failed';
      }
    } catch (error) {
      playback = playback.copyWith(isPlaying: !nextPlaying);
      lastProtocolMessage = 'Playback command failed: $error';
    }
    notifyListeners();
  }

  void previewVolume(double value) {
    playback = playback.copyWith(volume: value);
    notifyListeners();
  }

  Future<void> setVolume(double value) async {
    playback = playback.copyWith(volume: value);
    notifyListeners();

    final protocol = _protocol;
    if (protocol == null) {
      return;
    }

    try {
      final response = await protocol.setVolume(value);
      if (response.ok) {
        _applyStatusPayload(response.payload);
        lastProtocolMessage = 'Volume set to ${(value * 100).round()}%';
      } else {
        lastProtocolMessage =
            response.error?.message ?? 'Volume command failed';
      }
    } catch (error) {
      lastProtocolMessage = 'Volume command failed: $error';
    }
    notifyListeners();
  }

  Future<void> playSelection(QuranSelection selection) async {
    final previousPlayback = playback;
    playback = playback.copyWith(
      title: 'Surah ${selection.surahName}',
      subtitle:
          'Ayah ${selection.fromAyah}-${selection.toAyah} - Repeat ${selection.repeatCount}x',
      mode: PlaybackMode.quranRange,
      isPlaying: true,
      progress: 0.04,
      repeatCount: selection.repeatCount,
    );
    notifyListeners();

    final protocol = _protocol;
    if (protocol == null) {
      return;
    }

    try {
      final response = await protocol.playRange(
        surah: selection.surahNumber,
        fromAyah: selection.fromAyah,
        toAyah: selection.toAyah,
        repeatCount: selection.repeatCount,
        reciter: playback.reciter,
        volume: playback.volume,
      );
      if (response.ok) {
        _applyStatusPayload(response.payload);
        lastProtocolMessage = 'Play range sent';
      } else {
        playback = previousPlayback;
        lastProtocolMessage = response.error?.message ?? 'Play range failed';
      }
    } catch (error) {
      playback = previousPlayback;
      lastProtocolMessage = 'Play range failed: $error';
    }
    notifyListeners();
  }

  Future<void> nextTrack() async {
    final protocol = _protocol;
    if (protocol == null) {
      playback = playback.copyWith(progress: 0);
      notifyListeners();
      return;
    }

    try {
      final response = await protocol.next();
      if (response.ok) {
        _applyStatusPayload(response.payload);
        lastProtocolMessage = 'Next sent';
      } else {
        lastProtocolMessage = response.error?.message ?? 'Next command failed';
      }
    } catch (error) {
      lastProtocolMessage = 'Next command failed: $error';
    }
    notifyListeners();
  }

  Future<void> previousTrack() async {
    final protocol = _protocol;
    if (protocol == null) {
      playback = playback.copyWith(progress: 0);
      notifyListeners();
      return;
    }

    try {
      final response = await protocol.previous();
      if (response.ok) {
        _applyStatusPayload(response.payload);
        lastProtocolMessage = 'Previous sent';
      } else {
        lastProtocolMessage =
            response.error?.message ?? 'Previous command failed';
      }
    } catch (error) {
      lastProtocolMessage = 'Previous command failed: $error';
    }
    notifyListeners();
  }

  void toggleRule(String id) {
    rules = rules
        .map(
          (rule) =>
              rule.id == id ? rule.copyWith(enabled: !rule.enabled) : rule,
        )
        .toList();
    notifyListeners();
  }

  void setRuleEnabled(String id, bool enabled) {
    rules = rules
        .map((rule) => rule.id == id ? rule.copyWith(enabled: enabled) : rule)
        .toList();
    notifyListeners();
  }

  void connectDevice(DeviceSnapshot target) {
    device = target.copyWith(status: DeviceLinkStatus.connecting);
    notifyListeners();
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      device = target.copyWith(status: DeviceLinkStatus.connected);
      notifyListeners();
    });
  }

  void addSuggestedRule() {
    final newRule = MotionRule(
      id: 'rule-${DateTime.now().millisecondsSinceEpoch}',
      name: 'Focused study',
      triggerLabel: 'Desk motion detected',
      actionLabel: 'Play Al-Kahf 1-10, repeat once',
      enabled: true,
      icon: Icons.auto_stories_outlined,
      accent: AppTheme.coral,
    );
    rules = <MotionRule>[newRule, ...rules];
    notifyListeners();
  }

  void startUpload() {
    if (upload.isUploading) {
      return;
    }

    upload = upload.copyWith(
      progress: 0.02,
      isUploading: true,
      transferNote: 'Preparing device upload session',
    );
    notifyListeners();

    _uploadTimer?.cancel();
    _uploadTimer = Timer.periodic(const Duration(milliseconds: 420), (timer) {
      final next = (upload.progress + 0.08).clamp(0, 1).toDouble();
      upload = upload.copyWith(
        progress: next,
        isUploading: next < 1,
        transferNote: next >= 1
            ? 'Upload complete and ready to test'
            : 'Sending over local Wi-Fi ${(next * 100).round()}%',
      );
      notifyListeners();
      if (next >= 1) {
        timer.cancel();
      }
    });
  }

  void simulateReconnect() {
    device = device.copyWith(status: DeviceLinkStatus.connecting);
    notifyListeners();
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      device = device.copyWith(status: DeviceLinkStatus.connected);
      notifyListeners();
    });
  }

  void _handleDeviceEvent(DeviceEvent event) {
    if (event.type == DeviceEventType.statusChanged.wireName ||
        event.type == DeviceEventType.playbackChanged.wireName) {
      _applyStatusPayload(event.payload);
      lastProtocolMessage = 'Device event: ${event.type}';
      notifyListeners();
      return;
    }

    lastProtocolMessage = 'Device event: ${event.type}';
    notifyListeners();
  }

  void _applyStatusPayload(Map<String, Object?> payload) {
    device = device.copyWith(
      batteryPercent: _readInt(
        payload,
        'batteryPercent',
        device.batteryPercent,
      ),
      storageUsedPercent: _readInt(
        payload,
        'storageUsedPercent',
        device.storageUsedPercent,
      ),
      wifiName: _readString(payload, 'wifiName', device.wifiName),
      signalStrength: _readInt(payload, 'rssi', device.signalStrength),
      firmwareVersion: _readString(
        payload,
        'firmwareVersion',
        device.firmwareVersion,
      ),
      status: DeviceLinkStatus.connected,
    );

    final currentTitle = _readString(payload, 'currentTitle', playback.title);
    final currentRange = _readString(payload, 'currentRange', null);
    final repeatCount = _readInt(payload, 'repeatCount', playback.repeatCount);
    final isPlaying = _readBool(payload, 'isPlaying', playback.isPlaying);
    final volume = _readDouble(payload, 'volume', playback.volume);
    final progress = _readDouble(payload, 'progress', playback.progress);

    playback = playback.copyWith(
      title: currentTitle,
      subtitle: currentRange == null
          ? playback.subtitle
          : '$currentRange - Repeat ${repeatCount}x',
      isPlaying: isPlaying,
      volume: volume.clamp(0, 1).toDouble(),
      progress: progress.clamp(0, 1).toDouble(),
      repeatCount: repeatCount,
    );
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

  @override
  void dispose() {
    _uploadTimer?.cancel();
    _eventSub?.cancel();
    unawaited(_bleConnection?.disconnect() ?? Future<void>.value());
    super.dispose();
  }
}
