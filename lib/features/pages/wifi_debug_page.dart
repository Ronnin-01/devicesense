import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:devicesense/core/di/service_locator.dart';
import 'package:devicesense/core/platform/native_channel.dart';
import '../wifi/bloc/capabilities/wifi_capabilities_bloc.dart';
import '../wifi/bloc/capabilities/wifi_capabilities_event.dart';
import '../wifi/bloc/capabilities/wifi_capabilities_state.dart';
import '../wifi/bloc/info/wifi_info_bloc.dart';
import '../wifi/bloc/info/wifi_info_event.dart';
import '../wifi/bloc/info/wifi_info_state.dart';
import '../wifi/bloc/scan/wifi_scan_bloc.dart';
import '../wifi/bloc/scan/wifi_scan_event.dart';
import '../wifi/bloc/scan/wifi_scan_state.dart';
import '../wifi/models/wifi_capabilities_model.dart';
import '../wifi/models/wifi_info_model.dart';
import '../wifi/models/wifi_network_model.dart';
import '../wifi/models/wifi_scan_snapshot.dart';

/// Debug-only page for testing the complete Wi-Fi Bloc pipeline.
///
/// It tests:
/// - Wi-Fi hardware capabilities
/// - Current connected network information
/// - Nearby Wi-Fi scanning
/// - Loading, empty, loaded, stopped, and error states
/// - Manual refresh/start/stop actions
///
/// Keep this page out of production navigation once testing is complete.
class WifiDebugPage extends StatelessWidget {
  const WifiDebugPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<WifiCapabilitiesBloc>(
          create: (_) =>
              sl<WifiCapabilitiesBloc>()
                ..add(const WifiCapabilitiesRequested()),
        ),
        BlocProvider<WifiInfoBloc>(
          create: (_) => sl<WifiInfoBloc>()..add(const WifiInfoRequested()),
        ),
        BlocProvider<WifiScanBloc>(
          create: (_) => sl<WifiScanBloc>()..add(const WifiScanStarted()),
        ),
      ],
      child: const _WifiDebugView(),
    );
  }
}

class _WifiDebugView extends StatelessWidget {
  const _WifiDebugView();

  void _refreshCapabilities(BuildContext context) {
    context.read<WifiCapabilitiesBloc>().add(const WifiCapabilitiesRequested());
  }

  void _refreshInfo(BuildContext context) {
    context.read<WifiInfoBloc>().add(const WifiInfoRequested());
  }

  void _startScan(BuildContext context) {
    context.read<WifiScanBloc>().add(const WifiScanStarted());
  }

  void _stopScan(BuildContext context) {
    context.read<WifiScanBloc>().add(const WifiScanStopped());
  }

