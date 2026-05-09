import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/mock_device_controller.dart';
import '../theme/app_theme.dart';
import 'ble_device_page.dart';

class BleScanPage extends StatefulWidget {
  const BleScanPage({this.controller, super.key});

  final MockDeviceController? controller;

  @override
  State<BleScanPage> createState() => _BleScanPageState();
}

class _BleScanPageState extends State<BleScanPage> {
  final Map<DeviceIdentifier, ScanResult> _results =
      <DeviceIdentifier, ScanResult>{};
  StreamSubscription<List<ScanResult>>? _scanSub;

  bool _isScanning = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initScan();
  }

  Future<void> _initScan() async {
    setState(() => _error = null);

    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      if (mounted) {
        setState(() => _error = 'Bluetooth is off');
      }
      return;
    }

    final hasPermissions = await _requestBlePermissions();
    if (!hasPermissions) {
      if (mounted) {
        setState(() => _error = 'Bluetooth permission is required');
      }
      return;
    }

    _startScan();
  }

  Future<bool> _requestBlePermissions() async {
    if (Platform.isAndroid) {
      final statuses = await <Permission>[
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();
      return statuses.values.every((status) => status.isGranted);
    }

    if (Platform.isIOS) {
      final status = await Permission.bluetooth.request();
      return status.isGranted;
    }

    return true;
  }

  void _startScan() {
    _results.clear();
    _scanSub?.cancel();
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      for (final result in results) {
        _results[result.device.remoteId] = result;
      }
      if (mounted) {
        setState(() {});
      }
    });

    setState(() => _isScanning = true);

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 6)).then((_) {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    });
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final devices = _results.values.toList()
      ..sort((a, b) => b.rssi.compareTo(a.rssi));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Device'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Scan again',
            icon: const Icon(Icons.refresh),
            onPressed: _isScanning ? null : _initScan,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Nearby BLE devices',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Connect to any nearby BLE device. Quran Speaker services are detected after connection.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            Expanded(child: _buildBody(devices)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(List<ScanResult> devices) {
    if (_error != null) {
      return _EmptyScanState(
        icon: Icons.bluetooth_disabled,
        title: _error!,
        body: 'Turn on Bluetooth, allow permissions, and try scanning again.',
        action: OutlinedButton.icon(
          onPressed: _initScan,
          icon: const Icon(Icons.refresh),
          label: const Text('Try again'),
        ),
      );
    }

    if (_isScanning && devices.isEmpty) {
      return const _EmptyScanState(
        icon: Icons.bluetooth_searching,
        title: 'Scanning',
        body: 'Looking for nearby speakers...',
        showProgress: true,
      );
    }

    if (devices.isEmpty) {
      return _EmptyScanState(
        icon: Icons.speaker_group_outlined,
        title: 'No devices found',
        body: 'Keep the device awake and close to the phone.',
        action: FilledButton.icon(
          onPressed: _initScan,
          icon: const Icon(Icons.refresh),
          label: const Text('Scan again'),
        ),
      );
    }

    return ListView.separated(
      itemCount: devices.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final result = devices[index];
        final name = result.device.platformName.isNotEmpty
            ? result.device.platformName
            : 'Unknown BLE device';

        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFDDF3EA),
              foregroundColor: AppTheme.emerald,
              child: Icon(
                name.toLowerCase().contains('quran')
                    ? Icons.speaker_group
                    : Icons.bluetooth,
              ),
            ),
            title: Text(
              name,
              style: const TextStyle(
                color: AppTheme.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            subtitle: Text(
              '${result.device.remoteId} • RSSI ${result.rssi} dBm',
            ),
            trailing: FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => BleDevicePage(
                    scanResult: result,
                    controller: widget.controller,
                  ),
                ),
              ),
              child: const Text('Connect'),
            ),
          ),
        );
      },
    );
  }
}

class _EmptyScanState extends StatelessWidget {
  const _EmptyScanState({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
    this.showProgress = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, color: AppTheme.emerald, size: 42),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                body,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (showProgress) ...<Widget>[
                const SizedBox(height: 18),
                const CircularProgressIndicator(),
              ],
              if (action != null) ...<Widget>[
                const SizedBox(height: 18),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
