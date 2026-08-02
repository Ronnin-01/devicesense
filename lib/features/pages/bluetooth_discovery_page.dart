import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/service_locator.dart';
import '../bluetooth_info/bloc/bluetooth_discovery_bloc.dart';
import '../bluetooth_info/bloc/bluetooth_discovery_event.dart';
import '../bluetooth_info/bloc/bluetooth_discovery_state.dart';
import '../bluetooth_info/models/bluetooth_discovery_snapshot.dart';
import '../shared/bluetooth_discovery/adapter_statusbar.dart';
import '../shared/bluetooth_discovery/bluetooth_disable_error.dart';
import '../shared/bluetooth_discovery/device_list.dart';
import '../shared/bluetooth_discovery/empty_device_list.dart';
import '../shared/bluetooth_discovery/generic_error.dart';
import '../shared/bluetooth_discovery/permission_denied_error.dart';
import '../shared/bluetooth_discovery/scan_progressbar.dart';

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
        AdapterStatusBar(snapshot: snapshot),
        if (snapshot.isScanning) ScanProgressBar(snapshot: snapshot),
        Expanded(
          child: snapshot.devices.isEmpty
              ? EmptyDeviceList(isScanning: snapshot.isScanning)
              : DeviceList(snapshot: snapshot),
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
      'PERMISSION_DENIED' => PermissionDeniedError(detail: _detail),
      'BLUETOOTH_DISABLED' => BluetoothDisabledError(),
      'BLE_SCAN_FAILED' => GenericError(
        code: _code,
        detail: _detail,
        icon: Icons.bluetooth_disabled_rounded,
      ),
      _ => GenericError(
        code: _code,
        detail: _detail,
        icon: Icons.error_outline_rounded,
      ),
    };
  }
}
