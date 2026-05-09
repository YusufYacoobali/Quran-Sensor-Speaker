part of 'app_shell.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({required this.controller, super.key});

  final DeviceController controller;

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
