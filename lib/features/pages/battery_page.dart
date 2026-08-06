import 'dart:core' as logger;
import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';

import '../../core/di/service_locator.dart';
import '../battery_info/bloc/battery_info_bloc.dart';
import '../shared/reusable_widgets.dart';

class BatteryInfoPage extends StatelessWidget {
  const BatteryInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BatteryInfoBloc>()..add(const BatteryInfoRequested()),
      child: const _BatteryInfoView(),
    );
  }
}

class _BatteryInfoView extends StatelessWidget {
  const _BatteryInfoView();

  // ===========================================================================
  // Data Parsing Methods (Preserved exactly as requested)
  // ===========================================================================

  String _batteryLevel(Map<String, dynamic> data) {
    return '${data['level'] ?? '--'}%';
  }

  String _chargingStatus(Map<String, dynamic> data) {
    final charging = data['isCharging'];
    if (charging == null) return 'Unknown';
    return charging ? 'Charging' : 'Not Charging';
  }

  String _temperature(Map<String, dynamic> data) {
    final value = data['temperature'];
    if (value == null) return 'Unknown';
    return '$value °C';
  }

  String _voltage(Map<String, dynamic> data) {
    final value = data['voltage'];
    if (value == null) return 'Unknown';
    return '$value mV';
  }

  String _currentNow(Map<String, dynamic> data) {
    final raw = data['currentNowMicroAmps'];
    final microAmps = int.tryParse(raw?.toString() ?? '');
    if (microAmps == null || microAmps == -1) return 'Unavailable';
    final milliAmps = microAmps / 1000;
    return '${milliAmps.toStringAsFixed(0)} mA';
  }

  String _chargeCounter(Map<String, dynamic> data) {
    final raw = data['chargeCounterMicroAmpHours'];
    final microAmpHours = int.tryParse(raw?.toString() ?? '');
    if (microAmpHours == null || microAmpHours < 0) return 'Unavailable';
    final milliAmpHours = microAmpHours / 1000;
    return '${milliAmpHours.toStringAsFixed(0)} mAh';
  }

  String _levelCrossCheck(Map<String, dynamic> data) {
    final raw = data['levelFromBroadcast'];
    final level = int.tryParse(raw?.toString() ?? '');
    if (level == null || level < 0) return 'Unavailable';
    return '$level%';
  }

