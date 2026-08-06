import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/service_locator.dart';
import '../bluetooth_info/bloc/bluetooth_discovery_bloc.dart';
import '../bluetooth_info/bloc/bluetooth_discovery_event.dart';
import '../bluetooth_info/bloc/bluetooth_discovery_state.dart';
import '../bluetooth_info/models/bluetooth_discovery_snapshot.dart';
import '../shared/reusable_widgets.dart';

// ============================================================
// Route-level widget — provides the Bloc, nothing else
// ============================================================

class BluetoothDiscoveryPage extends StatelessWidget {
  const BluetoothDiscoveryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<BluetoothDiscoveryBloc>()
            ..add(const BluetoothDiscoveryStarted()), //[cite: 14]
      child: const _DiscoveryView(),
    );
  }
}

class _DiscoveryView extends StatefulWidget {
  const _DiscoveryView();

  @override
  State<_DiscoveryView> createState() => _DiscoveryViewState();
}

class _DiscoveryViewState extends State<_DiscoveryView> {
  @override
  void deactivate() {
    // Clean up scan on exit[cite: 14]
    context.read<BluetoothDiscoveryBloc>().add(
      const BluetoothScanStopRequested(),
    );
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live BT Discovery'),
        actions: [
          BlocBuilder<BluetoothDiscoveryBloc, BluetoothDiscoveryState>(
            builder: (context, state) {
              final isScanning =
                  state is BluetoothDiscoveryLoaded &&
                  state.isScanning; //[cite: 14]

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton.filledTonal(
                  icon: isScanning
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Icon(Icons.radar_rounded),
                  onPressed: () {
                    context.read<BluetoothDiscoveryBloc>().add(
                      isScanning
                          ? const BluetoothScanStopRequested()
                          : const BluetoothScanStartRequested(), //[cite: 14]
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<BluetoothDiscoveryBloc, BluetoothDiscoveryState>(
        builder: (context, state) {
          if (state is BluetoothDiscoveryInitial ||
              state is BluetoothDiscoveryLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Initializing Adapter...'),
                ],
              ),
            );
          }

          if (state is BluetoothDiscoveryLoaded) {
            final snapshot = state.snapshot; //[cite: 14]
            return Column(
              children: [
                _buildLiveScanHeader(context, snapshot),

                Expanded(
                  child: snapshot.devices.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.radar_rounded,
                                size: 64,
                                color: theme.colorScheme.outline,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "No Devices Found Yet",
                                style: theme.textTheme.titleMedium,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: snapshot.devices.length,
                          itemBuilder: (context, index) {
                            return BluetoothDeviceCard(
                              device: snapshot.devices[index],
                            );
                          },
                        ),
                ),
              ],
            );
          }

          if (state is BluetoothDiscoveryError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ModernSectionCard(
                  title: "Discovery Failed",
                  icon: Icons.error_rounded,
                  backgroundColor: theme.colorScheme.errorContainer,
                  children: [
                    Text(
                      state.message,
                      style: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ), //[cite: 14]
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<BluetoothDiscoveryBloc>().add(
                            const BluetoothScanStartRequested(),
                          ), //[cite: 14]
                      child: const Text("Retry Scan"),
                    ),
                  ],
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLiveScanHeader(
    BuildContext context,
    BluetoothDiscoverySnapshot snapshot,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Progress calculation[cite: 18]
    final progressElapsed = snapshot.scanProgressElapsed ?? 0;
    final progressTotal = snapshot.scanProgressTotal ?? 12;
    final progressRatio = progressTotal > 0
        ? (progressElapsed / progressTotal)
        : 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: snapshot.isScanning
              ? colorScheme.primary
              : colorScheme.outlineVariant,
        ), //[cite: 18]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                snapshot.isScanning
                    ? Icons.bluetooth_searching_rounded
                    : Icons.bluetooth_rounded,
                color: colorScheme.primary,
              ), //[cite: 18]
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  snapshot.isScanning
                      ? 'Scanning for Devices...'
                      : 'Discovery Paused', //[cite: 18]
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              StatusBadgeTag(
                label: 'Found ${snapshot.devices.length}', //[cite: 18]
                color: colorScheme.primary,
              ),
            ],
          ),

          if (snapshot.isScanning) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progressRatio, //[cite: 18]
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${progressElapsed}s / ${progressTotal}s',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ), //[cite: 18]
              ],
            ),
          ],

          if (snapshot.scanError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_rounded,
                    size: 16,
                    color: colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Error: ${snapshot.scanError}', //[cite: 18]
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onErrorContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
