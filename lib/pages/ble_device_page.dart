import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../services/device_protocol.dart';
import '../services/mock_device_controller.dart';
import '../services/quran_ble_connection.dart';
import '../theme/app_theme.dart';

class BleDevicePage extends StatefulWidget {
  const BleDevicePage({required this.scanResult, this.controller, super.key});

  final ScanResult scanResult;
  final MockDeviceController? controller;

  @override
  State<BleDevicePage> createState() => _BleDevicePageState();
}

class _BleDevicePageState extends State<BleDevicePage> {
  late final BluetoothDevice device = widget.scanResult.device;
  StreamSubscription<BluetoothConnectionState>? _connectionSub;
  QuranBleConnection? _quranConnection;
  bool _connectionHandedOff = false;

  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.disconnected;
  List<BluetoothService> _services = <BluetoothService>[];
  bool _isConnecting = true;
  bool _isDiscovering = false;
  bool _supportsQuranProtocol = false;
  bool _isSendingStatus = false;
  String? _error;
  String? _protocolStatus;

  String get _deviceName {
    final platformName = device.platformName;
    if (platformName.isNotEmpty) {
      return platformName;
    }
    return 'Unknown BLE device';
  }

  @override
  void initState() {
    super.initState();
    _connectionSub = device.connectionState.listen((state) {
      if (mounted) {
        setState(() => _connectionState = state);
      }
    });
    _connectAndDiscover();
  }

