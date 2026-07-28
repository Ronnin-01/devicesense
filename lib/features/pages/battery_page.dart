import 'dart:core' as logger;
import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';

import '../../core/di/service_locator.dart';
import '../battery_info/bloc/battery_info_bloc.dart';
import '../shared/widgets.dart';

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

  // BatteryManager electrical readings --------------------------

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

  //  PowerManager state -------------------------------------------

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Battery Information'),
        actions: [
          IconButton(
            icon: const Icon(Icons.show_chart_rounded),
            tooltip: 'View trends',
            onPressed: () => context.push('/battery/trends'),
          ),
        ],
      ),
      body: BlocBuilder<BatteryInfoBloc, BatteryInfoState>(
        builder: (context, state) {
          if (state is BatteryInfoInitial || state is BatteryInfoLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is BatteryInfoError) {
            final theme = Theme.of(context);

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.battery_alert_rounded,
                      size: 40,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Couldn't load battery information",
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        context.read<BatteryInfoBloc>().add(
                          const BatteryInfoRequested(),
                        );
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = (state as BatteryInfoLoaded).data;
          final history = (state).history;
          final logger = Logger();
          logger.d('Battery Info Data: $history');

          String field(String key) => (data[key] ?? 'Unknown').toString();

          return RefreshIndicator(
            onRefresh: () async {
              context.read<BatteryInfoBloc>().add(const BatteryInfoRequested());

              await context.read<BatteryInfoBloc>().stream.firstWhere(
                (state) => state is! BatteryInfoLoading,
              );
            },
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                SectionCard(
                  title: 'Battery Status',
                  icon: Icons.battery_full_outlined,
                  children: [
                    ExpandableInfoTile(
                      title: 'Battery Level',
                      value: _batteryLevel(data),
                    ),
                    const Divider(),
                    ExpandableInfoTile(
                      title: 'Level (secondary reading)',
                      value: _levelCrossCheck(data),
                    ),
                    const Divider(),
                    ExpandableInfoTile(
                      title: 'Status',
                      value: _chargingStatus(data),
                    ),
                    const Divider(),
                    ExpandableInfoTile(
                      title: 'OS Charging Flag',
                      value: _yesNo(data, 'isChargingFlag'),
                    ),
                    const Divider(),
                    ExpandableInfoTile(
                      title: 'Charging Source',
                      value: field('chargingSource'),
                    ),
                    const Divider(),
                    ExpandableInfoTile(
                      title: 'Battery Present',
                      value: _yesNo(data, 'isBatteryPresent'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                SectionCard(
                  title: 'Battery Health',
                  icon: Icons.health_and_safety_outlined,
                  children: [
                    ExpandableInfoTile(title: 'Health', value: field('health')),
                    const Divider(),
                    ExpandableInfoTile(
                      title: 'Technology',
                      value: field('technology'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                SectionCard(
                  title: 'Electrical Readings',
                  icon: Icons.bolt_outlined,
                  children: [
                    ExpandableInfoTile(
                      title: 'Current Draw',
                      value: _currentNow(data),
                    ),
                    const Divider(),
                    ExpandableInfoTile(
                      title: 'Charge Remaining',
                      value: _chargeCounter(data),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                SectionCard(
                  title: 'Battery Metrics',
                  icon: Icons.analytics_outlined,
                  children: [
                    ExpandableInfoTile(title: 'Voltage', value: _voltage(data)),
                    const Divider(),
                    ExpandableInfoTile(
                      title: 'Temperature',
                      value: _temperature(data),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                SectionCard(
                  title: 'Power State',
                  icon: Icons.settings_power_outlined,
                  children: [
                    ExpandableInfoTile(
                      title: 'Battery Saver',
                      value: _yesNo(data, 'isPowerSaveMode'),
                    ),
                    const Divider(),
                    ExpandableInfoTile(
                      title: 'Screen Interactive',
                      value: _yesNo(data, 'isScreenInteractive'),
                    ),
                    const Divider(),
                    ExpandableInfoTile(
                      title: 'Doze Mode',
                      value: _dozeMode(data),
                    ),
                    const Divider(),
                    ExpandableInfoTile(
                      title: 'Thermal Status',
                      value: _thermalStatus(data),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                SectionCard(
                  title: 'Quick Summary',
                  icon: Icons.info_outline_rounded,
                  children: [
                    ExpandableInfoTile(
                      title: 'Battery Level',
                      value: _batteryLevel(data),
                    ),
                    const Divider(),
                    ExpandableInfoTile(title: 'Health', value: field('health')),
                    const Divider(),
                    ExpandableInfoTile(
                      title: 'Charging',
                      value: _chargingStatus(data),
                    ),
                    const Divider(),
                    ExpandableInfoTile(
                      title: 'Temperature',
                      value: _temperature(data),
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
