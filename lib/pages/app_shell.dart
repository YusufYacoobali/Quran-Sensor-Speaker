import 'dart:async';

import 'package:flutter/material.dart';

import '../models/device_models.dart';
import '../services/mock_device_controller.dart';
import '../theme/app_theme.dart';
import 'ble_scan_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final MockDeviceController controller = MockDeviceController();
  int currentIndex = 0;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final pages = <Widget>[
          HomePage(controller: controller),
          QuranPage(controller: controller),
          RulesPage(controller: controller),
          UploadsPage(controller: controller),
          SettingsPage(controller: controller),
        ];

        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: IndexedStack(index: currentIndex, children: pages),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: (value) {
              setState(() => currentIndex = value);
            },
            destinations: const <NavigationDestination>[
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book),
                label: 'Quran',
              ),
              NavigationDestination(
                icon: Icon(Icons.sensors_outlined),
                selectedIcon: Icon(Icons.sensors),
                label: 'Rules',
              ),
              NavigationDestination(
                icon: Icon(Icons.upload_file_outlined),
                selectedIcon: Icon(Icons.upload_file),
                label: 'Upload',
              ),
              NavigationDestination(
                icon: Icon(Icons.tune_outlined),
                selectedIcon: Icon(Icons.tune),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({required this.controller, super.key});

  final MockDeviceController controller;

  @override
  Widget build(BuildContext context) {
    final devices = controller.knownDevices;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: <Widget>[
        _PageTitle(
          title: 'Quran Speaker',
          subtitle: '${devices.length} saved devices',
          trailing: IconButton.filled(
            tooltip: 'Add device',
            onPressed: () {
              unawaited(
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => BleScanPage(controller: controller),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add),
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          itemCount: devices.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.82,
          ),
          itemBuilder: (context, index) {
            final device = devices[index];
            return _DeviceGridCard(
              device: device,
              isPrimary: index == 0,
              onTap: () {
                unawaited(
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => DashboardPage(
                        controller: controller,
                        selectedDevice: device,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 18),
        _InfoBand(
          icon: Icons.bluetooth_searching,
          title: 'Pair a new speaker',
          body:
              'Use the add button to scan for ESP32 speakers nearby, then configure Wi-Fi and playback rules.',
          color: AppTheme.emerald,
        ),
      ],
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    required this.controller,
    required this.selectedDevice,
    super.key,
  });

  final MockDeviceController controller;
  final DeviceSnapshot selectedDevice;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final currentDevice = controller.device;
        final isActiveDevice = selectedDevice.name == currentDevice.name;
        final device = isActiveDevice ? currentDevice : selectedDevice;
        final canControl = isActiveDevice && device.isConnected;
        final playback = controller.playback;

        return Scaffold(
          appBar: AppBar(
            title: Text(device.name),
            actions: <Widget>[
              IconButton(
                tooltip: 'Find device',
                onPressed: () {
                  unawaited(
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => BleScanPage(controller: controller),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.bluetooth_searching),
              ),
            ],
          ),
          body: CustomScrollView(
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _HomeHeader(
                        device: device,
                        onFindDevice: () {
                          unawaited(
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    BleScanPage(controller: controller),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      if (canControl)
                        _HeroDeviceCard(
                          device: device,
                          playback: playback,
                          onPlayPause: () {
                            unawaited(controller.togglePlayback());
                          },
                          onPrevious: () {
                            unawaited(controller.previousTrack());
                          },
                          onNext: () {
                            unawaited(controller.nextTrack());
                          },
                          onReconnect: () {
                            if (controller.hasLiveBleConnection) {
                              unawaited(controller.refreshStatus());
                            } else {
                              controller.simulateReconnect();
                            }
                          },
                          onVolumePreview: controller.previewVolume,
                          onVolumeCommit: (value) {
                            unawaited(controller.setVolume(value));
                          },
                        )
                      else
                        _OfflineDeviceCard(
                          device: device,
                          onConnect: () => controller.connectDevice(device),
                        ),
                      const SizedBox(height: 14),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _MetricTile(
                              icon: Icons.battery_5_bar,
                              label: 'Battery',
                              value: '${device.batteryPercent}%',
                              color: AppTheme.emerald,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MetricTile(
                              icon: Icons.sd_storage_outlined,
                              label: 'Storage',
                              value: '${device.storageUsedPercent}%',
                              color: AppTheme.coral,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MetricTile(
                              icon: Icons.wifi,
                              label: 'Wi-Fi',
                              value: device.wifiName,
                              color: AppTheme.teal,
                            ),
                          ),
                        ],
                      ),
                      if (canControl) ...<Widget>[
                        const SizedBox(height: 22),
                        _SectionHeader(
                          title: 'Quick Actions',
                          actionLabel: 'Protocol',
                          onAction: () => _showProtocolSheet(context),
                        ),
                        const SizedBox(height: 10),
                        _QuickActionGrid(controller: controller),
                        const SizedBox(height: 22),
                        const _SectionHeader(title: 'Motion Highlights'),
                        const SizedBox(height: 10),
                        ...controller.rules
                            .take(2)
                            .map(
                              (rule) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _RuleCard(
                                  rule: rule,
                                  onChanged: (enabled) => controller
                                      .setRuleEnabled(rule.id, enabled),
                                ),
                              ),
                            ),
                      ] else ...<Widget>[
                        const SizedBox(height: 22),
                        const _InfoBand(
                          icon: Icons.history,
                          title: 'Saved device',
                          body:
                              'This speaker is in your device history. Connect to it before changing playback, uploads, or motion rules.',
                          color: AppTheme.teal,
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showProtocolSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const <Widget>[
              Text(
                'App-side protocol stub',
                style: TextStyle(
                  color: AppTheme.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'The UI is mocked, but commands now have a clear shape: status, playRange, setVolume, wifiProvision, uploadPrepare, and upsertMotionRule. When ESP32 firmware is ready, the BLE transport can slot into this contract.',
                style: TextStyle(height: 1.45, color: Color(0xFF52625F)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class QuranPage extends StatelessWidget {
  const QuranPage({required this.controller, super.key});

  final MockDeviceController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: <Widget>[
        const _PageTitle(
          title: 'Quran',
          subtitle: 'Choose a stored recitation range for the speaker.',
        ),
        const SizedBox(height: 16),
        _ReciterSelector(currentReciter: controller.playback.reciter),
        const SizedBox(height: 16),
        ...controller.quranSelections.map(
          (selection) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SelectionCard(
              selection: selection,
              onPlay: () {
                unawaited(controller.playSelection(selection));
              },
            ),
          ),
        ),
      ],
    );
  }
}

class RulesPage extends StatelessWidget {
  const RulesPage({required this.controller, super.key});

  final MockDeviceController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: <Widget>[
        _PageTitle(
          title: 'Motion Rules',
          subtitle: 'Make the speaker respond when the room comes alive.',
          trailing: FilledButton.icon(
            onPressed: () {
              controller.addSuggestedRule();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Suggested rule added')),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add'),
          ),
        ),
        const SizedBox(height: 16),
        _RuleBuilderCard(onAdd: controller.addSuggestedRule),
        const SizedBox(height: 16),
        ...controller.rules.map(
          (rule) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _RuleCard(
              rule: rule,
              onChanged: (enabled) =>
                  controller.setRuleEnabled(rule.id, enabled),
            ),
          ),
        ),
      ],
    );
  }
}

class UploadsPage extends StatelessWidget {
  const UploadsPage({required this.controller, super.key});

  final MockDeviceController controller;

  @override
  Widget build(BuildContext context) {
    final upload = controller.upload;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: <Widget>[
        const _PageTitle(
          title: 'Uploads',
          subtitle: 'Use BLE to configure Wi-Fi, then send test audio locally.',
        ),
        const SizedBox(height: 16),
        _WifiUploadCard(upload: upload, onStart: controller.startUpload),
        const SizedBox(height: 14),
        _InfoBand(
          icon: Icons.router_outlined,
          title: 'Transfer plan',
          body:
              'BLE handles pairing, status, and Wi-Fi credentials. Large MP3 files should move over the device web endpoint once both phone and speaker are on the same network.',
          color: AppTheme.teal,
        ),
        const SizedBox(height: 14),
        const _InfoBand(
          icon: Icons.folder_copy_outlined,
          title: 'Device storage',
          body:
              'Built-in Quran audio is expected on the SD card. Uploads are for testing custom tracks and future user audio.',
          color: AppTheme.gold,
        ),
      ],
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({required this.controller, super.key});

  final MockDeviceController controller;

  @override
  Widget build(BuildContext context) {
    final device = controller.device;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: <Widget>[
        const _PageTitle(
          title: 'Settings',
          subtitle: 'Connection, device identity, and diagnostics.',
        ),
        const SizedBox(height: 16),
        _SettingsTile(
          icon: Icons.bluetooth_connected,
          title: 'BLE connection',
          subtitle: _statusLabel(device.status),
          trailing: OutlinedButton(
            onPressed: controller.simulateReconnect,
            child: const Text('Test'),
          ),
        ),
        _SettingsTile(
          icon: Icons.drive_file_rename_outline,
          title: 'Device name',
          subtitle: device.name,
          trailing: const Icon(Icons.chevron_right),
        ),
        _SettingsTile(
          icon: Icons.system_update_alt,
          title: 'Firmware',
          subtitle: device.firmwareVersion,
          trailing: const Icon(Icons.chevron_right),
        ),
        _SettingsTile(
          icon: Icons.health_and_safety_outlined,
          title: 'Diagnostics',
          subtitle: 'RSSI ${device.signalStrength} dBm - storage healthy',
          trailing: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _DeviceGridCard extends StatelessWidget {
  const _DeviceGridCard({
    required this.device,
    required this.isPrimary,
    required this.onTap,
  });

  final DeviceSnapshot device;
  final bool isPrimary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final connected = device.isConnected;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: connected
                  ? const Color(0xFFBFE7D8)
                  : const Color(0xFFE5ECE4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: connected
                          ? const Color(0xFFDDF3EA)
                          : const Color(0xFFF0F3F0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.speaker_group_outlined,
                      color: connected ? AppTheme.emerald : Colors.black45,
                    ),
                  ),
                  const Spacer(),
                  _StatusDot(connected: connected),
                ],
              ),
              const Spacer(),
              Text(
                device.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  height: 1.12,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isPrimary ? 'Current device' : _statusLabel(device.status),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Icon(
                    Icons.battery_5_bar,
                    size: 17,
                    color: connected ? AppTheme.emerald : Colors.black45,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${device.batteryPercent}%',
                    style: const TextStyle(
                      color: AppTheme.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    connected ? Icons.wifi : Icons.wifi_off,
                    size: 17,
                    color: connected ? AppTheme.teal : Colors.black38,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.device, required this.onFindDevice});

  final DeviceSnapshot device;
  final VoidCallback onFindDevice;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Quran Speaker',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Row(
                children: <Widget>[
                  _StatusDot(connected: device.isConnected),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      device.isConnected
                          ? '${device.name} connected'
                          : '${device.name} saved',
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Find device',
          onPressed: onFindDevice,
          icon: const Icon(Icons.bluetooth_searching),
        ),
      ],
    );
  }
}

class _OfflineDeviceCard extends StatelessWidget {
  const _OfflineDeviceCard({required this.device, required this.onConnect});

  final DeviceSnapshot device;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5ECE4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F3F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.speaker_group_outlined,
                  color: Colors.black45,
                  size: 34,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      device.name,
                      style: const TextStyle(
                        color: AppTheme.ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _statusLabel(device.status),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            device.wifiName == 'Not configured'
                ? 'Needs Wi-Fi setup before uploads'
                : 'Last seen on ${device.wifiName}',
            style: const TextStyle(
              color: AppTheme.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Reconnect over BLE to make this the active speaker.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onConnect,
            icon: const Icon(Icons.bluetooth_connected),
            label: const Text('Connect speaker'),
          ),
        ],
      ),
    );
  }
}

class _HeroDeviceCard extends StatelessWidget {
  const _HeroDeviceCard({
    required this.device,
    required this.playback,
    required this.onPlayPause,
    required this.onPrevious,
    required this.onNext,
    required this.onReconnect,
    required this.onVolumePreview,
    required this.onVolumeCommit,
  });

  final DeviceSnapshot device;
  final PlaybackState playback;
  final VoidCallback onPlayPause;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onReconnect;
  final ValueChanged<double> onVolumePreview;
  final ValueChanged<double> onVolumeCommit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: <Color>[AppTheme.ink, AppTheme.teal, AppTheme.emerald],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.teal.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(
                  Icons.speaker_group_outlined,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      device.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _statusLabel(device.status),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.76),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filled(
                tooltip: 'Reconnect',
                onPressed: onReconnect,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.16),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.sync),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            playback.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            playback.subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: playback.progress,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.gold),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              IconButton.filledTonal(
                tooltip: 'Previous',
                onPressed: onPrevious,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.16),
                  foregroundColor: Colors.white,
                  fixedSize: const Size(46, 46),
                ),
                icon: const Icon(Icons.skip_previous),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: playback.isPlaying ? 'Pause' : 'Play',
                onPressed: onPlayPause,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.ink,
                  fixedSize: const Size(56, 56),
                ),
                icon: Icon(
                  playback.isPlaying ? Icons.pause : Icons.play_arrow,
                  size: 30,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Next',
                onPressed: onNext,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.16),
                  foregroundColor: Colors.white,
                  fixedSize: const Size(46, 46),
                ),
                icon: const Icon(Icons.skip_next),
              ),
              const SizedBox(width: 12),
              const Spacer(),
              _HeroPill(icon: Icons.repeat, label: '${playback.repeatCount}x'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              const Icon(Icons.volume_up, color: Colors.white, size: 20),
              Expanded(
                child: Slider(
                  value: playback.volume.clamp(0, 1).toDouble(),
                  onChanged: onVolumePreview,
                  onChangeEnd: onVolumeCommit,
                ),
              ),
              Text(
                '${(playback.volume * 100).round()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: color),
            const SizedBox(height: 10),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.ink,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid({required this.controller});

  final MockDeviceController controller;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.38,
      children: <Widget>[
        _ActionTile(
          icon: Icons.play_circle_outline,
          title: controller.playback.isPlaying
              ? 'Pause recitation'
              : 'Resume recitation',
          color: AppTheme.emerald,
          onTap: () {
            unawaited(controller.togglePlayback());
          },
        ),
        _ActionTile(
          icon: Icons.sensors,
          title: 'Add motion rule',
          color: AppTheme.coral,
          onTap: controller.addSuggestedRule,
        ),
        _ActionTile(
          icon: Icons.wifi_password,
          title: 'Provision Wi-Fi',
          color: AppTheme.teal,
          onTap: controller.simulateReconnect,
        ),
        _ActionTile(
          icon: Icons.upload_file,
          title: 'Upload test MP3',
          color: AppTheme.gold,
          onTap: controller.startUpload,
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5ECE4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Icon(icon, color: color, size: 28),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.ink,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReciterSelector extends StatelessWidget {
  const _ReciterSelector({required this.currentReciter});

  final String currentReciter;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: <Widget>[
            const CircleAvatar(
              backgroundColor: Color(0xFFDDF3EA),
              foregroundColor: AppTheme.emerald,
              child: Icon(Icons.record_voice_over_outlined),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Reciter',
                    style: TextStyle(
                      color: AppTheme.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    currentReciter,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down),
          ],
        ),
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({required this.selection, required this.onPlay});

  final QuranSelection selection;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.ink,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                selection.surahNumber.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    selection.surahName,
                    style: const TextStyle(
                      color: AppTheme.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${selection.translation} - Ayah ${selection.fromAyah}-${selection.toAyah} - ${selection.repeatCount}x',
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Play',
              onPressed: onPlay,
              icon: const Icon(Icons.play_arrow),
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleBuilderCard extends StatelessWidget {
  const _RuleBuilderCard({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.ink,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.motion_photos_on_outlined, color: AppTheme.gold),
          const SizedBox(height: 12),
          const Text(
            'When motion is detected',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pick a surah, ayah range, repeat count, and volume profile.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onAdd,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.gold,
              foregroundColor: AppTheme.ink,
            ),
            icon: const Icon(Icons.add),
            label: const Text('Create suggested rule'),
          ),
        ],
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({required this.rule, required this.onChanged});

  final MotionRule rule;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: <Widget>[
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: rule.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(rule.icon, color: rule.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    rule.name,
                    style: const TextStyle(
                      color: AppTheme.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rule.triggerLabel,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    rule.actionLabel,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Switch(value: rule.enabled, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _WifiUploadCard extends StatelessWidget {
  const _WifiUploadCard({required this.upload, required this.onStart});

  final UploadJob upload;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.audio_file_outlined, color: AppTheme.coral),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    upload.fileName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            LinearProgressIndicator(
              minHeight: 8,
              value: upload.progress,
              backgroundColor: const Color(0xFFE7EEE7),
            ),
            const SizedBox(height: 10),
            Text(
              upload.transferNote,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: upload.isUploading ? null : onStart,
              icon: Icon(upload.isUploading ? Icons.sync : Icons.upload),
              label: Text(
                upload.progress >= 1 ? 'Upload again' : 'Start test upload',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBand extends StatelessWidget {
  const _InfoBand({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(body, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          leading: Icon(icon, color: AppTheme.emerald),
          title: Text(
            title,
            style: const TextStyle(
              color: AppTheme.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          subtitle: Text(subtitle),
          trailing: trailing,
        ),
      ),
    );
  }
}

class _PageTitle extends StatelessWidget {
  const _PageTitle({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        if (trailing != null) ...<Widget>[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.connected});

  final bool connected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        color: connected ? AppTheme.emerald : AppTheme.coral,
        shape: BoxShape.circle,
      ),
    );
  }
}

String _statusLabel(DeviceLinkStatus status) {
  return switch (status) {
    DeviceLinkStatus.disconnected => 'Disconnected',
    DeviceLinkStatus.scanning => 'Scanning nearby speakers',
    DeviceLinkStatus.connecting => 'Connecting over BLE',
    DeviceLinkStatus.connected => 'Connected over BLE',
  };
}
