import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/platform/native_channel.dart';
import '../bluetooth_info/bloc/bluetooth_discovery_bloc.dart';
import '../bluetooth_info/bloc/bluetooth_discovery_event.dart';
import '../bluetooth_info/bloc/bluetooth_discovery_state.dart';
import '../bluetooth_info/models/bluetooth_device_model.dart';
import '../bluetooth_info/models/bluetooth_discovery_snapshot.dart';

// ============================================================
// Route-level widget — provides the Bloc, nothing else
// ============================================================

class BluetoothDiscoveryPage extends StatelessWidget {
  const BluetoothDiscoveryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<BluetoothDiscoveryBloc>()..add(const BluetoothDiscoveryStarted()),
      child: const _DiscoveryView(),
    );
  }
}

// ============================================================
// Top-level state router
// ============================================================

class _DiscoveryView extends StatelessWidget {
  const _DiscoveryView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: BlocBuilder<BluetoothDiscoveryBloc, BluetoothDiscoveryState>(
        builder: (context, state) {
          return switch (state) {
            BluetoothDiscoveryInitial() => const _IdleBody(),
            BluetoothDiscoveryLoading() => const _LoadingBody(),
            BluetoothDiscoveryLoaded(:final snapshot) => _LoadedBody(
              snapshot: snapshot,
            ),
            BluetoothDiscoveryError(:final message) => _ErrorBody(
              message: message,
            ),
            _ => const _IdleBody(),
          };
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Bluetooth Discovery'),
      actions: [
        BlocBuilder<BluetoothDiscoveryBloc, BluetoothDiscoveryState>(
          buildWhen: (previous, current) {
            final previousScanning =
                previous is BluetoothDiscoveryLoaded && previous.isScanning;
            final currentScanning =
                current is BluetoothDiscoveryLoaded && current.isScanning;

            return previous.runtimeType != current.runtimeType ||
                previousScanning != currentScanning;
          },
          builder: (context, state) {
            final isScanning =
                state is BluetoothDiscoveryLoaded && state.isScanning;
            final canControl =
                state is BluetoothDiscoveryLoaded ||
                state is BluetoothDiscoveryInitial ||
                state is BluetoothDiscoveryError;

            return IconButton(
              tooltip: isScanning ? 'Stop scan' : 'Start scan',
              icon: Icon(
                isScanning
                    ? Icons.stop_circle_outlined
                    : Icons.bluetooth_searching_rounded,
              ),
              onPressed: canControl
                  ? () {
                      context.read<BluetoothDiscoveryBloc>().add(
                        isScanning
                            ? const BluetoothScanStopRequested()
                            : const BluetoothScanStartRequested(),
                      );
                    }
                  : null,
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

// ============================================================
// State bodies
// ============================================================

class _IdleBody extends StatelessWidget {
  const _IdleBody();

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
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bluetooth_rounded,
                size: 40,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text('Ready to Scan', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Tap the scan button to discover nearby Bluetooth devices.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.read<BluetoothDiscoveryBloc>().add(
                const BluetoothScanStartRequested(),
              ),
              icon: const Icon(Icons.radar_rounded),
              label: const Text('Start Scan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text('Starting scan…', style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({required this.snapshot});

  final BluetoothDiscoverySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AdapterStatusBar(snapshot: snapshot),
        if (snapshot.isScanning) _ScanProgressBar(snapshot: snapshot),
        Expanded(
          child: snapshot.devices.isEmpty
              ? _EmptyDeviceList(isScanning: snapshot.isScanning)
              : _DeviceList(snapshot: snapshot),
        ),
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message});

  final String message;

  // Parse the code prefix the repository attaches: "CODE: message"
  String get _code {
    final colonIndex = message.indexOf(':');
    if (colonIndex == -1) return 'UNKNOWN';
    return message.substring(0, colonIndex).trim();
  }

  String get _detail {
    final colonIndex = message.indexOf(':');
    if (colonIndex == -1) return message;
    return message.substring(colonIndex + 1).trim();
  }

  @override
  Widget build(BuildContext context) {
    return switch (_code) {
      'PERMISSION_DENIED' => _PermissionDeniedError(detail: _detail),
      'BLUETOOTH_DISABLED' => _BluetoothDisabledError(),
      'BLE_SCAN_FAILED' => _GenericError(
        code: _code,
        detail: _detail,
        icon: Icons.bluetooth_disabled_rounded,
      ),
      _ => _GenericError(
        code: _code,
        detail: _detail,
        icon: Icons.error_outline_rounded,
      ),
    };
  }
}

// ============================================================
// Adapter status + progress
// ============================================================

class _AdapterStatusBar extends StatelessWidget {
  const _AdapterStatusBar({required this.snapshot});

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

class _ScanProgressBar extends StatelessWidget {
  const _ScanProgressBar({required this.snapshot});

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

// ============================================================
// Device list
// ============================================================

class _EmptyDeviceList extends StatelessWidget {
  const _EmptyDeviceList({required this.isScanning});

  final bool isScanning;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.devices_rounded,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              isScanning ? 'Searching for devices…' : 'No devices found',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              isScanning
                  ? 'Make sure nearby devices are discoverable.'
                  : 'Tap the scan button to try again.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceList extends StatelessWidget {
  const _DeviceList({required this.snapshot});

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
          _SectionHeader(
            label: 'Bluetooth Low Energy',
            count: ble.length,
            icon: Icons.bluetooth_searching_rounded,
            color: const Color(0xFF6200EA),
          ),
          const SizedBox(height: 8),
          ...ble.map((d) => _DeviceCard(device: d)),
        ],
        if (classic.isNotEmpty) ...[
          _SectionHeader(
            label: 'Classic Bluetooth',
            count: classic.length,
            icon: Icons.bluetooth_rounded,
            color: const Color(0xFF2979FF),
          ),
          const SizedBox(height: 8),
          ...classic.map((d) => _DeviceCard(device: d)),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(label, style: theme.textTheme.labelLarge?.copyWith(color: color)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: theme.textTheme.labelSmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// Device card
// ============================================================

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.device});

  final BluetoothDeviceModel device;

  Color _signalColor(String strength, ColorScheme scheme) => switch (strength) {
    'Excellent' => const Color(0xFF00C853),
    'Good' => const Color(0xFF64DD17),
    'Fair' => const Color(0xFFFF6D00),
    'Weak' => scheme.error,
    _ => scheme.onSurfaceVariant,
  };

  double _signalFill(String strength) => switch (strength) {
    'Excellent' => 1.0,
    'Good' => 0.75,
    'Fair' => 0.5,
    'Weak' => 0.25,
    _ => 0.0,
  };

  IconData _categoryIcon(String category) => switch (category) {
    'audio' => Icons.headphones_rounded,
    'computer' => Icons.computer_rounded,
    'phone' => Icons.smartphone_rounded,
    'wearable' => Icons.watch_rounded,
    'peripheral' => Icons.keyboard_rounded,
    'health' => Icons.monitor_heart_rounded,
    'imaging' => Icons.camera_alt_rounded,
    'networking' => Icons.router_rounded,
    'toy' => Icons.toys_rounded,
    'ble' => Icons.bluetooth_searching_rounded,
    _ => Icons.devices_rounded,
  };

  Future<void> _copyToClipboard(
    BuildContext context,
    String text,
    String label,
  ) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$label copied'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final signalColor = _signalColor(device.signalStrength, scheme);
    final signalFill = _signalFill(device.signalStrength);
    final isBonded = device.bondState == 'Bonded';
    final lastSeen = DateTime.fromMillisecondsSinceEpoch(device.timestamp);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onLongPress: () => _copyToClipboard(context, device.address, 'Address'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- Header row ----------------------------------------
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _categoryIcon(device.category),
                      color: scheme.onPrimaryContainer,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.name,
                          style: theme.textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        GestureDetector(
                          onTap: () => _copyToClipboard(
                            context,
                            device.address,
                            'Address',
                          ),
                          child: Row(
                            children: [
                              Text(
                                device.address,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontFamily: 'monospace',
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.copy_rounded,
                                size: 12,
                                color: scheme.onSurfaceVariant.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // RSSI + signal label
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${device.rssi} dBm',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: signalColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _SignalBar(fill: signalFill, color: signalColor),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // ---- Detail chips row ----------------------------------
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _InfoChip(
                    label: device.signalStrength,
                    color: signalColor,
                    icon: Icons.signal_cellular_alt_rounded,
                  ),
                  _InfoChip(
                    label: device.type,
                    color: scheme.primary,
                    icon: Icons.bluetooth_rounded,
                  ),
                  _InfoChip(
                    label: device.deviceClass,
                    color: scheme.secondary,
                    icon: _categoryIcon(device.category),
                  ),
                  if (isBonded)
                    _InfoChip(
                      label: 'Paired',
                      color: const Color(0xFF00C853),
                      icon: Icons.link_rounded,
                    )
                  else
                    _InfoChip(
                      label: device.bondState,
                      color: scheme.onSurfaceVariant,
                      icon: Icons.link_off_rounded,
                    ),
                ],
              ),

              const SizedBox(height: 10),

              // ---- Footer row: last seen timestamp -------------------
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 13,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Last seen ${_formatTime(lastSeen)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inSeconds < 10) return 'just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }
}

// ---- Signal strength bar -------------------------------------------

class _SignalBar extends StatelessWidget {
  const _SignalBar({required this.fill, required this.color});

  final double fill;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 6,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          value: fill,
          backgroundColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest,
          color: color,
          minHeight: 6,
        ),
      ),
    );
  }
}

// ---- Info chip -------------------------------------------------------

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Error bodies
// ============================================================

class _PermissionDeniedError extends StatelessWidget {
  const _PermissionDeniedError({required this.detail});

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
              onPressed: NativeChannel.openSettings,
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

class _BluetoothDisabledError extends StatelessWidget {
  const _BluetoothDisabledError();

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
                color: scheme.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bluetooth_disabled_rounded,
                size: 36,
                color: scheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Bluetooth is Turned Off',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Enable Bluetooth in your device settings, then try scanning again.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.read<BluetoothDiscoveryBloc>().add(
                const BluetoothScanStartRequested(),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GenericError extends StatelessWidget {
  const _GenericError({
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
