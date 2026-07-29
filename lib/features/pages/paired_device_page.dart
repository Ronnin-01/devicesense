import 'package:devicesense/features/bluetooth_info/bloc/bluetooth_info_bloc.dart';
import 'package:devicesense/features/bluetooth_info/bloc/bluetooth_info_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../core/di/service_locator.dart';
import '../../core/permissions/permission_type.dart';
import '../bluetooth_info/bloc/bluetooth_info_event.dart';
import '../permissions/bloc/permission_bloc.dart';
import '../permissions/bloc/permission_event.dart';
import '../shared/bluetooth_summary_card.dart';
import '../shared/paired_device_card.dart';
import '../shared/paired_device_detail_sheet.dart';

class PairedDevicesPage extends StatelessWidget {
  const PairedDevicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              sl<BluetoothInfoBloc>()..add(const BluetoothPairedDevices()),
        ),
        BlocProvider(create: (_) => sl<PermissionBloc>()),
      ],
      child: const _PairedDevicesView(),
    );
  }
}

class _PairedDevicesView extends StatelessWidget {
  const _PairedDevicesView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Paired Bluetooth Devices")),
      body: BlocBuilder<BluetoothInfoBloc, BluetoothInfoState>(
        builder: (context, state) {
          if (state is BluetoothInfoInitial || state is BluetoothInfoLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is BluetoothInfoError) {
            return _ErrorView(message: state.message);
          }

          final data = (state as BTDevicesLoaded).data;
          Logger().e(data);
          final supported = data["supported"] == true;
          final permissionRequired = data["permissionRequired"] == true;
          final bluetoothEnabled = data["bluetoothEnabled"] != false;

          final devices = (data["devices"] as List<dynamic>? ?? [])
              .cast<Map<dynamic, dynamic>>()
              .map(
                (e) => e.map((key, value) => MapEntry(key.toString(), value)),
              )
              .toList();

          if (!supported) {
            return const _UnsupportedView();
          }

          if (permissionRequired) {
            return _PermissionView(
              onGrant: () {
                context.read<PermissionBloc>().add(
                  const PermissionRequested(PermissionType.bluetoothConnect),
                );
              },
            );
          }

          if (!bluetoothEnabled) {
            return const _BluetoothDisabledView();
          }

          if (devices.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<BluetoothInfoBloc>().add(
                  const BluetoothPairedDevices(),
                );
              },
              child: ListView(
                children: const [SizedBox(height: 120), _EmptyView()],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<BluetoothInfoBloc>().add(
                const BluetoothPairedDevices(),
              );
            },
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                BluetoothSummaryCard(
                  bluetoothEnabled: bluetoothEnabled,
                  permissionGranted: !permissionRequired,
                  deviceCount: devices.length,
                  lastUpdated: DateTime.now(),
                ),

                const SizedBox(height: 24),

                Text(
                  "Paired Devices",
                  style: Theme.of(context).textTheme.titleLarge,
                ),

                const SizedBox(height: 14),

                ...devices.map(
                  (device) => PairedDeviceCard(
                    device: device,
                    onTap: () {
                      PairedDeviceDetailsSheet.show(context, device);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Icon(Icons.devices_other_rounded, size: 72),
          const SizedBox(height: 18),
          Text(
            "No paired Bluetooth devices found.",
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Pair a Bluetooth device from Android Settings and refresh this page.",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _PermissionView extends StatelessWidget {
  const _PermissionView({required this.onGrant});

  final VoidCallback onGrant;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 70),
            const SizedBox(height: 18),
            Text(
              "Bluetooth permission is required to view paired devices.",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onGrant,
              icon: const Icon(Icons.bluetooth),
              label: const Text("Grant Permission"),
            ),
          ],
        ),
      ),
    );
  }
}

class _BluetoothDisabledView extends StatelessWidget {
  const _BluetoothDisabledView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bluetooth_disabled, size: 70),
            SizedBox(height: 18),
            Text(
              "Bluetooth is currently turned off.",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _UnsupportedView extends StatelessWidget {
  const _UnsupportedView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bluetooth_disabled, size: 64),
            SizedBox(height: 16),
            Text(
              "Bluetooth is not supported on this device.",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
