import 'package:devicesense/core/platform/native_channel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bluetooth_info/bloc/bluetooth_discovery_bloc.dart';
import '../../bluetooth_info/bloc/bluetooth_discovery_event.dart';

class PermissionDeniedError extends StatelessWidget {
  const PermissionDeniedError({super.key, required this.detail});

  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bluetooth_disabled_rounded,
                size: 36,
                color: scheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Bluetooth Permission Required',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'DeviceSense needs the Bluetooth permission to discover '
              'nearby devices. No location data is collected or used.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: NativeChannel.openAppSettings,
              icon: const Icon(Icons.settings_rounded),
              label: const Text('Open App Settings'),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () => context.read<BluetoothDiscoveryBloc>().add(
                const BluetoothScanStartRequested(),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
            if (detail.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                detail,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
