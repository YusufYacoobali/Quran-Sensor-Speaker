import 'package:flutter_test/flutter_test.dart';
import 'package:quran_speaker/models/device_models.dart';
import 'package:quran_speaker/services/device_status_payload_mapper.dart';

void main() {
  test('maps partial status payloads without losing existing state', () {
    const mapper = DeviceStatusPayloadMapper();
    const device = DeviceSnapshot(
      name: 'Speaker',
      status: DeviceLinkStatus.disconnected,
      batteryPercent: 50,
      storageUsedPercent: 20,
      wifiName: 'Old Wi-Fi',
      signalStrength: -80,
      firmwareVersion: '0.1.0',
    );
    const playback = PlaybackState(
      title: 'Surah Al-Mulk',
      subtitle: 'Ayah 1-10 - Repeat 3x',
      reciter: 'Mishary Rashid Alafasy',
      mode: PlaybackMode.quranRange,
      isPlaying: false,
      volume: 0.5,
      progress: 0.2,
      repeatCount: 3,
    );

    final update = mapper.apply(
      payload: const <String, Object?>{
        'batteryPercent': 91,
        'isPlaying': true,
        'volume': 1.4,
        'progress': -0.2,
      },
      currentDevice: device,
      currentPlayback: playback,
    );

    expect(update.device.status, DeviceLinkStatus.connected);
    expect(update.device.batteryPercent, 91);
    expect(update.device.wifiName, 'Old Wi-Fi');
    expect(update.playback.isPlaying, isTrue);
    expect(update.playback.volume, 1);
    expect(update.playback.progress, 0);
    expect(update.playback.subtitle, playback.subtitle);
  });
}
