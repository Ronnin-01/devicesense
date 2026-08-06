import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/service_locator.dart';
import '../bluetooth_info/bloc/bluetooth_info_bloc.dart';
import '../bluetooth_info/bloc/bluetooth_info_event.dart';
import '../bluetooth_info/bloc/bluetooth_info_state.dart';
import '../shared/reusable_widgets.dart';

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

  bool _isSupported(Map<String, dynamic> data, String key) {
    return data[key] == true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Hardware'),
        actions: [
          IconButton.filledTonal(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<BluetoothInfoBloc>().add(
              const BluetoothInfoRequested(),
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bluetooth_disabled_rounded,
                    size: 56,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text("Error Loading Data", style: theme.textTheme.titleLarge),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(state.message, textAlign: TextAlign.center),
                  ),
                  FilledButton(
                    onPressed: () => context.read<BluetoothInfoBloc>().add(
                      const BluetoothInfoRequested(),
                    ),
                    child: const Text("Retry"),
                  ),
                ],
              ),
            );
          }

          final data = (state as BluetoothInfoLoaded).data; //[cite: 15]

          return RefreshIndicator(
            onRefresh: () async {
              context.read<BluetoothInfoBloc>().add(
                const BluetoothInfoRequested(),
              );
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Navigation Hero Banners
                Row(
                  children: [
                    Expanded(
                      child: _HeroNavigationCard(
                        title: 'Scanner',
                        icon: Icons.radar_rounded,
                        color: theme.colorScheme.primary,
                        onTap: () => context.push(
                          '/bluetooth/bt-discovery',
                        ), //[cite: 15]
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _HeroNavigationCard(
                        title: 'Paired Devices',
                        icon: Icons.devices_other_rounded,
                        color: theme.colorScheme.tertiary,
                        onTap: () => context.push(
                          '/bluetooth/paired-devices',
                        ), //[cite: 15]
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                ModernSectionCard(
                  title: "Adapter Identity",
                  icon: Icons.bluetooth_rounded,
                  children: [
                    Row(
                      children: [
                        Icon(
                          data["enabled"] == true
                              ? Icons.power_rounded
                              : Icons.power_off_rounded,
                          color: data["enabled"] == true
                              ? Colors.green
                              : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          data["enabled"] == true
                              ? "Adapter Powered ON"
                              : "Adapter Powered OFF", //[cite: 15]
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        ModernDetailTile(
                          width: 160,
                          label: "Adapter Name",
                          value: data["adapterName"] ?? "Unknown", //[cite: 15]
                          icon: Icons.badge_rounded,
                        ),
                        ModernDetailTile(
                          width: 160,
                          label: "MAC Address",
                          value:
                              data["adapterAddress"] ?? "Unknown", //[cite: 15]
                          icon: Icons.fingerprint_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                ModernSectionCard(
                  title: "Low Energy (BLE) Features",
                  icon: Icons.battery_charging_full_rounded,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        ModernDetailTile(
                          width: 160,
                          label: "BLE Support",
                          value: _isSupported(data, "bleSupported")
                              ? "Supported"
                              : "Unsupported", //[cite: 15]
                          icon: Icons.bluetooth_connected_rounded,
                          isSupported: _isSupported(data, "bleSupported"),
                        ),
                        ModernDetailTile(
                          width: 160,
                          label: "Multiple Advertisements",
                          value: _isSupported(data, "multipleAdvertisement")
                              ? "Supported"
                              : "Unsupported", //[cite: 15]
                          icon: Icons.campaign_rounded,
                          isSupported: _isSupported(
                            data,
                            "multipleAdvertisement",
                          ),
                        ),
                        ModernDetailTile(
                          width: 160,
                          label: "Offloaded Filtering",
                          value: _isSupported(data, "offloadedFiltering")
                              ? "Supported"
                              : "Unsupported", //[cite: 15]
                          icon: Icons.filter_alt_rounded,
                          isSupported: _isSupported(data, "offloadedFiltering"),
                        ),
                        ModernDetailTile(
                          width: 160,
                          label: "Scan Batching",
                          value: _isSupported(data, "offloadedBatching")
                              ? "Supported"
                              : "Unsupported", //[cite: 15]
                          icon: Icons.dynamic_feed_rounded,
                          isSupported: _isSupported(data, "offloadedBatching"),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                ModernSectionCard(
                  title: "Advanced PHY & Audio",
                  icon: Icons.memory_rounded,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        ModernDetailTile(
                          width: 160,
                          label: "LE 2M PHY",
                          value: _isSupported(data, "le2MPhy")
                              ? "Supported"
                              : "Unsupported", //[cite: 15]
                          icon: Icons.speed_rounded,
                          isSupported: _isSupported(data, "le2MPhy"),
                        ),
                        ModernDetailTile(
                          width: 160,
                          label: "LE Coded PHY",
                          value: _isSupported(data, "leCodedPhy")
                              ? "Supported"
                              : "Unsupported", //[cite: 15]
                          icon: Icons.route_rounded,
                          isSupported: _isSupported(data, "leCodedPhy"),
                        ),
                        ModernDetailTile(
                          width: 160,
                          label: "Extended Advertising",
                          value: _isSupported(data, "extendedAdvertising")
                              ? "Supported"
                              : "Unsupported", //[cite: 15]
                          icon: Icons.settings_input_antenna_rounded,
                          isSupported: _isSupported(
                            data,
                            "extendedAdvertising",
                          ),
                        ),
                        ModernDetailTile(
                          width: 160,
                          label: "LE Audio",
                          value: _isSupported(data, "leAudio")
                              ? "Supported"
                              : "Unsupported", //[cite: 15]
                          icon: Icons.headphones_rounded,
                          isSupported: _isSupported(data, "leAudio"),
                        ),
                      ],
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

class _HeroNavigationCard extends StatelessWidget {
  const _HeroNavigationCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
