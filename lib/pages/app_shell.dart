import 'dart:async';

import 'package:flutter/material.dart';

import '../models/device_models.dart';
import '../services/device_controller.dart';
import '../theme/app_theme.dart';
import 'ble_scan_page.dart';

part 'home_page.dart';
part 'home_widgets.dart';
part 'quran_page.dart';
part 'rules_page.dart';
part 'uploads_page.dart';
part 'settings_page.dart';
part 'shared_widgets.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final DeviceController controller = DeviceController();
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
