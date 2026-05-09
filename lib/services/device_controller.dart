import 'dart:async';

import 'package:flutter/material.dart';

import '../models/device_models.dart';
import '../theme/app_theme.dart';
import 'device_seed_data.dart';
import 'device_protocol.dart';
import 'device_status_payload_mapper.dart';
import 'motion_rule_payload_mapper.dart';
import 'quran_ble_connection.dart';
import 'upload_file_picker.dart';
import 'wifi_upload_client.dart';

/// App state coordinator for the prototype.
///
/// It owns the visible state and delegates edge concerns such as BLE transport,
/// file picking, upload IO, and firmware payload mapping to smaller services.
class DeviceController extends ChangeNotifier {
  DeviceController({
    UploadFilePicker uploadFilePicker = const UploadFilePicker(),
    MotionRulePayloadMapper rulePayloadMapper = const MotionRulePayloadMapper(),
    DeviceStatusPayloadMapper statusPayloadMapper =
        const DeviceStatusPayloadMapper(),
  }) : _uploadFilePicker = uploadFilePicker,
       _rulePayloadMapper = rulePayloadMapper,
       _statusPayloadMapper = statusPayloadMapper;

  QuranBleConnection? _bleConnection;
  DeviceProtocol? _protocol;
  StreamSubscription<DeviceEvent>? _eventSub;
  final UploadFilePicker _uploadFilePicker;
  final MotionRulePayloadMapper _rulePayloadMapper;
  final DeviceStatusPayloadMapper _statusPayloadMapper;
  final WifiUploadClient _wifiUploadClient = const WifiUploadClient();
  List<int>? _selectedUploadBytes;
  String? lastProtocolMessage;

  bool get hasLiveBleConnection => _protocol != null;

  DeviceSnapshot device = DeviceSeedData.currentDevice;

  List<DeviceSnapshot> get knownDevices => <DeviceSnapshot>[
    device,
    ...DeviceSeedData.savedDevices.where(
      (savedDevice) => savedDevice.name != device.name,
    ),
  ];

  PlaybackState playback = DeviceSeedData.playback;
  UploadJob upload = DeviceSeedData.upload;
  final List<QuranSelection> quranSelections = DeviceSeedData.quranSelections;
  List<MotionRule> rules = <MotionRule>[...DeviceSeedData.motionRules];

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

