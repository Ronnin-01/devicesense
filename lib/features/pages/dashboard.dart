import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/service_locator.dart';
import '../device_info/bloc/device_info_bloc.dart';
import '../device_info/bloc/device_info_event.dart';
import '../device_info/bloc/device_info_state.dart';
import '../shared/widgets.dart';

/// Route-level widget. Its only job is to create/provide the
/// [DeviceInfoBloc] for this page (Single Responsibility) — all
/// rendering lives in [_DashboardView].
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DeviceInfoBloc>()..add(const DeviceInfoRequested()),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            context.read<DeviceInfoBloc>().add(const DeviceInfoRequested());
            await context.read<DeviceInfoBloc>().stream.firstWhere(
              (state) => state is! DeviceInfoLoading,
            );
          },
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DeviceSense',
                            style: theme.textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Your hardware, inspected',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.memory_rounded,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: BlocBuilder<DeviceInfoBloc, DeviceInfoState>(
                    builder: (context, state) {
                      final loading =
                          state is DeviceInfoLoading ||
                          state is DeviceInfoInitial;
                      final data = state is DeviceInfoLoaded
                          ? state.data
                          : <String, dynamic>{};
                      String field(String key) => (data[key] ?? '').toString();

                      return _DeviceSummaryCard(
                        loading: loading,
                        model: field('model'),
                        manufacturer: field('manufacturer'),
                        androidVersion: field('androidVersion'),
                        sdk: field('sdk'),
                        onTap: () => context.push('/device-info'),
                      );
                    },
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Text('Explore', style: theme.textTheme.titleLarge),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1.05,
                  ),
                  delegate: SliverChildListDelegate([
                    CategoryCard(
                      icon: Icons.info_outline_rounded,
                      title: 'Device Info',
                      subtitle: 'Build, model & SoC details',
                      color: const Color(0xFF3D5AFE),
                      onTap: () => context.push('/device-info'),
                    ),
                    CategoryCard(
                      icon: Icons.battery_charging_full_rounded,
                      title: 'Battery',
                      subtitle: 'Level, health & temperature',
                      color: const Color(0xFF00C853),
                      onTap: () => context.push('/battery'),
                    ),
                    CategoryCard(
                      icon: Icons.bluetooth_rounded,
                      title: 'Bluetooth',
                      subtitle: 'Paired & nearby devices',
                      color: const Color(0xFF2979FF),
                      onTap: () => context.push('/bluetooth'),
                    ),
                    CategoryCard(
                      icon: Icons.wifi_rounded,
                      title: 'Wi-Fi',
                      subtitle: 'Signal, IP & network info',
                      color: const Color(0xFFFF6D00),
                      onTap: () => context.push('/wifi'),
                    ),
                    CategoryCard(
                      icon: Icons.nfc_rounded,
                      title: 'NFC',
                      subtitle: 'Availability & tag reads',
                      color: const Color(0xFF6200EA),
                      onTap: () => context.push('/nfc'),
                    ),
                    CategoryCard(
                      icon: Icons.sensors_rounded,
                      title: 'Sensors',
                      subtitle: 'Accelerometer, gyro & more',
                      color: const Color(0xFFD50000),
                      onTap: () => context.push('/sensors'),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeviceSummaryCard extends StatelessWidget {
  const _DeviceSummaryCard({
    required this.loading,
    required this.model,
    required this.manufacturer,
    required this.androidVersion,
    required this.sdk,
    required this.onTap,
  });

  final bool loading;
  final String model;
  final String manufacturer;
  final String androidVersion;
  final String sdk;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Material(
      color: scheme.primary,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [scheme.primary, scheme.primary.withValues(alpha: 0.8)],
            ),
          ),
          child: loading
              ? const SizedBox(
                  height: 72,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.4,
                    ),
                  ),
                )
              : Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.phone_android_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            model.isEmpty ? 'Unknown device' : model,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$manufacturer • Android $androidVersion (SDK $sdk)',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
