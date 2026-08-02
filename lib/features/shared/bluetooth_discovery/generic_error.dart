import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bluetooth_info/bloc/bluetooth_discovery_bloc.dart';
import '../../bluetooth_info/bloc/bluetooth_discovery_event.dart';

class GenericError extends StatelessWidget {
  const GenericError({
    super.key,
    required this.code,
    required this.detail,
    required this.icon,
  });

  final String code;
  final String detail;
  final IconData icon;

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
              child: Icon(icon, size: 36, color: scheme.onErrorContainer),
            ),
            const SizedBox(height: 24),
            Text(
              'Scan Failed',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              detail.isNotEmpty ? detail : 'An unexpected error occurred.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Error code: $code',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.read<BluetoothDiscoveryBloc>().add(
                const BluetoothScanStartRequested(),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
