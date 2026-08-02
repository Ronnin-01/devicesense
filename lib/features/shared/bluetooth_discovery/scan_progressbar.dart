import 'package:flutter/material.dart';

import '../../bluetooth_info/models/bluetooth_discovery_snapshot.dart';

class ScanProgressBar extends StatelessWidget {
  const ScanProgressBar({super.key, required this.snapshot});

  final BluetoothDiscoverySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final elapsed = snapshot.scanProgressElapsed;
    final total = snapshot.scanProgressTotal ?? 12;
    final progress = elapsed != null ? elapsed / total : null;

    return LinearProgressIndicator(
      value: progress, // null → indeterminate until first tick arrives
      backgroundColor: scheme.surfaceContainer,
      color: scheme.primary,
      minHeight: 3,
    );
  }
}
