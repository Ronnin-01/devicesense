import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/theme.dart';
import '../../core/di/service_locator.dart';
import '../wifi/bloc/scan/wifi_scan_bloc.dart';
import '../wifi/bloc/scan/wifi_scan_event.dart';
import '../wifi/bloc/scan/wifi_scan_state.dart';
import '../wifi/models/wifi_network_model.dart';
import '../wifi/models/wifi_scan_snapshot.dart'; // Adjust import

class WifiScanPage extends StatelessWidget {
  const WifiScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WifiScanBloc>(
      create: (_) => sl<WifiScanBloc>()..add(const WifiScanStarted()),
      child: const _WifiScanView(),
    );
  }
}

class _WifiScanView extends StatefulWidget {
  const _WifiScanView();

  @override
  State<_WifiScanView> createState() => _WifiScanViewState();
}

class _WifiScanViewState extends State<_WifiScanView> {
  @override
  void deactivate() {
    // Stop scanning when exiting to free system broadcast receivers
    context.read<WifiScanBloc>().add(const WifiScanStopped());
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wi-Fi Radar Scan'),
        actions: [
          BlocBuilder<WifiScanBloc, WifiScanState>(
            builder: (context, state) {
              final isScanning =
                  state is WifiScanLoaded && state.snapshot.isScanning;

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton.filledTonal(
                  icon: isScanning
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Icon(Icons.sync_rounded),
                  onPressed: isScanning
                      ? null
                      : () => context.read<WifiScanBloc>().add(
                          const WifiScanStarted(),
                        ),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<WifiScanBloc, WifiScanState>(
        listener: (context, state) {
          if (state is WifiScanError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is WifiScanInitial || state is WifiScanLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Initiating Native Wi-Fi Scan...'),
                ],
              ),
            );
          }

          if (state is WifiScanLoaded) {
            final snapshot = state.snapshot;
            return Column(
              children: [
                // Top Metadata Header Card
                _buildScanMetadataCard(context, snapshot, colorScheme, theme),

                // Access Points List
                Expanded(
                  child: snapshot.networks.isEmpty
                      ? _buildEmptyState(theme)
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: snapshot.networks.length,
                          itemBuilder: (context, index) {
                            return _WifiAccessPointCard(
                              network: snapshot.networks[index],
                            );
                          },
                        ),
                ),
              ],
            );
          }

          if (state is WifiScanError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.signal_wifi_connected_no_internet_4_rounded,
                      size: 64,
                      color: colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Scan Failure',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try Again'),
                      onPressed: () => context.read<WifiScanBloc>().add(
                        const WifiScanStarted(),
                      ),
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

  Widget _buildScanMetadataCard(
    BuildContext context,
    WifiScanSnapshot snapshot,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final bool isThrottled = snapshot.fromCache ?? false;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isThrottled
            ? Colors.amber.shade50
            : colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: isThrottled
              ? Colors.amber.shade300
              : colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isThrottled ? Icons.timer_rounded : Icons.cell_tower_rounded,
                color: isThrottled
                    ? Colors.amber.shade900
                    : colorScheme.primary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isThrottled
                          ? 'OS Scan Throttled'
                          : 'Active Scanner Online',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isThrottled
                            ? Colors.amber.shade900
                            : colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      isThrottled
                          ? 'Showing cached results (Android limits scans to 4 per 2 min)'
                          : 'State: ${snapshot.wifiState} | Discovered ${snapshot.networks.length} APs',
                      style: TextStyle(
                        fontSize: 11,
                        color: isThrottled
                            ? Colors.amber.shade900
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${snapshot.lastUpdated.hour.toString().padLeft(2, '0')}:${snapshot.lastUpdated.minute.toString().padLeft(2, '0')}:${snapshot.lastUpdated.second.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          if (snapshot.scanError != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_rounded,
                    size: 16,
                    color: colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Warning: ${snapshot.scanError}',
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

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_find_rounded,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            'No Networks Discovered',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ensure Wi-Fi & Location services are enabled.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Detailed Access Point Tile Card (Includes ALL fields from WifiNetworkModel)
// =============================================================================
class _WifiAccessPointCard extends StatelessWidget {
  const _WifiAccessPointCard({required this.network});

  final WifiNetworkModel network;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isHidden = network.isHidden || network.ssid.isEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getSignalColor(network.signalLevel).withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getSignalIcon(network.signalLevel),
            color: _getSignalColor(network.signalLevel),
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                isHidden ? 'Hidden Access Point' : network.ssid,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  fontStyle: isHidden ? FontStyle.italic : FontStyle.normal,
                  color: isHidden ? colorScheme.outline : colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (network.isPasspoint)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Passpoint',
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: [
              Text(
                '${network.rssi} dBm (${network.signalStrength})',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              _BadgeTag(
                label: network.band,
                color: colorScheme.primaryContainer,
                textColor: colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 4),
              _BadgeTag(
                label: network.securityType,
                color: colorScheme.secondaryContainer,
                textColor: colorScheme.onSecondaryContainer,
              ),
            ],
          ),
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(AppTheme.radiusMedium),
                bottomRight: Radius.circular(AppTheme.radiusMedium),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Technical Specs',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                _SpecGridRow(label: 'BSSID (MAC)', value: network.bssid),
                _SpecGridRow(
                  label: 'Center Frequency',
                  value: '${network.frequencyMHz} MHz',
                ),
                _SpecGridRow(
                  label: 'Channel Number',
                  value: network.channel == -1
                      ? 'Unknown'
                      : 'Channel ${network.channel}',
                ),
                _SpecGridRow(
                  label: 'Channel Width',
                  value: network.channelWidthMHz.isEmpty
                      ? 'N/A'
                      : network.channelWidthMHz,
                ),
                _SpecGridRow(
                  label: 'Security Type',
                  value: network.securityType,
                ),
                _SpecGridRow(
                  label: 'Hidden Network',
                  value: network.isHidden ? 'Yes' : 'No',
                ),
                _SpecGridRow(
                  label: 'Passpoint (Hotspot 2.0)',
                  value: network.isPasspoint ? 'Yes' : 'No',
                ),
                if (network.operatorFriendlyName.isNotEmpty)
                  _SpecGridRow(
                    label: 'Carrier Operator',
                    value: network.operatorFriendlyName,
                  ),
                _SpecGridRow(
                  label: 'Discovered At',
                  value: DateTime.fromMillisecondsSinceEpoch(
                    network.timestamp,
                  ).toLocal().toString().split('.')[0],
                ),
                const SizedBox(height: 8),
                Text(
                  'Raw Capabilities',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Text(
                    network.capabilities.isEmpty
                        ? 'None'
                        : network.capabilities,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getSignalColor(int level) {
    switch (level) {
      case 4:
      case 3:
        return Colors.green;
      case 2:
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  IconData _getSignalIcon(int level) {
    switch (level) {
      case 4:
        return Icons.signal_wifi_4_bar_rounded;
      case 3:
        return Icons.network_wifi_3_bar_rounded;
      case 2:
        return Icons.network_wifi_2_bar_rounded;
      case 1:
        return Icons.network_wifi_1_bar_rounded;
      default:
        return Icons.signal_wifi_0_bar_rounded;
    }
  }
}

class _SpecGridRow extends StatelessWidget {
  const _SpecGridRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          SelectableText(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _BadgeTag extends StatelessWidget {
  const _BadgeTag({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
