import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/di/service_locator.dart';
import '../wifi/bloc/capabilities/wifi_capabilities_bloc.dart';
import '../wifi/bloc/capabilities/wifi_capabilities_event.dart';
import '../wifi/bloc/capabilities/wifi_capabilities_state.dart';
import '../wifi/bloc/info/wifi_info_bloc.dart';
import '../wifi/bloc/info/wifi_info_event.dart';
import '../wifi/bloc/info/wifi_info_state.dart';
import '../wifi/models/wifi_capabilities_model.dart';
import '../wifi/models/wifi_info_model.dart'; // Adjust import

class WifiCapabilitiesPage extends StatelessWidget {
  const WifiCapabilitiesPage({super.key});

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
      ],
      child: const _WifiCapabilitiesView(),
    );
  }
}

class _WifiCapabilitiesView extends StatelessWidget {
  const _WifiCapabilitiesView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wi-Fi & Capabilities'),
        actions: [
          IconButton.filledTonal(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () {
              context.read<WifiCapabilitiesBloc>().add(
                const WifiCapabilitiesRequested(),
              );
              context.read<WifiInfoBloc>().add(const WifiInfoRequested());
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<WifiCapabilitiesBloc>().add(
            const WifiCapabilitiesRequested(),
          );
          context.read<WifiInfoBloc>().add(const WifiInfoRequested());
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Quick Navigation Hero Banner
            _buildScanHeroBanner(context, colorScheme, theme),
            const SizedBox(height: 20),

            // Active Connection Section
            _buildSectionHeader(theme, 'Active Connection', Icons.wifi_sharp),
            const SizedBox(height: 10),
            _buildConnectedNetworkCard(context, colorScheme, theme),
            const SizedBox(height: 24),

            // Hardware & OS Capabilities Section
            _buildSectionHeader(
              theme,
              'Hardware Capabilities',
              Icons.developer_board_rounded,
            ),
            const SizedBox(height: 10),
            _buildCapabilitiesGrid(context, colorScheme, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildScanHeroBanner(
    BuildContext context,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          onTap: () => context.push('/wifi/scan'),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.radar_rounded,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Wi-Fi Scanner',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Scan nearby access points, bands & RSSI',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectedNetworkCard(
    BuildContext context,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return BlocBuilder<WifiInfoBloc, WifiInfoState>(
      builder: (context, state) {
        if (state is WifiInfoLoading) {
          return Card(
            child: Container(
              height: 160,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(),
            ),
          );
        }

        if (state is WifiInfoError) {
          return Card(
            color: colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      state.message,
                      style: TextStyle(color: colorScheme.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is WifiInfoLoaded) {
          final info = state.info;
          return _ConnectedInfoCardDetails(info: info);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildCapabilitiesGrid(
    BuildContext context,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return BlocBuilder<WifiCapabilitiesBloc, WifiCapabilitiesState>(
      builder: (context, state) {
        if (state is WifiCapabilitiesLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state is WifiCapabilitiesError) {
          return Card(
            color: colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error: ${state.message}',
                style: TextStyle(color: colorScheme.onErrorContainer),
              ),
            ),
          );
        }

        if (state is WifiCapabilitiesLoaded) {
          final caps = state.capabilities;
          return Column(
            children: [
              // Adapter Overview Banner
              _AdapterStatusCard(caps: caps),
              const SizedBox(height: 12),

              // Capabilities Matrix Cards
              _CapabilityItemTile(
                title: 'Wi-Fi Hardware Supported',
                subtitle: caps.wifiSupported
                    ? 'Hardware present on device'
                    : 'No Wi-Fi module detected',
                isSupported: caps.wifiSupported,
                icon: Icons.wifi,
              ),
              _CapabilityItemTile(
                title: '5 GHz Band',
                subtitle: caps.is5GHzSupported
                    ? 'High-speed 5 GHz band available'
                    : '2.4 GHz only',
                isSupported: caps.is5GHzSupported,
                icon: Icons.five_g_rounded,
              ),
              _CapabilityItemTile(
                title: '6 GHz Band (Wi-Fi 6E)',
                subtitle: caps.is6GHzSupported
                    ? 'Ultra-fast 6 GHz band supported'
                    : 'Unsupported or API < 30',
                isSupported: caps.is6GHzSupported,
                icon: Icons.wifi_channel_rounded,
              ),
              _CapabilityItemTile(
                title: 'Wi-Fi Direct (P2P)',
                subtitle: caps.isWifiDirectSupported
                    ? 'Peer-to-peer connection supported'
                    : 'Unsupported',
                isSupported: caps.isWifiDirectSupported,
                icon: Icons.swap_calls_rounded,
              ),
              _CapabilityItemTile(
                title: 'WPA3 Personal (SAE)',
                subtitle: caps.isWpa3SaeSupported
                    ? 'Latest WPA3 encryption supported'
                    : 'WPA2 max supported',
                isSupported: caps.isWpa3SaeSupported,
                icon: Icons.verified_user_rounded,
              ),
              _CapabilityItemTile(
                title: 'WPA3 Enterprise (Suite-B)',
                subtitle: caps.isWpa3SuiteBSupported
                    ? '192-bit security supported'
                    : 'Unsupported',
                isSupported: caps.isWpa3SuiteBSupported,
                icon: Icons.admin_panel_settings_rounded,
              ),
              _CapabilityItemTile(
                title: 'Enhanced Open (OWE)',
                subtitle: caps.isEnhancedOpenSupported
                    ? 'Opportunistic Wireless Encryption supported'
                    : 'Unsupported',
                isSupported: caps.isEnhancedOpenSupported,
                icon: Icons.lock_open_rounded,
              ),
              _CapabilityItemTile(
                title: 'Scan Always Available',
                subtitle: caps.scanAlwaysAvailable
                    ? 'OS permits background location scans'
                    : 'Disabled in Android Settings',
                isSupported: caps.scanAlwaysAvailable,
                icon: Icons.travel_explore_rounded,
              ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

// =============================================================================
// Active Wi-Fi Connected Details Card (Includes ALL fields from WifiInfoModel)
// =============================================================================
class _ConnectedInfoCardDetails extends StatelessWidget {
  const _ConnectedInfoCardDetails({required this.info});

  final WifiInfoModel info;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!info.connected) {
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 48,
                color: colorScheme.outline,
              ),
              const SizedBox(height: 12),
              Text(
                'Disconnected',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                info.wifiEnabled
                    ? 'Wi-Fi is ON, but not connected to any network.'
                    : 'Wi-Fi is currently turned OFF.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SSID Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Icon(
                    Icons.wifi_rounded,
                    color: colorScheme.onPrimaryContainer,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              info.ssid.isEmpty ? 'Hidden Network' : info.ssid,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (info.hiddenSsid)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Hidden',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        'BSSID: ${info.bssid}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Signal Gauge Row
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Signal Strength: ${info.signalStrength} (${info.rssi} dBm)',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (info.signalLevel + 1) / 5.0,
                            minHeight: 8,
                            backgroundColor: colorScheme.outlineVariant
                                .withValues(alpha: 0.3),
                            color: _getSignalColor(info.signalLevel),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${info.signalLevel}/4 Bars',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Grid displaying ALL remaining model fields
            Wrap(
              runSpacing: 12,
              spacing: 12,
              children: [
                _InfoTile(
                  width: 150,
                  label: 'IP Address',
                  value: info.ipAddress,
                  icon: Icons.lan_rounded,
                ),
                _InfoTile(
                  width: 150,
                  label: 'Link Speed',
                  value: '${info.linkSpeedMbps} Mbps',
                  icon: Icons.speed_rounded,
                ),
                _InfoTile(
                  width: 150,
                  label: 'Frequency',
                  value: '${info.frequencyMHz} MHz',
                  icon: Icons.graphic_eq_rounded,
                ),
                _InfoTile(
                  width: 150,
                  label: 'Frequency Band',
                  value: info.band,
                  icon: Icons.cell_tower_rounded,
                ),
                _InfoTile(
                  width: 150,
                  label: 'Network ID',
                  value: '${info.networkId}',
                  icon: Icons.numbers_rounded,
                ),
                _InfoTile(
                  width: 150,
                  label: 'MAC Address',
                  value: info.macAddress,
                  icon: Icons.perm_device_information_rounded,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Permissions Status Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _PermissionChip(
                  label: 'Fine Location',
                  granted: info.hasLocationPermission,
                ),
                _PermissionChip(
                  label: 'Nearby Wi-Fi',
                  granted: info.hasNearbyWifiPermission,
                ),
              ],
            ),
          ],
        ),
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
}

class _AdapterStatusCard extends StatelessWidget {
  const _AdapterStatusCard({required this.caps});

  final WifiCapabilitiesModel caps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      color: colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              caps.wifiEnabled ? Icons.power_rounded : Icons.power_off_rounded,
              color: caps.wifiEnabled ? Colors.green : Colors.red,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'State: ${caps.wifiState}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    caps.wifiEnabled
                        ? 'Wi-Fi Adapter Enabled'
                        : 'Wi-Fi Adapter Disabled',
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            Chip(
              label: Text(caps.wifiEnabled ? 'ENABLED' : 'DISABLED'),
              backgroundColor: caps.wifiEnabled
                  ? Colors.green.shade100
                  : Colors.red.shade100,
              labelStyle: TextStyle(
                color: caps.wifiEnabled
                    ? Colors.green.shade900
                    : Colors.red.shade900,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

class _CapabilityItemTile extends StatelessWidget {
  const _CapabilityItemTile({
    required this.title,
    required this.subtitle,
    required this.isSupported,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final bool isSupported;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSupported ? colorScheme.primary : colorScheme.outline,
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSupported
                ? Colors.green.withValues(alpha: 0.1)
                : colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isSupported ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: isSupported ? Colors.green : colorScheme.outline,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
  });

  final double width;
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                Text(
                  value.isEmpty ? 'Unknown' : value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionChip extends StatelessWidget {
  const _PermissionChip({required this.label, required this.granted});

  final String label;
  final bool granted;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          granted
              ? Icons.check_circle_outline_rounded
              : Icons.highlight_off_rounded,
          size: 14,
          color: granted ? Colors.green : Colors.red,
        ),
        const SizedBox(width: 4),
        Text(
          '$label: ${granted ? "Granted" : "Denied"}',
          style: TextStyle(
            fontSize: 11,
            color: granted ? Colors.green.shade800 : Colors.red.shade800,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
