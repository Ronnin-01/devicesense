import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/service_locator.dart'; // Adjust path
import '../sensors/bloc/sensors_bloc.dart';
import '../sensors/bloc/sensors_event.dart';
import '../sensors/bloc/sensors_state.dart';
import '../sensors/models/sensor_reading_model.dart';
import '../shared/reusable_widgets.dart'; // Adjust path

class SensorsStreamPage extends StatelessWidget {
  const SensorsStreamPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SensorsBloc>()..add(const SensorsRequested()),
      child: const _SensorsStreamView(),
    );
  }
}

class _SensorsStreamView extends StatefulWidget {
  const _SensorsStreamView();

  @override
  State<_SensorsStreamView> createState() => _SensorsStreamViewState();
}

class _SensorsStreamViewState extends State<_SensorsStreamView> {
  @override
  void deactivate() {
    // Safety check: Stop all sensors when leaving the page to preserve battery
    context.read<SensorsBloc>().add(const SensorsStopAllSensorsRequested());
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Live Sensor Stream')),
      body: BlocConsumer<SensorsBloc, SensorsState>(
        listener: (context, state) {
          if (state is SensorsLoaded && state.hasError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.errorMessage ?? state.errorCode ?? 'Sensor Error',
                ),
                backgroundColor: scheme.error,
              ),
            );
            // Clear the error so it doesn't fire again on rebuild
            context.read<SensorsBloc>().add(
              const SensorsRefreshActiveSensorsRequested(),
            );
          }
        },
        builder: (context, state) {
          if (state is SensorsInitial || state is SensorsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is! SensorsLoaded) return const SizedBox.shrink();

          final capabilities = state.capabilities;
          if (capabilities == null || capabilities.sensors.isEmpty) {
            return const Center(
              child: Text("No sensors found on this device."),
            );
          }

          final activeList = state.activeSensors.activeSensors;
          final lastReading = state.lastReading;

          return Column(
            children: [
              // Global Controls
              _buildGlobalControls(
                context,
                state.isStreaming,
                activeList.length,
                theme,
              ),

              // The active reading header
              if (lastReading != null)
                _buildLiveReadingBanner(lastReading, theme),

              // The toggleable list of all sensors
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: capabilities.sensors.length,
                  itemBuilder: (context, index) {
                    final sensor = capabilities.sensors[index];
                    final isActive = activeList.any(
                      (a) => a.type == sensor.type,
                    );

                    return _SensorStreamTile(
                      name: sensor.name,
                      typeLabel: sensor.typeLabel,
                      type: sensor.type,
                      isActive: isActive,
                      requiresPermission: sensor.permissionRequired,
                      onToggle: (bool enable) {
                        if (enable) {
                          context.read<SensorsBloc>().add(
                            SensorsStartSensorRequested(type: sensor.type),
                          );
                        } else {
                          context.read<SensorsBloc>().add(
                            SensorsStopSensorRequested(type: sensor.type),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGlobalControls(
    BuildContext context,
    bool isStreaming,
    int activeCount,
    ThemeData theme,
  ) {
    final scheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.podcasts_rounded, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Global Stream Control',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              StatusBadgeTag(
                label: '$activeCount ACTIVE',
                color: activeCount > 0 ? Colors.green : Colors.grey,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => context.read<SensorsBloc>().add(
                    const SensorsStartAllSensorsRequested(),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Start All'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: isStreaming
                      ? () => context.read<SensorsBloc>().add(
                          const SensorsStopAllSensorsRequested(),
                        )
                      : null,
                  icon: const Icon(Icons.stop_rounded, size: 18),
                  label: const Text('Stop All'),
                  style: FilledButton.styleFrom(backgroundColor: scheme.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveReadingBanner(SensorReadingModel reading, ThemeData theme) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LATEST FRAME: ${reading.typeLabel}',
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'ACC: ${reading.accuracyLabel}',
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '[ ${reading.values.map((v) => v.toStringAsFixed(3)).join(' ,  ')} ]',
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SensorStreamTile extends StatelessWidget {
  const _SensorStreamTile({
    required this.name,
    required this.typeLabel,
    required this.type,
    required this.isActive,
    required this.requiresPermission,
    required this.onToggle,
  });

  final String name;
  final String typeLabel;
  final int type;
  final bool isActive;
  final bool requiresPermission;
  final Function(bool) onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive
              ? Colors.green.withValues(alpha: 0.5)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(
          isActive ? Icons.sensors_rounded : Icons.sensors_off_rounded,
          color: isActive ? Colors.green : scheme.outline,
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isActive ? Colors.green.shade800 : scheme.onSurface,
          ),
        ),
        subtitle: Row(
          children: [
            Text(typeLabel, style: const TextStyle(fontSize: 11)),
            if (requiresPermission) ...[
              const SizedBox(width: 6),
              const Icon(Icons.lock_rounded, size: 10, color: Colors.red),
            ],
          ],
        ),
        trailing: Switch(
          value: isActive,
          activeColor: Colors.green,
          onChanged: onToggle,
        ),
      ),
    );
  }
}
