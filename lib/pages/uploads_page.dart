part of 'app_shell.dart';

class UploadsPage extends StatelessWidget {
  const UploadsPage({required this.controller, super.key});

  final DeviceController controller;

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
        _WifiProvisionCard(
          controller: controller,
          onProvision: () => _showWifiProvisionSheet(context, controller),
        ),
        const SizedBox(height: 14),
        _WifiUploadCard(
          upload: upload,
          onChoose: controller.pickUploadFile,
          onStart: controller.startUpload,
        ),
        const SizedBox(height: 14),
        _InfoBand(
          icon: Icons.router_outlined,
          title: 'Transfer plan',
          body:
              'BLE prepares an upload session, then the app sends the selected MP3 to the device URL over local Wi-Fi.',
          color: AppTheme.teal,
        ),
        const SizedBox(height: 14),
        const _InfoBand(
          icon: Icons.folder_copy_outlined,
          title: 'Device storage',
          body:
              'Built-in Quran audio is expected on the SD card. This prototype flow uploads one MP3 chosen from the phone.',
          color: AppTheme.gold,
        ),
      ],
    );
  }
}

class _WifiProvisionCard extends StatelessWidget {
  const _WifiProvisionCard({
    required this.controller,
    required this.onProvision,
  });

  final DeviceController controller;
  final VoidCallback onProvision;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFDDF3EA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.wifi_password, color: AppTheme.teal),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Wi-Fi provisioning',
                    style: TextStyle(
                      color: AppTheme.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    controller.hasLiveBleConnection
                        ? 'Ready to send credentials over BLE'
                        : 'Connect a Quran Speaker to send credentials',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (controller.lastProtocolMessage != null) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      controller.lastProtocolMessage!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: onProvision,
              child: const Text('Configure'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WifiUploadCard extends StatelessWidget {
  const _WifiUploadCard({
    required this.upload,
    required this.onChoose,
    required this.onStart,
  });

  final UploadJob upload;
  final Future<void> Function() onChoose;
  final Future<void> Function() onStart;

  @override
  Widget build(BuildContext context) {
    final sizeLabel = upload.sizeBytes == 0
        ? 'No file chosen'
        : _formatBytes(upload.sizeBytes);

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        upload.fileName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sizeLabel,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: upload.isUploading
                        ? null
                        : () {
                            unawaited(onChoose());
                          },
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Choose MP3'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: upload.isUploading
                        ? null
                        : () {
                            unawaited(onStart());
                          },
                    icon: Icon(upload.isUploading ? Icons.sync : Icons.upload),
                    label: Text(
                      upload.progress >= 1 ? 'Upload again' : 'Upload',
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
          ],
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '$bytes B';
  }
}

Future<void> _showWifiProvisionSheet(
  BuildContext context,
  DeviceController controller,
) async {
  final ssidController = TextEditingController(
    text: controller.device.wifiName,
  );
  final passwordController = TextEditingController();
  var isSubmitting = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          Future<void> submit() async {
            setSheetState(() => isSubmitting = true);
            final success = await controller.provisionWifi(
              ssid: ssidController.text,
              password: passwordController.text,
            );
            setSheetState(() => isSubmitting = false);

            if (!context.mounted) {
              return;
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  controller.lastProtocolMessage ??
                      (success ? 'Wi-Fi credentials sent' : 'Wi-Fi failed'),
                ),
              ),
            );

            if (success) {
              Navigator.of(context).pop();
            }
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(
              22,
              4,
              22,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Provision Wi-Fi',
                  style: TextStyle(
                    color: AppTheme.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ssidController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Network name',
                    prefixIcon: Icon(Icons.wifi),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) {
                    if (!isSubmitting) {
                      unawaited(submit());
                    }
                  },
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: isSubmitting ? null : () => unawaited(submit()),
                  icon: isSubmitting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                    controller.hasLiveBleConnection
                        ? 'Send to speaker'
                        : 'Save mock Wi-Fi',
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );

  ssidController.dispose();
  passwordController.dispose();
}
