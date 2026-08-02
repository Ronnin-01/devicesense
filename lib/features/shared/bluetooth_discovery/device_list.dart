import 'package:flutter/material.dart';

import '../../bluetooth_info/models/bluetooth_discovery_snapshot.dart';
import 'device_card.dart';
import 'section_header.dart';

class DeviceList extends StatelessWidget {
  const DeviceList({super.key, required this.snapshot});

  final BluetoothDiscoverySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    // Split into two groups for section headers.
    final classic = snapshot.devices
        .where((d) => d.source == 'classic')
        .toList();
    final ble = snapshot.devices.where((d) => d.source == 'ble').toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        if (ble.isNotEmpty) ...[
          SectionHeader(
            label: 'Bluetooth Low Energy',
            count: ble.length,
            icon: Icons.bluetooth_searching_rounded,
            color: const Color(0xFF6200EA),
          ),
          const SizedBox(height: 8),
          ...ble.map((d) => DeviceCard(device: d)),
        ],
        if (classic.isNotEmpty) ...[
          SectionHeader(
            label: 'Classic Bluetooth',
            count: classic.length,
            icon: Icons.bluetooth_rounded,
            color: const Color(0xFF2979FF),
          ),
          const SizedBox(height: 8),
          ...classic.map((d) => DeviceCard(device: d)),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}
