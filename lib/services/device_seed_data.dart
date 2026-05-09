import 'package:flutter/material.dart';

import '../models/device_models.dart';
import '../theme/app_theme.dart';

// Temporary product seed data used until paired devices and settings are
// persisted locally. Keeping it out of the controller makes the controller
// easier to read and avoids burying real orchestration code under mock data.
class DeviceSeedData {
  const DeviceSeedData._();

  static const DeviceSnapshot currentDevice = DeviceSnapshot(
    name: 'Qari Speaker 01',
    status: DeviceLinkStatus.connected,
    batteryPercent: 84,
    storageUsedPercent: 62,
    wifiName: 'Home Wi-Fi',
    signalStrength: -48,
    firmwareVersion: '0.2.0-dev',
  );

  static const List<DeviceSnapshot> savedDevices = <DeviceSnapshot>[
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

  static const PlaybackState playback = PlaybackState(
    title: 'Surah Al-Mulk',
    subtitle: 'Ayah 1-10 - Repeat 3x',
    reciter: 'Mishary Rashid Alafasy',
    mode: PlaybackMode.quranRange,
    isPlaying: true,
    volume: 0.72,
    progress: 0.38,
    repeatCount: 3,
  );

  static const UploadJob upload = UploadJob(
    fileName: 'No MP3 selected',
    sizeBytes: 0,
    progress: 0,
    isUploading: false,
    transferNote: 'Choose an MP3 from your phone',
  );

  static const List<QuranSelection> quranSelections = <QuranSelection>[
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

  static const List<MotionRule> motionRules = <MotionRule>[
    MotionRule(
      id: 'entry',
      name: 'Entry remembrance',
      triggerLabel: 'Motion near hallway',
      actionLabel: 'Play Al-Fatihah 1-7, repeat 3x',
      enabled: true,
      icon: Icons.door_front_door_outlined,
      accent: AppTheme.emerald,
    ),
    MotionRule(
      id: 'morning',
      name: 'Morning kitchen',
      triggerLabel: 'First motion after 6:00 AM',
      actionLabel: 'Play Al-Mulk 1-10',
      enabled: true,
      icon: Icons.wb_sunny_outlined,
      accent: AppTheme.gold,
    ),
    MotionRule(
      id: 'night',
      name: 'Quiet night mode',
      triggerLabel: 'Motion after 10:30 PM',
      actionLabel: 'Play Al-Ikhlas at 35% volume',
      enabled: false,
      icon: Icons.nightlight_outlined,
      accent: AppTheme.teal,
    ),
  ];
}
