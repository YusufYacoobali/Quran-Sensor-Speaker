import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleScanPage extends StatefulWidget {
  const BleScanPage({super.key});

  @override
  State<BleScanPage> createState() => _BleScanPageState();
}

class _BleScanPageState extends State<BleScanPage> {
  final List<ScanResult> _results = [];

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  void _startScan() async {
    _results.clear();

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 5),
    );

    FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        _results
          ..clear()
          ..addAll(results);
      });
    });
  }

  @override
  void dispose() {
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find Device')),
      body: _results.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _results.length,
        itemBuilder: (context, index) {
          final r = _results[index];
          final name = r.device.name.isNotEmpty
              ? r.device.name
              : 'Unknown device';

          return ListTile(
            title: Text(name),
            subtitle: Text(r.device.id.toString()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: connect + go to WiFi screen
            },
          );
        },
      ),
    );
  }
}
