import 'package:devicesense/features/bluetooth_info/bloc/bluetooth_info_bloc.dart';
import 'package:devicesense/features/bluetooth_info/bloc/bluetooth_info_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/service_locator.dart';
import '../../core/permissions/permission_type.dart';
import '../bluetooth_info/bloc/bluetooth_info_event.dart';
import '../bluetooth_info/models/bluetooth_device_model.dart';
import '../permissions/bloc/permission_bloc.dart';
import '../permissions/bloc/permission_event.dart';
import '../shared/reusable_widgets.dart';

class PairedDevicesPage extends StatelessWidget {
  const PairedDevicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              sl<BluetoothInfoBloc>()..add(const BluetoothPairedDevices()),
        ), //[cite: 16]
        BlocProvider(create: (_) => sl<PermissionBloc>()), //[cite: 16]
      ],
      child: const _PairedDevicesView(),
    );
  }
}

class _PairedDevicesView extends StatelessWidget {
  const _PairedDevicesView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Paired Devices"),
        actions: [
          IconButton.filledTonal(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<BluetoothInfoBloc>().add(
              const BluetoothPairedDevices(),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<BluetoothInfoBloc, BluetoothInfoState>(
        builder: (context, state) {
          if (state is BluetoothInfoInitial || state is BluetoothInfoLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is BluetoothInfoError) {
            return Center(child: Text(state.message));
          }

          final data = (state as BTDevicesLoaded).data; //[cite: 16]
          final supported = data["supported"] == true; //[cite: 16]
          final permissionRequired =
              data["permissionRequired"] == true; //[cite: 16]
          final bluetoothEnabled =
              data["bluetoothEnabled"] != false; //[cite: 16]

          final rawDevices = (data["devices"] as List<dynamic>? ?? [])
              .cast<Map<dynamic, dynamic>>();

          if (!supported) {
            return _WarningStateView(
              icon: Icons.bluetooth_disabled_rounded,
              title: "Unsupported",
              message: "Bluetooth is not supported on this device.",
            ); //[cite: 16]
          }
          if (permissionRequired) {
            return _PermissionRequestView(
              onGrant: () => context.read<PermissionBloc>().add(
                const PermissionRequested(PermissionType.bluetoothConnect),
              ), //[cite: 16]
            );
          }
          if (!bluetoothEnabled) {
            return _WarningStateView(
              icon: Icons.bluetooth_disabled_rounded,
              title: "Bluetooth is Off",
              message: "Please enable Bluetooth to view bonded devices.",
            ); //[cite: 16]
          }

          if (rawDevices.isEmpty) {
            return _WarningStateView(
              icon: Icons.link_off_rounded,
              title: "No Paired Devices",
              message: "Pair a device from your Android Settings first.",
            ); //[cite: 16]
          }

          return RefreshIndicator(
            onRefresh: () async => context.read<BluetoothInfoBloc>().add(
              const BluetoothPairedDevices(),
            ),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rawDevices.length + 1, // +1 for the header card
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: EdgeInsets.fromLTRB(0, 0, 0, 16.0),
                    child: ModernSectionCard(
                      title: "Bonded Record",
                      icon: Icons.memory_rounded,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      children: [
                        Text(
                          "Found ${rawDevices.length} previously paired devices saved in the adapter's memory.",
                          style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Convert Map to Model for our reusable card
                final devMap = rawDevices[index - 1].map(
                  (key, value) => MapEntry(key.toString(), value),
                );
                final model = BluetoothDeviceModel.fromJson(
                  Map<String, dynamic>.from(devMap),
                );
                return BluetoothDeviceCard(device: model);
              },
            ),
          );
        },
      ),
    );
  }
}

class _WarningStateView extends StatelessWidget {
  const _WarningStateView({
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionRequestView extends StatelessWidget {
  const _PermissionRequestView({required this.onGrant});
  final VoidCallback onGrant;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ModernSectionCard(
          title: "Permission Required",
          icon: Icons.security_rounded,
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          children: [
            const Text(
              "Bluetooth Connect permission is required to view paired devices on Android 12+.",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onGrant,
              icon: const Icon(Icons.check_circle_rounded),
              label: const Text("Grant Permission"),
            ),
          ],
        ),
      ),
    );
  }
}