  String _yesNo(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null) return 'Unavailable';
    return value == true ? 'Yes' : 'No';
  }

  String _thermalStatus(Map<String, dynamic> data) {
    final value = data['thermalStatus'];
    if (value == null) return 'Not available (Android 10+ only)';
    return value.toString();
  }

  String _dozeMode(Map<String, dynamic> data) {
    if (!data.containsKey('isDeviceIdleMode')) {
      return 'Not available (Android 6+ only)';
    }
    return _yesNo(data, 'isDeviceIdleMode');
  }

  String _lastUpdated(Map<String, dynamic> data) {
    final timestamp = data['timestamp'];
    if (timestamp == null || timestamp is! int) return 'Unknown';

    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    // Format to a readable string like "14:30:45"
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }

  // ===========================================================================
  // UI Build Method
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Battery Information'),
        actions: [
          IconButton.filledTonal(
            icon: const Icon(Icons.show_chart_rounded),
            tooltip: 'View trends',
            onPressed: () => context.push('/battery/trends'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<BatteryInfoBloc, BatteryInfoState>(
        builder: (context, state) {
          if (state is BatteryInfoInitial || state is BatteryInfoLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Reading battery sensors...'),
                ],
              ),
            );
          }

          if (state is BatteryInfoError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ModernSectionCard(
                  title: "Error Reading Data",
                  icon: Icons.battery_alert_rounded,
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
                        onPressed: () => context.read<BatteryInfoBloc>().add(
                          const BatteryInfoRequested(),
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

          final data = (state as BatteryInfoLoaded).data;
          final history = state.history;
          Logger().d('Battery Info Data: $history');

          String field(String key) => (data[key] ?? 'Unknown').toString();

          final isCharging = data['isCharging'] == true;
          final levelStr = _batteryLevel(data);

          return RefreshIndicator(
            onRefresh: () async {
              context.read<BatteryInfoBloc>().add(const BatteryInfoRequested());
              await context.read<BatteryInfoBloc>().stream.firstWhere(
                (state) => state is! BatteryInfoLoading,
              );
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. Hero Summary Banner
                _buildHeroBanner(
                  context,
                  isCharging,
                  levelStr,
                  _chargingStatus(data),
                  _lastUpdated(data),
                ),
                const SizedBox(height: 24),

                // 2. Electrical Readings Grid
                ModernSectionCard(
                  title: 'Electrical Metrics',
                  icon: Icons.bolt_rounded,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        // Calculate the exact width for 2 columns by taking the max available width,
                        // subtracting the 12px spacing between the two items, and dividing by 2.
                        final double tileWidth =
                            (constraints.maxWidth - 12) / 2;

                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            ModernDetailTile(
                              width: tileWidth,
                              label: 'Voltage',
                              value: _voltage(data),
                              icon: Icons.speed_rounded,
                            ),
                            ModernDetailTile(
                              width: tileWidth,
                              label: 'Temperature',
                              value: _temperature(data),
                              icon: Icons.thermostat_rounded,
                            ),
                            ModernDetailTile(
                              width: tileWidth,
                              label: 'Current Draw',
                              value: _currentNow(data),
                              icon: Icons.electric_meter_rounded,
                            ),
                            ModernDetailTile(
                              width: tileWidth,
                              label: 'Charge Remaining',
                              value: _chargeCounter(data),
                              icon: Icons.battery_charging_full_rounded,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 3. Health & Hardware
                ModernSectionCard(
                  title: 'Health & Hardware',
                  icon: Icons.health_and_safety_rounded,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        // Calculate the exact width for 2 columns by taking the max available width,
                        // subtracting the 12px spacing between the two items, and dividing by 2.
                        final double tileWidth =
                            (constraints.maxWidth - 12) / 2;

                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            ModernDetailTile(
                              width: tileWidth,
                              label: 'Battery Health',
                              value: field('health'),
                              icon: Icons.monitor_heart_rounded,
                            ),
                            ModernDetailTile(
                              width: tileWidth,
                              label: 'Technology',
                              value: field('technology'),
                              icon: Icons.science_rounded,
                            ),
                            ModernDetailTile(
                              width: tileWidth,
                              label: 'Charging Source',
                              value: field('chargingSource'),
                              icon: Icons.power_rounded,
                            ),
                            ModernDetailTile(
                              width: tileWidth,
                              label: 'Battery Present',
                              value: _yesNo(data, 'isBatteryPresent'),
                              icon: Icons.check_circle_outline_rounded,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 4. Power State & OS Flags
                ModernSectionCard(
                  title: 'Power State & OS Flags',
                  icon: Icons.settings_power_rounded,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        // Calculate the exact width for 2 columns by taking the max available width,
                        // subtracting the 12px spacing between the two items, and dividing by 2.
                        final double tileWidth =
                            (constraints.maxWidth - 12) / 2;

                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            ModernDetailTile(
                              width: tileWidth,
                              label: 'Battery Saver',
                              value: _yesNo(data, 'isPowerSaveMode'),
                              icon: Icons.eco_rounded,
                              isSupported: data['isPowerSaveMode'] == true,
                            ),
                            ModernDetailTile(
                              width: tileWidth,
                              label: 'Doze Mode',
                              value: _dozeMode(data),
                              icon: Icons.bedtime_rounded,
                            ),
                            ModernDetailTile(
                              width: tileWidth,
                              label: 'Screen Interactive',
                              value: _yesNo(data, 'isScreenInteractive'),
                              icon: Icons.touch_app_rounded,
                            ),
                            ModernDetailTile(
                              width: tileWidth,
                              label: 'Thermal Status',
                              value: _thermalStatus(data),
                              icon: Icons.local_fire_department_rounded,
                            ),
                            ModernDetailTile(
                              width: tileWidth,
                              label: 'OS Charging Flag',
                              value: _yesNo(data, 'isChargingFlag'),
                              icon: Icons.flag_rounded,
                            ),
                            ModernDetailTile(
                              width: tileWidth,
                              label: 'Level (Broadcast)',
                              value: _levelCrossCheck(data),
                              icon: Icons.cell_tower_rounded,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32), // Bottom padding
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
    BuildContext context,
    bool isCharging,
    String levelStr,
    String chargingStr,
    String lastUpdatedStr,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final gradientColors = isCharging
        ? [Colors.green.shade400, Colors.green.shade700]
        : [colorScheme.primary, colorScheme.tertiary];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withValues(alpha: 0.3),
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
            child: Icon(
              isCharging
                  ? Icons.battery_charging_full_rounded
                  : Icons.battery_std_rounded,
              size: 42,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  levelStr,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    StatusBadgeTag(label: chargingStr, color: Colors.white),
                  ],
                ),
              ],
            ),
          ),
          Text(
            "Snapshot Taken At",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w400,
              letterSpacing: -1,
            ),
          ),
          SizedBox(width: 4),
          StatusBadgeTag(label: lastUpdatedStr, color: Colors.white),
        ],
      ),
    );
  }
}
