import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/service_locator.dart';
import '../device_info/bloc/device_info_bloc.dart';
import '../device_info/bloc/device_info_event.dart';
import '../device_info/bloc/device_info_state.dart';
import '../shared/widgets.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Device Information')),
      body: BlocBuilder<DeviceInfoBloc, DeviceInfoState>(
        builder: (context, state) {
          if (state is DeviceInfoLoading || state is DeviceInfoInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is DeviceInfoError) {
            final theme = Theme.of(context);
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 40,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Couldn't load device info",
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
                      onPressed: () => context.read<DeviceInfoBloc>().add(
                        const DeviceInfoRequested(),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = (state as DeviceInfoLoaded).data;
          String field(String key) => (data[key] ?? '').toString();

          return RefreshIndicator(
            onRefresh: () async {
              context.read<DeviceInfoBloc>().add(const DeviceInfoRequested());
              await context.read<DeviceInfoBloc>().stream.firstWhere(
                (s) => s is! DeviceInfoLoading,
              );
            },
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                SectionCard(
                  title: 'Identity',
                  icon: Icons.badge_outlined,
                  children: [
                    InfoRow(
                      label: 'Manufacturer',
                      value: field('manufacturer'),
                    ),
                    const Divider(),
                    InfoRow(label: 'Brand', value: field('brand')),
                    const Divider(),
                    InfoRow(label: 'Model', value: field('model')),
                    const Divider(),
                    InfoRow(label: 'Device', value: field('device')),
                  ],
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Software',
                  icon: Icons.developer_mode_outlined,
                  children: [
                    InfoRow(
                      label: 'Android Version',
                      value: field('androidVersion'),
                    ),
                    const Divider(),
                    InfoRow(label: 'SDK Level', value: field('sdk')),
                    const Divider(),
                    InfoRow(
                      label: 'Security Patch',
                      value: field('securityPatch'),
                    ),
                    const Divider(),
                    InfoRow(label: 'Build Time', value: _buildTime(data)),
                    const Divider(),
                    InfoRow(label: 'Bootloader', value: field('bootloader')),
                    const Divider(),
                    InfoRow(label: 'Host', value: field('host')),
                    const Divider(),
                    InfoRow(label: 'Fingerprint', value: field('fingerprint')),
                    const Divider(),
                    InfoRow(label: 'Tags', value: field('tags')),
                    const Divider(),
                    InfoRow(label: 'ABI', value: field('abi')),
                    const Divider(),
                    InfoRow(label: 'Build Type', value: field('buildType')),
                    const Divider(),
                    InfoRow(label: 'Codename', value: field('codename')),
                    const Divider(),
                    InfoRow(label: 'Incremental', value: field('incremental')),
                    const Divider(),
                    InfoRow(label: 'Release', value: field('release')),
                    const Divider(),
                    InfoRow(label: 'Base OS', value: field('baseOS')),
                  ],
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Hardware',
                  icon: Icons.memory_outlined,
                  children: [
                    InfoRow(label: 'Hardware', value: field('hardware')),
                    const Divider(),
                    InfoRow(label: 'Board', value: field('board')),
                    const Divider(),
                    InfoRow(label: 'Product', value: field('product')),
                    const Divider(),
                    InfoRow(label: 'Supported ABI', value: field('abi')),
                    const Divider(),
                    InfoRow(label: 'SoC Manufacturer', value: field('socman')),
                    const Divider(),
                    InfoRow(label: 'SoC Model', value: field('socmodel')),
                    const Divider(),
                    InfoRow(label: 'ODM SKU', value: field('odmsku')),
                  ],
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Display',
                  icon: Icons.smartphone_outlined,
                  children: [
                    InfoRow(label: 'Display', value: field('display')),
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
