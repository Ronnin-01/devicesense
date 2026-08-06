import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/service_locator.dart';
import '../device_info/bloc/device_info_bloc.dart';
import '../device_info/bloc/device_info_event.dart';
import '../device_info/bloc/device_info_state.dart';
import '../shared/reusable_widgets.dart';

class DeviceInfoPage extends StatelessWidget {
  const DeviceInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DeviceInfoBloc>()..add(const DeviceInfoRequested()),
      child: const _DeviceInfoView(),
    );
  }
}

class _DeviceInfoView extends StatelessWidget {
  const _DeviceInfoView();

  // ===========================================================================
  // Data Parsing (Preserved exactly as requested)
  // ===========================================================================
  String _buildTime(Map<String, dynamic> info) {
    final raw = info['time'];
    if (raw == null) return 'Unknown';
    final millis = int.tryParse(raw.toString());
    if (millis == null) return 'Unknown';
    final date = DateTime.fromMillisecondsSinceEpoch(millis);
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${date.year}-${pad(date.month)}-${pad(date.day)} '
        '${pad(date.hour)}:${pad(date.minute)}';
  }

  // ===========================================================================
  // UI Build Method
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Information'),
        actions: [
          IconButton.filledTonal(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Info',
            onPressed: () =>
                context.read<DeviceInfoBloc>().add(const DeviceInfoRequested()),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<DeviceInfoBloc, DeviceInfoState>(
        builder: (context, state) {
          if (state is DeviceInfoLoading || state is DeviceInfoInitial) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Reading system properties...'),
                ],
              ),
            );
          }