  void _refreshAll(BuildContext context) {
    _refreshCapabilities(context);
    _refreshInfo(context);
    _startScan(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wi-Fi Debug'),
        actions: [
          IconButton(
            tooltip: 'Refresh everything',
            onPressed: () => _refreshAll(context),
            icon: const Icon(Icons.refresh_rounded),
          ),
          BlocBuilder<WifiScanBloc, WifiScanState>(
            buildWhen: (previous, current) {
              final previousScanning =
                  previous is WifiScanLoaded && previous.snapshot.isScanning;
              final currentScanning =
                  current is WifiScanLoaded && current.snapshot.isScanning;

              return previous.runtimeType != current.runtimeType ||
                  previousScanning != currentScanning;
            },
            builder: (context, state) {
              final isLoading = state is WifiScanLoading;
              final isScanning =
                  state is WifiScanLoaded && state.snapshot.isScanning;

              return IconButton(
                tooltip: isScanning ? 'Stop Wi-Fi scan' : 'Start Wi-Fi scan',
                onPressed: isLoading
                    ? null
                    : () {
                        if (isScanning) {
                          _stopScan(context);
                        } else {
                          _startScan(context);
                        }
                      },
                icon: isLoading
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        isScanning
                            ? Icons.stop_circle_outlined
                            : Icons.wifi_find_rounded,
                      ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshAll(context);
          await Future<void>.delayed(const Duration(milliseconds: 350));
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _DebugHeader(onRefreshAll: () => _refreshAll(context)),
            const SizedBox(height: 16),

            _SectionTitle(
              icon: Icons.memory_rounded,
              title: 'Wi-Fi Capabilities',
              actionTooltip: 'Refresh capabilities',
              onAction: () => _refreshCapabilities(context),
            ),
            const SizedBox(height: 8),
            BlocBuilder<WifiCapabilitiesBloc, WifiCapabilitiesState>(
              builder: (context, state) {
                if (state is WifiCapabilitiesInitial) {
                  return _ActionCard(
                    message: 'Capabilities have not been requested.',
                    buttonLabel: 'Load Capabilities',
                    icon: Icons.memory_rounded,
                    onPressed: () => _refreshCapabilities(context),
                  );
                }

                if (state is WifiCapabilitiesLoading) {
                  return const _LoadingCard(
                    message: 'Reading Wi-Fi hardware capabilities…',
                  );
                }

                if (state is WifiCapabilitiesError) {
                  return _ErrorCard(
                    title: 'Capabilities Error',
                    message: state.message,
                    onRetry: () => _refreshCapabilities(context),
                  );
                }

                if (state is WifiCapabilitiesLoaded) {
                  return _CapabilitiesCard(capabilities: state.capabilities);
                }

                return const _UnknownStateCard(
                  stateName: 'Unknown capabilities state',
                );
              },
            ),

            const SizedBox(height: 24),

            _SectionTitle(
              icon: Icons.wifi_rounded,
              title: 'Current Connection',
              actionTooltip: 'Refresh connection info',
              onAction: () => _refreshInfo(context),
            ),
            const SizedBox(height: 8),
            BlocBuilder<WifiInfoBloc, WifiInfoState>(
              builder: (context, state) {
                if (state is WifiInfoInitial) {
                  return _ActionCard(
                    message:
                        'Current Wi-Fi information has not been requested.',
                    buttonLabel: 'Load Wi-Fi Info',
                    icon: Icons.wifi_rounded,
                    onPressed: () => _refreshInfo(context),
                  );
                }

                if (state is WifiInfoLoading) {
                  return const _LoadingCard(
                    message: 'Reading current Wi-Fi connection…',
                  );
                }

                if (state is WifiInfoError) {
                  return _ErrorCard(
                    title: 'Wi-Fi Information Error',
                    message: state.message,
                    onRetry: () => _refreshInfo(context),
                    showSettings: true,
                  );
                }

                if (state is WifiInfoLoaded) {
                  return _WifiInfoCard(
                    info: state.info,
                    onRefresh: () => _refreshInfo(context),
                  );
                }

                return const _UnknownStateCard(
                  stateName: 'Unknown Wi-Fi info state',
                );
              },
            ),

            const SizedBox(height: 24),

            BlocBuilder<WifiScanBloc, WifiScanState>(
              builder: (context, state) {
                final isScanning =
                    state is WifiScanLoaded && state.snapshot.isScanning;

                return _SectionTitle(
                  icon: Icons.radar_rounded,
                  title: 'Nearby Networks',
                  actionTooltip: isScanning
                      ? 'Stop Wi-Fi scan'
                      : 'Start Wi-Fi scan',
                  actionIcon: isScanning
                      ? Icons.stop_circle_outlined
                      : Icons.wifi_find_rounded,
                  onAction: () {
                    if (isScanning) {
                      _stopScan(context);
                    } else {
                      _startScan(context);
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 8),

            BlocBuilder<WifiScanBloc, WifiScanState>(
              builder: (context, state) {
                if (state is WifiScanInitial) {
                  return _ActionCard(
                    message: 'The Wi-Fi scanner is stopped.',
                    buttonLabel: 'Start Scan',
                    icon: Icons.wifi_find_rounded,
                    onPressed: () => _startScan(context),
                  );
                }

                if (state is WifiScanLoading) {
                  return const _LoadingCard(
                    message: 'Starting nearby Wi-Fi scan…',
                  );
                }

                if (state is WifiScanError) {
                  return _ErrorCard(
                    title: 'Wi-Fi Scan Error',
                    message: state.message,
                    onRetry: () => _startScan(context),
                    onStop: () => _stopScan(context),
                    showSettings: true,
                  );
                }

                if (state is WifiScanLoaded) {
                  return _ScanResultSection(
                    snapshot: state.snapshot,
                    onStart: () => _startScan(context),
                    onStop: () => _stopScan(context),
                  );
                }

                return const _UnknownStateCard(
                  stateName: 'Unknown Wi-Fi scan state',
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DebugHeader extends StatelessWidget {
  const _DebugHeader({required this.onRefreshAll});

  final VoidCallback onRefreshAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.bug_report_rounded,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wi-Fi Bloc Test Console',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Capabilities, connection information, scan lifecycle, '
                    'results, and errors.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Refresh all',
              onPressed: onRefreshAll,
              icon: const Icon(Icons.sync_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.actionTooltip,
    required this.onAction,
    this.actionIcon = Icons.refresh_rounded,
  });

  final IconData icon;
  final String title;
  final String actionTooltip;
  final VoidCallback onAction;
  final IconData actionIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        IconButton(
          tooltip: actionTooltip,
          onPressed: onAction,
          icon: Icon(actionIcon),
        ),
      ],
    );
  }
}

class _CapabilitiesCard extends StatelessWidget {
  const _CapabilitiesCard({required this.capabilities});

  final WifiCapabilitiesModel capabilities;

  @override
  Widget build(BuildContext context) {
    return _DebugCard(
      children: [
        _ValueRow(
          label: 'Wi-Fi supported',
          value: _yesNo(capabilities.wifiSupported),
        ),
        _ValueRow(
          label: 'Wi-Fi enabled',
          value: _yesNo(capabilities.wifiEnabled),
        ),
        _ValueRow(label: 'Wi-Fi state', value: capabilities.wifiState),
        _ValueRow(
          label: 'Scan always available',
          value: _yesNo(capabilities.scanAlwaysAvailable),
        ),
        _ValueRow(
          label: '5 GHz supported',
          value: _yesNo(capabilities.is5GHzSupported),
        ),
        _ValueRow(
          label: '6 GHz supported',
          value: _yesNo(capabilities.is6GHzSupported),
        ),
        _ValueRow(
          label: 'Wi-Fi Direct supported',
          value: _yesNo(capabilities.isWifiDirectSupported),
        ),
        _ValueRow(
          label: 'WPA3 SAE supported',
          value: _yesNo(capabilities.isWpa3SaeSupported),
        ),
        _ValueRow(
          label: 'WPA3 Suite-B supported',
          value: _yesNo(capabilities.isWpa3SuiteBSupported),
        ),
        _ValueRow(
          label: 'Enhanced Open supported',
          value: _yesNo(capabilities.isEnhancedOpenSupported),
          showDivider: false,
        ),
      ],
    );
  }
}

class _WifiInfoCard extends StatelessWidget {
  const _WifiInfoCard({required this.info, required this.onRefresh});

  final WifiInfoModel info;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    if (!info.connected) {
      return _ActionCard(
        message: info.wifiEnabled
            ? 'Wi-Fi is enabled, but the device is not connected.'
            : 'Wi-Fi is currently disabled.',
        buttonLabel: 'Refresh Connection',
        icon: info.wifiEnabled
            ? Icons.wifi_off_rounded
            : Icons.signal_wifi_statusbar_connected_no_internet_4_rounded,
        onPressed: onRefresh,
      );
    }

    return _DebugCard(
      children: [
        _ValueRow(label: 'Connected', value: _yesNo(info.connected)),
        _ValueRow(label: 'Wi-Fi enabled', value: _yesNo(info.wifiEnabled)),
        _ValueRow(
          label: 'Location permission',
          value: _yesNo(info.hasLocationPermission),
        ),
        _ValueRow(
          label: 'Nearby Wi-Fi permission',
          value: _yesNo(info.hasNearbyWifiPermission),
        ),
        _ValueRow(label: 'SSID', value: _display(info.ssid)),
        _ValueRow(label: 'BSSID', value: _display(info.bssid)),
        _ValueRow(label: 'RSSI', value: '${info.rssi} dBm'),
        _ValueRow(label: 'Signal', value: info.signalStrength),
        _ValueRow(label: 'Signal level', value: '${info.signalLevel}/4'),
        _ValueRow(label: 'Link speed', value: '${info.linkSpeedMbps} Mbps'),
        _ValueRow(label: 'Frequency', value: '${info.frequencyMHz} MHz'),
        _ValueRow(label: 'Band', value: _display(info.band)),
        _ValueRow(label: 'IP address', value: _display(info.ipAddress)),
        _ValueRow(label: 'Network ID', value: '${info.networkId}'),
        _ValueRow(label: 'Hidden SSID', value: _yesNo(info.hiddenSsid)),
        _ValueRow(
          label: 'Device MAC',
          value: _display(info.macAddress),
          showDivider: false,
        ),
      ],
    );
  }
}

class _ScanResultSection extends StatelessWidget {
  const _ScanResultSection({
    required this.snapshot,
    required this.onStart,
    required this.onStop,
  });

  final WifiScanSnapshot snapshot;
  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ScanStatusCard(snapshot: snapshot, onStart: onStart, onStop: onStop),
        const SizedBox(height: 10),
        if (snapshot.networks.isEmpty)
          _ActionCard(
            message: snapshot.isScanning
                ? 'Scanning is active. Waiting for nearby networks…'
                : 'No nearby Wi-Fi networks were returned.',
            buttonLabel: snapshot.isScanning ? 'Stop Scan' : 'Scan Again',
            icon: snapshot.isScanning
                ? Icons.radar_rounded
                : Icons.wifi_find_rounded,
            onPressed: snapshot.isScanning ? onStop : onStart,
          )
        else
          ...snapshot.networks.map(
            (network) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _NetworkCard(network: network),
            ),
          ),
      ],
    );
  }
}

class _ScanStatusCard extends StatelessWidget {
  const _ScanStatusCard({
    required this.snapshot,
    required this.onStart,
    required this.onStop,
  });

  final WifiScanSnapshot snapshot;
  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  snapshot.isScanning
                      ? Icons.radar_rounded
                      : Icons.wifi_rounded,
                  color: snapshot.isScanning
                      ? scheme.primary
                      : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    snapshot.isScanning ? 'Scanning' : 'Scan stopped',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: snapshot.isScanning ? onStop : onStart,
                  icon: Icon(
                    snapshot.isScanning
                        ? Icons.stop_rounded
                        : Icons.play_arrow_rounded,
                  ),
                  label: Text(snapshot.isScanning ? 'Stop' : 'Start'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ValueRow(label: 'Wi-Fi state', value: snapshot.wifiState),
            _ValueRow(label: 'Networks', value: '${snapshot.networks.length}'),
            _ValueRow(
              label: 'From cache',
              value: snapshot.fromCache == null
                  ? 'Unknown'
                  : _yesNo(snapshot.fromCache!),
            ),
            _ValueRow(
              label: 'Last updated',
              value: snapshot.lastUpdated.toIso8601String(),
              showDivider: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _NetworkCard extends StatelessWidget {
  const _NetworkCard({required this.network});

  final WifiNetworkModel network;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final displayName = network.ssid.trim().isEmpty
        ? '<Hidden network>'
        : network.ssid;

    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          child: Icon(_wifiIcon(network.signalLevel)),
        ),
        title: Text(displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${network.rssi} dBm • ${network.band} • ${network.securityType}',
        ),
        trailing: _SignalBadge(
          level: network.signalLevel,
          label: network.signalStrength,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(),
          _ValueRow(label: 'BSSID', value: network.bssid),
          _ValueRow(label: 'RSSI', value: '${network.rssi} dBm'),
          _ValueRow(label: 'Signal', value: network.signalStrength),
          _ValueRow(label: 'Signal level', value: '${network.signalLevel}/4'),
          _ValueRow(label: 'Frequency', value: '${network.frequencyMHz} MHz'),
          _ValueRow(label: 'Band', value: network.band),
          _ValueRow(label: 'Channel', value: '${network.channel}'),
          _ValueRow(
            label: 'Channel width',
            value: _display(network.channelWidthMHz),
          ),
          _ValueRow(label: 'Security', value: network.securityType),
          _ValueRow(label: 'Hidden', value: _yesNo(network.isHidden)),
          _ValueRow(label: 'Passpoint', value: _yesNo(network.isPasspoint)),
          _ValueRow(
            label: 'Operator name',
            value: _display(network.operatorFriendlyName),
          ),
          _ValueRow(
            label: 'Timestamp',
            value: network.timestamp == 0
                ? 'Unknown'
                : DateTime.fromMillisecondsSinceEpoch(
                    network.timestamp,
                  ).toIso8601String(),
          ),
          _ValueRow(
            label: 'Capabilities',
            value: _display(network.capabilities),
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class _SignalBadge extends StatelessWidget {
  const _SignalBadge({required this.level, required this.label});

  final int level;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$level/4',
          style: TextStyle(
            color: scheme.onPrimaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _DebugCard extends StatelessWidget {
  const _DebugCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(children: children),
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 6,
                child: SelectableText(
                  value,
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.message,
    required this.buttonLabel,
    required this.icon,
    required this.onPressed,
  });

  final String message;
  final String buttonLabel;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 38),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.title,
    required this.message,
    required this.onRetry,
    this.onStop,
    this.showSettings = false,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;
  final VoidCallback? onStop;
  final bool showSettings;

  Future<void> _openSettings(BuildContext context) async {
    try {
      await NativeChannel.openAppSettings();
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Unable to open app settings: $error')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 36,
              color: scheme.onErrorContainer,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: scheme.onErrorContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
                if (onStop != null)
                  OutlinedButton.icon(
                    onPressed: onStop,
                    icon: const Icon(Icons.stop_rounded),
                    label: const Text('Stop'),
                  ),
                if (showSettings)
                  OutlinedButton.icon(
                    onPressed: () => _openSettings(context),
                    icon: const Icon(Icons.settings_rounded),
                    label: const Text('App Settings'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UnknownStateCard extends StatelessWidget {
  const _UnknownStateCard({required this.stateName});

  final String stateName;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.help_outline_rounded),
            const SizedBox(width: 12),
            Expanded(child: Text(stateName)),
          ],
        ),
      ),
    );
  }
}

String _yesNo(bool value) => value ? 'Yes' : 'No';

String _display(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? 'Not available' : trimmed;
}

IconData _wifiIcon(int level) {
  if (level >= 4) return Icons.signal_wifi_4_bar_rounded;
  if (level == 3) return Icons.network_wifi_3_bar_rounded;
  if (level == 2) return Icons.network_wifi_2_bar_rounded;
  if (level == 1) return Icons.network_wifi_1_bar_rounded;
  return Icons.signal_wifi_0_bar_rounded;
}