  Future<void> _connectAndDiscover() async {
    setState(() {
      _isConnecting = true;
      _isDiscovering = false;
      _error = null;
      _protocolStatus = null;
    });

    try {
      await FlutterBluePlus.stopScan();
      if (!device.isConnected) {
        await device.connect(
          license: License.free,
          timeout: const Duration(seconds: 18),
          mtu: 512,
        );
      }

      setState(() => _isDiscovering = true);
      final services = await device.discoverServices();
      final quranConnection = QuranBleConnection.fromServices(
        device: device,
        services: services,
      );

      setState(() {
        _services = services;
        _supportsQuranProtocol = quranConnection != null;
        _isDiscovering = false;
      });

      if (quranConnection != null) {
        _quranConnection = quranConnection;
        await _attachQuranConnection(quranConnection);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _isDiscovering = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

  Future<void> _attachQuranConnection(QuranBleConnection connection) async {
    setState(() {
      _isSendingStatus = true;
      _protocolStatus = 'Quran Speaker service found. Reading status...';
    });

    try {
      await connection.start();
      final controller = widget.controller;
      if (controller != null) {
        await controller.attachBleConnection(
          connection,
          deviceName: _deviceName,
          rssi: widget.scanResult.rssi,
        );
        _connectionHandedOff = true;
      } else {
        final protocol = DeviceProtocol(connection);
        final response = await protocol.requestStatus();
        if (mounted) {
          setState(() {
            _protocolStatus = response.ok
                ? 'status.get response received'
                : 'status.get failed: ${response.error?.message ?? response.type}';
          });
        }
        return;
      }
      if (mounted) {
        setState(() {
          _protocolStatus =
              'Connected to app dashboard. Playback controls are live.';
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _protocolStatus = 'Protocol setup failed: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingStatus = false);
      }
    }
  }

  Future<void> _disconnect() async {
    setState(() => _error = null);
    try {
      if (_connectionHandedOff) {
        await widget.controller?.disconnectLiveDevice();
      } else {
        await _quranConnection?.disconnect();
      }
      _quranConnection = null;
      _connectionHandedOff = false;
      if (device.isConnected) {
        await device.disconnect();
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    }
  }

  @override
  void dispose() {
    _connectionSub?.cancel();
    if (!_connectionHandedOff) {
      unawaited(_quranConnection?.disconnect() ?? Future<void>.value());
    }
    if (device.isConnected && !_connectionHandedOff) {
      unawaited(device.disconnect());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connected = _connectionState == BluetoothConnectionState.connected;
    final busy = _isConnecting || _isDiscovering;

    return Scaffold(
      appBar: AppBar(
        title: Text(_deviceName),
        actions: <Widget>[
          IconButton(
            tooltip: connected ? 'Disconnect' : 'Reconnect',
            onPressed: busy
                ? null
                : connected
                ? _disconnect
                : _connectAndDiscover,
            icon: Icon(connected ? Icons.link_off : Icons.sync),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: <Widget>[
          _ConnectionHero(
            name: _deviceName,
            remoteId: device.remoteId.toString(),
            rssi: widget.scanResult.rssi,
            state: _connectionState,
            busy: busy,
            supportsQuranProtocol: _supportsQuranProtocol,
          ),
          const SizedBox(height: 14),
          if (_error != null)
            _InfoBand(
              icon: Icons.error_outline,
              title: 'Connection issue',
              body: _error!,
              color: AppTheme.coral,
            ),
          if (_error != null) const SizedBox(height: 14),
          if (_protocolStatus != null)
            _InfoBand(
              icon: _supportsQuranProtocol
                  ? Icons.verified_outlined
                  : Icons.info_outline,
              title: 'Quran protocol',
              body: _protocolStatus!,
              color: AppTheme.emerald,
              trailing: _isSendingStatus
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
            ),
          if (_protocolStatus != null) const SizedBox(height: 14),
          _SectionHeader(
            title: 'Discovered Services',
            subtitle: busy
                ? 'Connecting and discovering GATT...'
                : '${_services.length} services found',
          ),
          const SizedBox(height: 10),
          if (busy)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(22),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_services.isEmpty)
            const _InfoBand(
              icon: Icons.search_off,
              title: 'No services discovered',
              body:
                  'Try reconnecting, or make sure the device is advertising BLE GATT services.',
              color: AppTheme.gold,
            )
          else
            ..._services.map(
              (service) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ServiceCard(service: service),
              ),
            ),
        ],
      ),
    );
  }
}

class _ConnectionHero extends StatelessWidget {
  const _ConnectionHero({
    required this.name,
    required this.remoteId,
    required this.rssi,
    required this.state,
    required this.busy,
    required this.supportsQuranProtocol,
  });

  final String name;
  final String remoteId;
  final int rssi;
  final BluetoothConnectionState state;
  final bool busy;
  final bool supportsQuranProtocol;

  @override
  Widget build(BuildContext context) {
    final connected = state == BluetoothConnectionState.connected;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          colors: connected
              ? const <Color>[AppTheme.ink, AppTheme.teal]
              : const <Color>[Color(0xFF596662), AppTheme.ink],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  supportsQuranProtocol
                      ? Icons.speaker_group_outlined
                      : Icons.bluetooth,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _connectionLabel(state, busy),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.76),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            remoteId,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              _HeroPill(icon: Icons.signal_cellular_alt, label: '$rssi dBm'),
              const SizedBox(width: 8),
              _HeroPill(
                icon: supportsQuranProtocol
                    ? Icons.verified_outlined
                    : Icons.extension_outlined,
                label: supportsQuranProtocol ? 'Protocol found' : 'Generic BLE',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service});

  final BluetoothService service;

  @override
  Widget build(BuildContext context) {
    final isQuranService = _sameUuid(
      service.uuid,
      QuranSpeakerBleUuids.service,
    );

    return Card(
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        leading: Icon(
          isQuranService ? Icons.speaker_group_outlined : Icons.hub_outlined,
          color: isQuranService ? AppTheme.emerald : AppTheme.teal,
        ),
        title: Text(
          isQuranService ? 'Quran Speaker Service' : 'Service',
          style: const TextStyle(
            color: AppTheme.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          service.uuid.toString(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        children: <Widget>[
          if (service.characteristics.isEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'No characteristics',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            ...service.characteristics.map(
              (characteristic) =>
                  _CharacteristicRow(characteristic: characteristic),
            ),
        ],
      ),
    );
  }
}

class _CharacteristicRow extends StatelessWidget {
  const _CharacteristicRow({required this.characteristic});

  final BluetoothCharacteristic characteristic;

  @override
  Widget build(BuildContext context) {
    final isRx = _sameUuid(characteristic.uuid, QuranSpeakerBleUuids.commandRx);
    final isTx = _sameUuid(characteristic.uuid, QuranSpeakerBleUuids.eventTx);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5ECE4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  isRx
                      ? 'Command RX'
                      : isTx
                      ? 'Event TX'
                      : 'Characteristic',
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                _formatProperties(characteristic.properties),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            characteristic.uuid.toString(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: Colors.white, size: 17),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 2),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _InfoBand extends StatelessWidget {
  const _InfoBand({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;
  final Widget? trailing;

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
          if (trailing != null) ...<Widget>[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}

bool _sameUuid(Guid uuid, String expected) {
  return uuid.toString().toLowerCase() == expected.toLowerCase();
}

String _connectionLabel(BluetoothConnectionState state, bool busy) {
  if (busy) {
    return state == BluetoothConnectionState.connected
        ? 'Discovering services'
        : 'Connecting';
  }
  return switch (state) {
    BluetoothConnectionState.connected => 'Connected',
    BluetoothConnectionState.disconnected => 'Disconnected',
    _ => state.name,
  };
}

String _formatProperties(CharacteristicProperties properties) {
  final labels = <String>[
    if (properties.read) 'read',
    if (properties.write) 'write',
    if (properties.writeWithoutResponse) 'writeNR',
    if (properties.notify) 'notify',
    if (properties.indicate) 'indicate',
  ];
  return labels.isEmpty ? 'no props' : labels.join(', ');
}
