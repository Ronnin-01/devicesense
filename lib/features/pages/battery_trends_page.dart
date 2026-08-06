import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/theme.dart';
import '../../core/di/service_locator.dart';
import '../battery_info/bloc/battery_info_bloc.dart';
import '../shared/reusable_widgets.dart';
import '../shared/trend_chart_card.dart';

class BatteryTrendsPage extends StatelessWidget {
  const BatteryTrendsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BatteryInfoBloc>()..add(const BatteryInfoRequested()),
      child: const _BatteryTrendsView(),
    );
  }
}

class _BatteryTrendsView extends StatelessWidget {
  const _BatteryTrendsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Battery Trends'),
        actions: [
          IconButton.filledTonal(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh trends',
            onPressed: () => context.read<BatteryInfoBloc>().add(
              const BatteryInfoRequested(),
            ),
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
                  Text('Loading historical data...'),
                ],
              ),
            );
          }

          if (state is BatteryInfoError) {
            return _ErrorView(message: state.message);
          }

          final samples = (state as BatteryInfoLoaded).history;

          if (samples.isEmpty) {
            return const _EmptyHistoryView();
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<BatteryInfoBloc>().add(const BatteryInfoRequested());
              await context.read<BatteryInfoBloc>().stream.firstWhere(
                (s) => s is! BatteryInfoLoading,
              );
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Metadata Summary Banner
                _buildSampleSummaryBanner(context, samples.length),
                const SizedBox(height: 24),

                // Battery Level Chart
                TrendChartCard(
                  title: 'Battery Level',
                  icon: Icons.battery_charging_full_rounded,
                  color: const Color(0xFF00C853),
                  unit: '%',
                  samples: samples,
                  valueKey: 'level',
                  minY: 0,
                  maxY: 100,
                ),
                const SizedBox(height: 16),

                // Temperature Chart
                TrendChartCard(
                  title: 'Temperature',
                  icon: Icons.thermostat_rounded,
                  color: const Color(
                    0xFFFF6D00,
                  ), // Keeping original brand color
                  unit: '°C',
                  samples: samples,
                  valueKey: 'temperature',
                  minY: null,
                  maxY: null,
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSampleSummaryBanner(BuildContext context, int count) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history_rounded,
              color: colorScheme.onPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Background Sampling Active',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$count samples collected so far',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimaryContainer.withValues(
                      alpha: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Modern Empty State View
// =============================================================================
class _EmptyHistoryView extends StatelessWidget {
  const _EmptyHistoryView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.hourglass_empty_rounded,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text('No History Yet', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Background sampling runs every 30 minutes. Check back after the app has been installed for a while to see your battery trends.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.read<BatteryInfoBloc>().add(
                const BatteryInfoRequested(),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Modern Error State View
// =============================================================================
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ModernSectionCard(
          title: "Couldn't Load Trends",
          icon: Icons.error_outline_rounded,
          backgroundColor: theme.colorScheme.errorContainer,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onErrorContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                ),
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
}