          if (state is DeviceInfoError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ModernSectionCard(
                  title: "Error Reading Data",
                  icon: Icons.error_outline_rounded,
                  backgroundColor: theme.colorScheme.errorContainer,
                  children: [
                    Text(
                      state.message,
                      style: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => context.read<DeviceInfoBloc>().add(
                          const DeviceInfoRequested(),
                        ),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = (state as DeviceInfoLoaded).data;

          // Helper to extract fields safely
          String field(String key) {
            final val = data[key];
            return (val == null || val.toString().isEmpty)
                ? 'Unknown'
                : val.toString();
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<DeviceInfoBloc>().add(const DeviceInfoRequested());
              await context.read<DeviceInfoBloc>().stream.firstWhere(
                (s) => s is! DeviceInfoLoading,
              );
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. Hero Identity Banner
                _buildHeroBanner(
                  context,
                  brand: field('brand'),
                  model: field('model'),
                  osVersion: field('androidVersion'),
                  sdk: field('sdk'),
                ),
                const SizedBox(height: 24),

                // 2. Identity Grid
                ModernSectionCard(
                  title: 'Core Identity',
                  icon: Icons.badge_rounded,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final halfWidth = (constraints.maxWidth - 12) / 2;
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            ModernDetailTile(
                              width: halfWidth,
                              label: 'Manufacturer',
                              value: field('manufacturer'),
                              icon: Icons.factory_rounded,
                            ),
                            ModernDetailTile(
                              width: halfWidth,
                              label: 'Brand',
                              value: field('brand'),
                              icon: Icons.branding_watermark_rounded,
                            ),
                            ModernDetailTile(
                              width: halfWidth,
                              label: 'Model',
                              value: field('model'),
                              icon: Icons.smartphone_rounded,
                            ),
                            ModernDetailTile(
                              width: halfWidth,
                              label: 'Device Name',
                              value: field('device'),
                              icon: Icons.devices_rounded,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 3. Hardware Grid
                ModernSectionCard(
                  title: 'Hardware & Architecture',
                  icon: Icons.memory_rounded,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final halfWidth = (constraints.maxWidth - 12) / 2;
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            ModernDetailTile(
                              width: halfWidth,
                              label: 'Hardware',
                              value: field('hardware'),
                              icon: Icons.developer_board_rounded,
                            ),
                            ModernDetailTile(
                              width: halfWidth,
                              label: 'Board',
                              value: field('board'),
                              icon: Icons.dashboard_rounded,
                            ),
                            ModernDetailTile(
                              width: halfWidth,
                              label: 'Product',
                              value: field('product'),
                              icon: Icons.inventory_2_rounded,
                            ),
                            ModernDetailTile(
                              width: halfWidth,
                              label: 'Supported ABI',
                              value: field('abi'),
                              icon: Icons.settings_ethernet_rounded,
                            ),
                            ModernDetailTile(
                              width: halfWidth,
                              label: 'SoC Manufacturer',
                              value: field('socman'),
                              icon: Icons.precision_manufacturing_rounded,
                            ),
                            ModernDetailTile(
                              width: halfWidth,
                              label: 'SoC Model',
                              value: field('socmodel'),
                              icon: Icons.memory_rounded,
                            ),
                            ModernDetailTile(
                              width: halfWidth,
                              label: 'ODM SKU',
                              value: field('odmsku'),
                              icon: Icons.qr_code_rounded,
                            ),
                            ModernDetailTile(
                              width: halfWidth,
                              label: 'Display Panel',
                              value: field('display'),
                              icon: Icons.screenshot_monitor_rounded,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 4. Software & OS Grid
                ModernSectionCard(
                  title: 'Operating System',
                  icon: Icons.android_rounded,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final halfWidth = (constraints.maxWidth - 12) / 2;
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            ModernDetailTile(
                              width: halfWidth,
                              label: 'Android Version',
                              value: field('androidVersion'),
                              icon: Icons.system_update_rounded,
                            ),
                            ModernDetailTile(
                              width: halfWidth,
                              label: 'SDK Level',
                              value: 'API ${field('sdk')}',
                              icon: Icons.code_rounded,
                            ),
                            ModernDetailTile(
                              width: halfWidth,
                              label: 'Security Patch',
                              value: field('securityPatch'),
                              icon: Icons.security_rounded,
                            ),
                            ModernDetailTile(
                              width: halfWidth,
                              label: 'Codename',
                              value: field('codename'),
                              icon: Icons.bug_report_rounded,
                            ),
                            ModernDetailTile(
                              width: halfWidth,
                              label: 'Release',
                              value: field('release'),
                              icon: Icons.new_releases_rounded,
                            ),
                            ModernDetailTile(
                              width: halfWidth,
                              label: 'Base OS',
                              value: field('baseOS'),
                              icon: Icons.terminal_rounded,
                            ),
                            ModernDetailTile(
                              width: halfWidth,
                              label: 'Build Type',
                              value: field('buildType'),
                              icon: Icons.build_circle_rounded,
                            ),
                            ModernDetailTile(
                              width: halfWidth,
                              label: 'Incremental',
                              value: field('incremental'),
                              icon: Icons.merge_type_rounded,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 5. Advanced System Build
                ModernSectionCard(
                  title: 'System Build Details',
                  icon: Icons.settings_system_daydream_rounded,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final halfWidth = (constraints.maxWidth - 12) / 2;
                        final fullWidth = constraints
                            .maxWidth; // For long strings like fingerprint

                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            ModernDetailTile(
                              width: halfWidth,
                              label: 'Build Time',
                              value: _buildTime(data),
                              icon: Icons.access_time_rounded,
                            ),
                            ModernDetailTile(
                              width: halfWidth,
                              label: 'Bootloader',
                              value: field('bootloader'),
                              icon: Icons.system_security_update_rounded,
                            ),
                            ModernDetailTile(
                              width: halfWidth,
                              label: 'Host',
                              value: field('host'),
                              icon: Icons.dns_rounded,
                            ),
                            ModernDetailTile(
                              width: halfWidth,
                              label: 'Tags',
                              value: field('tags'),
                              icon: Icons.local_offer_rounded,
                            ),
                            // Fingerprint is typically a very long string, so it gets full width
                            ModernDetailTile(
                              width: fullWidth,
                              label: 'System Fingerprint',
                              value: field('fingerprint'),
                              icon: Icons.fingerprint_rounded,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // Custom Visual Hero Card
  // ===========================================================================
  Widget _buildHeroBanner(
    BuildContext context, {
    required String brand,
    required String model,
    required String osVersion,
    required String sdk,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Capitalize brand name for aesthetic purposes
    final displayBrand = brand.isNotEmpty
        ? '${brand[0].toUpperCase()}${brand.substring(1)}'
        : 'Unknown';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smartphone_rounded,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$displayBrand $model',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    StatusBadgeTag(
                      label: 'Android $osVersion',
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    StatusBadgeTag(label: 'API $sdk', color: Colors.white),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
