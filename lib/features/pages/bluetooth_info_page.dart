import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/service_locator.dart';
import '../bluetooth_info/bloc/bluetooth_info_bloc.dart';
import '../bluetooth_info/bloc/bluetooth_info_event.dart';
import '../bluetooth_info/bloc/bluetooth_info_state.dart';
import '../shared/widgets.dart';

class BluetoothInfoPage extends StatelessWidget {
  const BluetoothInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<BluetoothInfoBloc>()..add(const BluetoothInfoRequested()),
      child: const _BluetoothInfoView(),
    );
  }
}

class _BluetoothInfoView extends StatelessWidget {
  const _BluetoothInfoView();

  String field(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null) return "Unknown";
    return value.toString();
  }

  String capability(Map<String, dynamic> data, String key) {
    final value = data[key];

    if (value == null) return "Unknown";

    if (value is bool) {
      return value ? "Supported" : "Not Supported";
    }

    return value.toString();
  }

  String bluetoothState(Map<String, dynamic> data) {
    final enabled = data["enabled"];

    if (enabled == true) {
      return "Enabled";
    }

    return "Disabled";
  }

  IconData capabilityIcon(bool value) {
    return value ? Icons.check_circle : Icons.cancel;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Information'),
        actions: [
          IconButton(
            icon: const Icon(Icons.devices_other_rounded),
            tooltip: 'Paired devices',
            onPressed: () => context.push('/bluetooth/paired-devices'),
          ),
          IconButton(
            icon: const Icon(Icons.bluetooth_searching_rounded),
            tooltip: ' BT discovery',
            onPressed: () => context.push('/bluetooth/bt-discovery'),
          ),
        ],
      ),
      body: BlocBuilder<BluetoothInfoBloc, BluetoothInfoState>(
        builder: (context, state) {
          if (state is BluetoothInfoLoading || state is BluetoothInfoInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is BluetoothInfoError) {
            final theme = Theme.of(context);

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bluetooth_disabled_rounded,
                      size: 42,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Couldn't load Bluetooth information",
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        context.read<BluetoothInfoBloc>().add(
                          const BluetoothInfoRequested(),
                        );
                      },
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = (state as BluetoothInfoLoaded).data;

          return RefreshIndicator(
            onRefresh: () async {
              context.read<BluetoothInfoBloc>().add(
                const BluetoothInfoRequested(),
              );

              await context.read<BluetoothInfoBloc>().stream.firstWhere(
                (state) => state is! BluetoothInfoLoading,
              );
            },
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                SectionCard(
                  title: "Bluetooth Adapter",
                  icon: Icons.bluetooth,
                  children: [
                    ExpandableInfoTile(
                      title: "Bluetooth",

                      value: capability(data, "supported"),
                    ),
                    const Divider(),
                    ExpandableInfoTile(
                      title: "State",
                      value: bluetoothState(data),
                    ),
                    const Divider(),
                    ExpandableInfoTile(
                      title: "Adapter Name",
                      value: field(data, "adapterName"),
                    ),
                    const Divider(),
                    ExpandableInfoTile(
                      title: "Adapter Address",
                      value: field(data, "adapterAddress"),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                SectionCard(
                  title: "Bluetooth Low Energy",
                  icon: Icons.settings_bluetooth,
                  children: [
                    ExpandableInfoTile(
                      title: "BLE Support",
                      value: capability(data, "bleSupported"),
                    ),
                    const Divider(),
                    ExpandableInfoTile(
                      title: "Multiple Advertisement",
                      value: capability(data, "multipleAdvertisement"),
                    ),
                    const Divider(),
                    ExpandableInfoTile(
                      title: "Offloaded Filtering",
                      value: capability(data, "offloadedFiltering"),
                    ),
                    const Divider(),
                    ExpandableInfoTile(
                      title: "Offloaded Scan Batching",
                      value: capability(data, "offloadedBatching"),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                SectionCard(
                  title: "Advanced Hardware",
                  icon: Icons.memory_outlined,
                  children: [
                    ExpandableInfoTile(
                      title: "LE 2M PHY",
                      value: capability(data, "le2MPhy"),
                    ),
                    const Divider(),
                    ExpandableInfoTile(
                      title: "LE Coded PHY",
                      value: capability(data, "leCodedPhy"),
                    ),
                    const Divider(),
                    ExpandableInfoTile(
                      title: "Extended Advertising",
                      value: capability(data, "extendedAdvertising"),
                    ),
                    const Divider(),
                    ExpandableInfoTile(
                      title: "LE Audio",
                      value: capability(data, "leAudio"),
                      description:
                          "Bluetooth LE Audio is part of the Bluetooth 5.2 specification. "
                          "It provides better sound quality while consuming less power and "
                          "enables features such as Auracast and Multi-Stream Audio.",
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
