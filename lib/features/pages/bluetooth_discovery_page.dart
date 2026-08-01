import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../battery_info/bloc/bluetooth_discovery_bloc.dart';
import '../battery_info/bloc/bluetooth_discovery_event.dart';
import '../battery_info/bloc/bluetooth_discovery_state.dart';
import '../battery_info/models/bluetooth_device_model.dart';

class BluetoothDebugPage extends StatefulWidget {
  const BluetoothDebugPage({super.key});

  @override
  State<BluetoothDebugPage> createState() => _BluetoothDebugPageState();
}

class _BluetoothDebugPageState extends State<BluetoothDebugPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bluetooth Debug")),
      body: BlocBuilder<BluetoothDiscoveryBloc, BluetoothDiscoveryState>(
        builder: (context, state) {
          print("UI BUILD -> ${state.runtimeType}");
          if (state is BluetoothDiscoveryLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is BluetoothDiscoveryError) {
            return Center(child: Text(state.message));
          }

          if (state is! BluetoothDiscoveryLoaded) {
            return const SizedBox();
          }
          print("UI DEVICES -> ${state.devices.length}");

          return Column(
            children: [
              _InfoTile(title: "Adapter", value: state.adapterState),
              _InfoTile(
                title: "Scanning",
                value: state.isScanning ? "YES" : "NO",
              ),
              _InfoTile(
                title: "Devices",
                value: state.devices.length.toString(),
              ),
              _InfoTile(
                title: "Last Update",
                value: state.lastUpdated.toString(),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: state.devices.length,
                  itemBuilder: (context, index) {
                    final BluetoothDeviceModel device = state.devices[index];

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(device.rssi.toString()),
                      ),
                      title: Text(device.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(device.address),
                          Text(device.type),
                          Text(device.deviceClass),
                          Text(device.bondState),
                        ],
                      ),
                      trailing: Text("${device.rssi} dBm"),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(title),
      trailing: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
