part of 'app_shell.dart';

class HomePage extends StatelessWidget {
  const HomePage({required this.controller, super.key});

  final DeviceController controller;

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

  final DeviceController controller;
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
                                  onChanged: (enabled) {
                                    unawaited(
                                      controller.setRuleEnabled(
                                        rule.id,
                                        enabled,
                                      ),
                                    );
                                  },
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
