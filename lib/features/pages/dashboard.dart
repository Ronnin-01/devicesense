import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/service_locator.dart';
import '../device_info/bloc/device_info_bloc.dart';
import '../device_info/bloc/device_info_event.dart';
import '../device_info/bloc/device_info_state.dart';

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
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // 1. App Header
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DeviceSense',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your hardware, inspected.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [scheme.primary, scheme.tertiary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: scheme.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.memory_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Hero Summary Card (Gateway to Device Info)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
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

              // 3. Section Title
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Hardware Modules',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              // 4. Modern Bento Box Layout
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      // Row 1: Wide Battery Card
                      BentoCard(
                        isWide: true,
                        icon: Icons.battery_charging_full_rounded,
                        title: 'Battery',
                        subtitle: 'Health, capacity, & thermal trends',
                        color: const Color(0xFF00C853),
                        onTap: () => context.push('/battery'),
                      ),
                      const SizedBox(height: 14),

                      // Row 2: Wi-Fi & Bluetooth (Connectivity)
                      Row(
                        children: [
                          Expanded(
                            child: BentoCard(
                              isWide: false,
                              icon: Icons.wifi_rounded,
                              title: 'Wi-Fi',
                              subtitle: 'Networks & IPs',
                              color: const Color(0xFFFF6D00),
                              onTap: () => context.push('/wifi'),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: BentoCard(
                              isWide: false,
                              icon: Icons.bluetooth_rounded,
                              title: 'Bluetooth',
                              subtitle: 'Adapters & LE',
                              color: const Color(0xFF2979FF),
                              onTap: () => context.push('/bluetooth'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Row 3: Permissions & Sensors (System)
                      Row(
                        children: [
                          Expanded(
                            child: BentoCard(
                              isWide: false,
                              icon: Icons.admin_panel_settings_rounded,
                              title: 'Permissions',
                              subtitle: 'Access rights',
                              color: const Color(0xFFE53935),
                              onTap: () => context.push('/permissions'),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: BentoCard(
                              isWide: false,
                              icon: Icons.sensors_rounded,
                              title: 'Sensors',
                              subtitle: 'Gyro, accel',
                              color: const Color(0xFF8E24AA),
                              onTap: () => context.push('/sensors'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Row 4: Wide NFC Card
                      BentoCard(
                        isWide: true,
                        icon: Icons.nfc_rounded,
                        title: 'NFC Reader',
                        subtitle: 'Near-field availability & tag scans',
                        color: const Color(0xFF00BFA5),
                        onTap: () => context.push('/nfc'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Upgraded Hero Summary Card
// =============================================================================
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

    // Capitalize manufacturer for aesthetics
    final displayBrand = manufacturer.isNotEmpty
        ? '${manufacturer[0].toUpperCase()}${manufacturer.substring(1)}'
        : 'Unknown';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.primary.withValues(alpha: 0.75)],
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: loading
                ? const SizedBox(
                    height: 100,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.phone_android_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Full Specs',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  size: 14,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        model.isEmpty ? 'Unknown device' : model,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$displayBrand • Android $androidVersion (API $sdk)',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Reusable Bento Box Card
// =============================================================================
class BentoCard extends StatelessWidget {
  const BentoCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.isWide,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: isWide ? _buildWideLayout() : _buildSquareLayout(),
          ),
        ),
      ),
    );
  }

  // Layout for full-width items (e.g., Battery, NFC)
  Widget _buildWideLayout() {
    return Row(
      children: [
        _buildIconContainer(),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Icon(
          Icons.chevron_right_rounded,
          color: Colors.grey.withValues(alpha: 0.5),
        ),
      ],
    );
  }

  // Layout for side-by-side half items (e.g., Wi-Fi, Bluetooth)
  Widget _buildSquareLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIconContainer(),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: Colors.grey, fontSize: 12, height: 1.2),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildIconContainer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }
}
