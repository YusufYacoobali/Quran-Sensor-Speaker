part of 'app_shell.dart';

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

  final DeviceController controller;

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
          onTap: () {
            unawaited(controller.addSuggestedRule());
          },
        ),
        _ActionTile(
          icon: Icons.wifi_password,
          title: 'Provision Wi-Fi',
          color: AppTheme.teal,
          onTap: () => _showWifiProvisionSheet(context, controller),
        ),
        _ActionTile(
          icon: Icons.upload_file,
          title: 'Upload test MP3',
          color: AppTheme.gold,
          onTap: () {
            unawaited(controller.startUpload());
          },
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
