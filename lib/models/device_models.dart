import 'package:flutter/material.dart';

enum DeviceLinkStatus { disconnected, scanning, connecting, connected }

enum PlaybackMode { quranRange, uploadedAudio }

class DeviceSnapshot {
  const DeviceSnapshot({
    required this.name,
    required this.status,
    required this.batteryPercent,
    required this.storageUsedPercent,
    required this.wifiName,
    required this.signalStrength,
    required this.firmwareVersion,
  });

  final String name;
  final DeviceLinkStatus status;
  final int batteryPercent;
  final int storageUsedPercent;
  final String wifiName;
  final int signalStrength;
  final String firmwareVersion;

  bool get isConnected => status == DeviceLinkStatus.connected;

  DeviceSnapshot copyWith({
    String? name,
    DeviceLinkStatus? status,
    int? batteryPercent,
    int? storageUsedPercent,
    String? wifiName,
    int? signalStrength,
    String? firmwareVersion,
  }) {
    return DeviceSnapshot(
      name: name ?? this.name,
      status: status ?? this.status,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      storageUsedPercent: storageUsedPercent ?? this.storageUsedPercent,
      wifiName: wifiName ?? this.wifiName,
      signalStrength: signalStrength ?? this.signalStrength,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
    );
  }
}

class PlaybackState {
  const PlaybackState({
    required this.title,
    required this.subtitle,
    required this.reciter,
    required this.mode,
    required this.isPlaying,
    required this.volume,
    required this.progress,
    required this.repeatCount,
  });

  final String title;
  final String subtitle;
  final String reciter;
  final PlaybackMode mode;
  final bool isPlaying;
  final double volume;
  final double progress;
  final int repeatCount;

  PlaybackState copyWith({
    String? title,
    String? subtitle,
    String? reciter,
    PlaybackMode? mode,
    bool? isPlaying,
    double? volume,
    double? progress,
    int? repeatCount,
  }) {
    return PlaybackState(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      reciter: reciter ?? this.reciter,
      mode: mode ?? this.mode,
      isPlaying: isPlaying ?? this.isPlaying,
      volume: volume ?? this.volume,
      progress: progress ?? this.progress,
      repeatCount: repeatCount ?? this.repeatCount,
    );
  }
}

class QuranSelection {
  const QuranSelection({
    required this.surahNumber,
    required this.surahName,
    required this.translation,
    required this.fromAyah,
    required this.toAyah,
    required this.repeatCount,
  });

  final int surahNumber;
  final String surahName;
  final String translation;
  final int fromAyah;
  final int toAyah;
  final int repeatCount;

  String get rangeLabel => '$surahName $fromAyah-$toAyah';
}

class MotionRule {
  const MotionRule({
    required this.id,
    required this.name,
    required this.triggerLabel,
    required this.actionLabel,
    required this.enabled,
    required this.icon,
    required this.accent,
  });

  final String id;
  final String name;
  final String triggerLabel;
  final String actionLabel;
  final bool enabled;
  final IconData icon;
  final Color accent;

  MotionRule copyWith({bool? enabled}) {
    return MotionRule(
      id: id,
      name: name,
      triggerLabel: triggerLabel,
      actionLabel: actionLabel,
      enabled: enabled ?? this.enabled,
      icon: icon,
      accent: accent,
    );
  }
}

class UploadJob {
  const UploadJob({
    required this.fileName,
    required this.sizeBytes,
    required this.progress,
    required this.isUploading,
    required this.transferNote,
  });

  final String fileName;
  final int sizeBytes;
  final double progress;
  final bool isUploading;
  final String transferNote;

  UploadJob copyWith({
    String? fileName,
    int? sizeBytes,
    double? progress,
    bool? isUploading,
    String? transferNote,
  }) {
    return UploadJob(
      fileName: fileName ?? this.fileName,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      progress: progress ?? this.progress,
      isUploading: isUploading ?? this.isUploading,
      transferNote: transferNote ?? this.transferNote,
    );
  }
}
