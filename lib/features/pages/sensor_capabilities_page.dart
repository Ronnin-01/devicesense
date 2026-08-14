import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/di/service_locator.dart'; // Adjust path
import '../sensors/bloc/sensors_bloc.dart';
import '../sensors/bloc/sensors_event.dart';
import '../sensors/bloc/sensors_state.dart';
import '../sensors/models/sensor_capability_model.dart';
import '../shared/reusable_widgets.dart'; // Adjust path

class SensorsCapabilitiesPage extends StatelessWidget {
  const SensorsCapabilitiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SensorsBloc>()..add(const SensorsRequested()),
      child: const _SensorsCapabilitiesView(),
    );
  }
}

class _SensorsCapabilitiesView extends StatelessWidget {
  const _SensorsCapabilitiesView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor Hardware'),
        actions: [
          IconButton.filledTonal(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Hardware Catalog',
            onPressed: () => context.read<SensorsBloc>().add(
              const SensorsCapabilitiesRequested(forceRefresh: true),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<SensorsBloc, SensorsState>(
        builder: (context, state) {
          if (state is SensorsInitial || state is SensorsLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Interrogating hardware catalog...'),
                ],
              ),
            );
          }

          if (state is SensorsError && !state.hasSnapshot) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ModernSectionCard(
                  title: "Hardware Query Failed",
                  icon: Icons.error_outline_rounded,
                  backgroundColor: scheme.errorContainer,
                  children: [
                    Text(
                      state.message,
                      style: TextStyle(
                        color: scheme.onErrorContainer,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is! SensorsLoaded) return const SizedBox.shrink();

          final capabilities = state.capabilities;
          if (capabilities == null || !capabilities.supported) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.sensors_off_rounded,
                    size: 64,
                    color: scheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sensor Service Unavailable',
                    style: theme.textTheme.titleLarge,
                  ),
                  const Text(
                    'This device does not support hardware sensor pooling.',
                  ),
                ],
              ),
            );
          }

          final sensorsList = capabilities.sensors;

          return RefreshIndicator(
            onRefresh: () async {
              context.read<SensorsBloc>().add(
                const SensorsCapabilitiesRequested(forceRefresh: true),
              );
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. Hero Navigation Banner
                _buildStreamHeroBanner(
                  context,
                  scheme,
                  theme,
                  capabilities.sensorCount,
                ),
                const SizedBox(height: 24),

                // 2. Capabilities Section Header
                Row(
                  children: [
                    Icon(
                      Icons.developer_board_rounded,
                      size: 20,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Hardware Catalog',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    StatusBadgeTag(
                      label: 'Android SDK ${capabilities.sdkInt}',
                      color: scheme.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 3. Sensor List
                ...sensorsList.map(
                  (sensor) => _SensorCatalogCard(sensor: sensor),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStreamHeroBanner(
    BuildContext context,
    ColorScheme scheme,
    ThemeData theme,
    int count,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => context.push('/sensors/stream'),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.stream_rounded,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live Sensor Stream',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Toggle and monitor $count hardware sensors in real-time.',
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
}

class _SensorCatalogCard extends StatelessWidget {
  const _SensorCatalogCard({required this.sensor});

  final SensorCapabilityModel sensor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final requiresPermission = sensor.permissionRequired;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: BorderSide(
          color: requiresPermission
              ? scheme.error.withValues(alpha: 0.3)
              : Colors.transparent,
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _getCategoryColor(
              sensor.category,
              scheme,
            ).withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getCategoryIcon(sensor.category),
            color: _getCategoryColor(sensor.category, scheme),
            size: 24,
          ),
        ),
        title: Text(
          sensor.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Row(
            children: [
              Text(
                'Type: ${sensor.type}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              StatusBadgeTag(
                label: sensor.category,
                color: _getCategoryColor(sensor.category, scheme),
              ),
              if (requiresPermission) ...[
                const SizedBox(width: 4),
                const StatusBadgeTag(label: 'SECURED', color: Colors.red),
              ],
            ],
          ),
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(AppTheme.radiusMedium),
                bottomRight: Radius.circular(AppTheme.radiusMedium),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (requiresPermission) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: scheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lock_rounded,
                          size: 16,
                          color: scheme.onErrorContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            sensor.permissionReason,
                            style: TextStyle(
                              fontSize: 11,
                              color: scheme.onErrorContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                LayoutBuilder(
                  builder: (context, constraints) {
                    final halfWidth = (constraints.maxWidth - 12) / 2;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        ModernDetailTile(
                          width: halfWidth,
                          label: 'Vendor',
                          value: sensor.vendor,
                          icon: Icons.precision_manufacturing_rounded,
                        ),
                        ModernDetailTile(
                          width: halfWidth,
                          label: 'Label',
                          value: sensor.typeLabel,
                          icon: Icons.label_rounded,
                        ),
                        ModernDetailTile(
                          width: halfWidth,
                          label: 'Mode',
                          value: sensor.reportingMode,
                          icon: Icons.data_usage_rounded,
                        ),
                        ModernDetailTile(
                          width: halfWidth,
                          label: 'String Type',
                          value: sensor.stringType,
                          icon: Icons.text_snippet_rounded,
                        ),
                        ModernDetailTile(
                          width: halfWidth,
                          label: 'Max Range',
                          value: '${sensor.maximumRange}',
                          icon: Icons.linear_scale_rounded,
                        ),
                        ModernDetailTile(
                          width: halfWidth,
                          label: 'Resolution',
                          value: '${sensor.resolution}',
                          icon: Icons.zoom_in_rounded,
                        ),
                        ModernDetailTile(
                          width: halfWidth,
                          label: 'Power',
                          value: '${sensor.power} mA',
                          icon: Icons.bolt_rounded,
                        ),
                        ModernDetailTile(
                          width: halfWidth,
                          label: 'Wake-Up',
                          value: sensor.wakeUpSensor ? 'Yes' : 'No',
                          icon: Icons.alarm_rounded,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category, ColorScheme scheme) {
    switch (category.toLowerCase()) {
      case 'motion':
        return Colors.blue.shade700;
      case 'orientation':
        return Colors.purple.shade700;
      case 'environment':
        return Colors.teal.shade700;
      case 'context':
        return Colors.orange.shade800;
      case 'health':
        return Colors.red.shade700;
      case 'system':
        return Colors.grey.shade700;
      default:
        return scheme.primary;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'motion':
        return Icons.run_circle_rounded;
      case 'orientation':
        return Icons.screen_rotation_rounded;
      case 'environment':
        return Icons.thermostat_rounded;
      case 'context':
        return Icons.directions_walk_rounded;
      case 'health':
        return Icons.monitor_heart_rounded;
      case 'system':
        return Icons.memory_rounded;
      default:
        return Icons.sensors_rounded;
    }
  }
}
