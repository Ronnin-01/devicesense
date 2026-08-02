import 'package:flutter/material.dart';

import '../../bluetooth_info/models/bluetooth_discovery_snapshot.dart';

class AdapterStatusBar extends StatelessWidget {
  const AdapterStatusBar({super.key, required this.snapshot});

  final BluetoothDiscoverySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isOn = snapshot.adapterState == 'ON';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: scheme.surfaceContainer,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOn ? const Color(0xFF00C853) : scheme.error,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Bluetooth ${snapshot.adapterState}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (snapshot.devices.isNotEmpty)
            Text(
              '${snapshot.devices.length} device${snapshot.devices.length == 1 ? '' : 's'}',
              style: theme.textTheme.bodyMedium,
            ),
        ],
      ),
    );
  }
}
