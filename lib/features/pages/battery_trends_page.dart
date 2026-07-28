import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/service_locator.dart';
import '../battery_info/bloc/battery_info_bloc.dart';
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
      appBar: AppBar(title: const Text('Battery Trends')),
      body: BlocBuilder<BatteryInfoBloc, BatteryInfoState>(
        builder: (context, state) {
          if (state is BatteryInfoInitial || state is BatteryInfoLoading) {
            return const Center(child: CircularProgressIndicator());
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
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  '${samples.length} samples collected',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
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
                TrendChartCard(
                  title: 'Temperature',
                  icon: Icons.thermostat_rounded,
                  color: const Color(0xFFFF6D00),
                  unit: '°C',
                  samples: samples,
                  valueKey: 'temperature',
                  minY: null,
                  maxY: null,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EmptyHistoryView extends StatelessWidget {
  const _EmptyHistoryView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.hourglass_empty_rounded,
              size: 40,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text('No history yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Background sampling runs every 30 minutes. Check back '
              'after the app has been installed a little while.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
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
              "Couldn't load battery history",
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.read<BatteryInfoBloc>().add(
                const BatteryInfoRequested(),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
