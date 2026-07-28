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
                    ExpandableInfoTile(
                      title: 'Manufacturer',
                      value: field('manufacturer'),
                    ),
                    const Divider(),
                    ExpandableInfoTile(title: 'Brand', value: field('brand')),
                    const Divider(),
                    ExpandableInfoTile(title: 'Model', value: field('model')),
                    const Divider(),
                    ExpandableInfoTile(title: 'Device', value: field('device')),
                  ],
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Software',
                  icon: Icons.developer_mode_outlined,
                  children: [
                    ExpandableInfoTile(
                      title: 'Android Version',
                      value: field('androidVersion'),
                    ),
                    const Divider(),
                    ExpandableInfoTile(title: 'SDK Level', value: field('sdk')),
                    const Divider(),
                    ExpandableInfoTile(
                      title: 'Security Patch',
                      value: field('securityPatch'),
                    ),
                    const Divider(),
                    ExpandableInfoTile(
                      title: 'Build Time',
                      value: _buildTime(data),
                    ),
                    const Divider(),
                    ExpandableInfoTile(
                      title: 'Bootloader',
                      value: field('bootloader'),
                    ),
                    const Divider(),
                    ExpandableInfoTile(title: 'Host', value: field('host')),
                    const Divider(),
                    ExpandableInfoTile(
                      title: 'Fingerprint',
                      value: field('fingerprint'),
                    ),
                    const Divider(),
                    ExpandableInfoTile(title: 'Tags', value: field('tags')),
                    const Divider(),
                    ExpandableInfoTile(title: 'ABI', value: field('abi')),
                    const Divider(),
                    ExpandableInfoTile(
                      title: 'Build Type',
                      value: field('buildType'),
                    ),
                    const Divider(),
                    ExpandableInfoTile(
                      title: 'Codename',
                      value: field('codename'),
                    ),
                    const Divider(),
                    ExpandableInfoTile(
                      title: 'Incremental',
                      value: field('incremental'),
                    ),
                    const Divider(),
                    ExpandableInfoTile(
                      title: 'Release',
                      value: field('release'),
                    ),
                    const Divider(),
                    ExpandableInfoTile(
                      title: 'Base OS',
                      value: field('baseOS'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Hardware',
                  icon: Icons.memory_outlined,
                  children: [
                    ExpandableInfoTile(
                      title: 'Hardware',
                      value: field('hardware'),
                    ),
                    const Divider(),
                    ExpandableInfoTile(title: 'Board', value: field('board')),
                    const Divider(),
                    ExpandableInfoTile(
                      title: 'Product',
                      value: field('product'),
                    ),
                    const Divider(),
                    ExpandableInfoTile(
                      title: 'Supported ABI',
                      value: field('abi'),
                    ),
                    const Divider(),
                    ExpandableInfoTile(
                      title: 'SoC Manufacturer',
                      value: field('socman'),
                    ),
                    const Divider(),
                    ExpandableInfoTile(
                      title: 'SoC Model',
                      value: field('socmodel'),
                    ),
                    const Divider(),
                    ExpandableInfoTile(
                      title: 'ODM SKU',
                      value: field('odmsku'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Display',
                  icon: Icons.smartphone_outlined,
                  children: [
                    ExpandableInfoTile(
                      title: 'Display',
                      value: field('display'),
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