  Future<void> setRuleEnabled(String id, bool enabled) async {
    final previousRules = rules;
    final rule = rules.firstWhere((rule) => rule.id == id);
    final updatedRule = rule.copyWith(enabled: enabled);
    rules = rules.map((rule) => rule.id == id ? updatedRule : rule).toList();
    notifyListeners();

    final protocol = _protocol;
    if (protocol == null) {
      return;
    }

    try {
      final payload = _rulePayloadMapper.toPayload(updatedRule);
      final response = await protocol.upsertMotionRule(
        id: updatedRule.id,
        enabled: updatedRule.enabled,
        trigger: payload.trigger,
        action: payload.action,
      );
      if (response.ok) {
        lastProtocolMessage = 'Motion rule saved';
      } else {
        rules = previousRules;
        lastProtocolMessage =
            response.error?.message ?? 'Motion rule save failed';
      }
    } catch (error) {
      rules = previousRules;
      lastProtocolMessage = 'Motion rule save failed: $error';
    }
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

  Future<void> addSuggestedRule() async {
    final newRule = MotionRule(
      id: 'rule-${DateTime.now().millisecondsSinceEpoch}',
      name: 'Focused study',
      triggerLabel: 'Desk motion detected',
      actionLabel: 'Play Al-Kahf 1-10, repeat once',
      enabled: true,
      icon: Icons.auto_stories_outlined,
      accent: AppTheme.coral,
    );
    final previousRules = rules;
    rules = <MotionRule>[newRule, ...rules];
    notifyListeners();

    final protocol = _protocol;
    if (protocol == null) {
      return;
    }

    try {
      final payload = _rulePayloadMapper.toPayload(newRule);
      final response = await protocol.upsertMotionRule(
        id: newRule.id,
        enabled: newRule.enabled,
        trigger: payload.trigger,
        action: payload.action,
      );
      if (response.ok) {
        lastProtocolMessage = 'Motion rule created';
      } else {
        rules = previousRules;
        lastProtocolMessage =
            response.error?.message ?? 'Motion rule create failed';
      }
    } catch (error) {
      rules = previousRules;
      lastProtocolMessage = 'Motion rule create failed: $error';
    }
    notifyListeners();
  }

  Future<bool> provisionWifi({
    required String ssid,
    required String password,
  }) async {
    final protocol = _protocol;
    if (ssid.trim().isEmpty) {
      lastProtocolMessage = 'Wi-Fi SSID is required';
      notifyListeners();
      return false;
    }

    if (protocol == null) {
      device = device.copyWith(wifiName: ssid.trim());
      lastProtocolMessage = 'Wi-Fi saved in mock mode';
      notifyListeners();
      return true;
    }

    try {
      final response = await protocol.provisionWifi(
        ssid: ssid.trim(),
        password: password,
      );
      if (response.ok) {
        final connected = _readBool(response.payload, 'connected', false);
        device = device.copyWith(
          wifiName: _readString(response.payload, 'ssid', ssid.trim()),
        );
        lastProtocolMessage = connected
            ? 'Wi-Fi provisioned successfully'
            : 'Wi-Fi credentials sent';
        notifyListeners();
        await refreshStatus();
        return true;
      }

      lastProtocolMessage =
          response.error?.message ?? 'Wi-Fi provisioning failed';
    } catch (error) {
      lastProtocolMessage = 'Wi-Fi provisioning failed: $error';
    }
    notifyListeners();
    return false;
  }

  Future<void> startUpload() async {
    if (upload.isUploading) {
      return;
    }

    final protocol = _protocol;
    if (protocol == null) {
      _startMockUpload();
      return;
    }

    final uploadBytes = _selectedUploadBytes;
    if (uploadBytes == null || uploadBytes.isEmpty) {
      upload = upload.copyWith(transferNote: 'Choose an MP3 first');
      lastProtocolMessage = upload.transferNote;
      notifyListeners();
      return;
    }

    upload = upload.copyWith(
      progress: 0.02,
      isUploading: true,
      transferNote: 'Requesting upload session over BLE',
    );
    notifyListeners();

    try {
      final prepare = await protocol.prepareUpload(
        fileName: upload.fileName,
        sizeBytes: uploadBytes.length,
        mimeType: 'audio/mpeg',
      );

      if (!prepare.ok) {
        upload = upload.copyWith(
          isUploading: false,
          transferNote: prepare.error?.message ?? 'Upload prepare failed',
        );
        lastProtocolMessage = upload.transferNote;
        notifyListeners();
        return;
      }

      final url = _readString(prepare.payload, 'url', null);
      final method = _readString(prepare.payload, 'method', 'PUT') ?? 'PUT';
      if (url == null) {
        upload = upload.copyWith(
          isUploading: false,
          transferNote: 'Upload prepare response did not include a URL',
        );
        lastProtocolMessage = upload.transferNote;
        notifyListeners();
        return;
      }

      upload = upload.copyWith(
        progress: 0.08,
        transferNote: 'Uploading over Wi-Fi',
      );
      notifyListeners();

      await _wifiUploadClient.uploadBytes(
        uri: Uri.parse(url),
        method: method,
        bytes: uploadBytes,
        mimeType: 'audio/mpeg',
        onProgress: (progress) {
          upload = upload.copyWith(
            progress: 0.08 + (progress * 0.9),
            transferNote:
                'Sending over local Wi-Fi ${(progress * 100).round()}%',
          );
          notifyListeners();
        },
      );

      upload = upload.copyWith(
        progress: 1,
        isUploading: false,
        transferNote: 'Upload complete and stored on speaker',
      );
      lastProtocolMessage = 'MP3 uploaded to speaker';
    } catch (error) {
      upload = upload.copyWith(
        isUploading: false,
        transferNote: 'Upload failed: $error',
      );
      lastProtocolMessage = upload.transferNote;
    }
    notifyListeners();
  }

  Future<void> pickUploadFile() async {
    if (upload.isUploading) {
      return;
    }

    final file = await _uploadFilePicker.pickMp3();
    if (file == null) {
      lastProtocolMessage = 'MP3 selection cancelled';
      notifyListeners();
      return;
    }

    if (file.bytes.isEmpty) {
      upload = upload.copyWith(transferNote: 'Selected MP3 could not be read');
      lastProtocolMessage = upload.transferNote;
      notifyListeners();
      return;
    }

    _selectedUploadBytes = file.bytes;
    upload = upload.copyWith(
      fileName: file.name,
      sizeBytes: file.sizeBytes,
      progress: 0,
      isUploading: false,
      transferNote:
          'Ready to upload ${(file.sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
    );
    lastProtocolMessage = 'MP3 selected';
    notifyListeners();
  }

  void _startMockUpload() {
    upload = upload.copyWith(
      progress: 0.02,
      isUploading: true,
      transferNote: 'Preparing mock upload session',
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
    final update = _statusPayloadMapper.apply(
      payload: payload,
      currentDevice: device,
      currentPlayback: playback,
    );
    device = update.device;
    playback = update.playback;
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
