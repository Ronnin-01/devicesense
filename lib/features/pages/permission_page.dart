import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/service_locator.dart';
import '../permissions/bloc/permission_bloc.dart';
import '../permissions/bloc/permission_event.dart';
import '../permissions/bloc/permission_state.dart';
import '../shared/permission_card.dart';
import '../shared/permission_metadata.dart';

class PermissionPage extends StatelessWidget {
  const PermissionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Permission Center")),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: PermissionCatalog.permissions.length,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final metadata = PermissionCatalog.permissions[index];

            return BlocProvider(
              create: (_) =>
                  sl<PermissionBloc>()..add(PermissionChecked(metadata.type)),
              child: _PermissionCard(metadata: metadata),
            );
          },
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({required this.metadata});

  final PermissionMetadata metadata;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PermissionBloc, PermissionState>(
      builder: (context, state) {
        if (state is PermissionLoading || state is PermissionInitial) {
          return const _LoadingCard();
        }

        if (state is PermissionError) {
          return _ErrorCard(message: state.message, metadata: metadata);
        }

        final result = (state as PermissionLoaded).result;

        return PermissionCard(
          metadata: metadata,
          result: result,
          onCheck: () {
            context.read<PermissionBloc>().add(
              PermissionChecked(metadata.type),
            );
          },
          onRequest: () {
            context.read<PermissionBloc>().add(
              PermissionRequested(metadata.type),
            );
          },
          onOpenSettings: () {
            context.read<PermissionBloc>().add(
              const PermissionSettingsOpened(),
            );
          },
        );
      },
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: SizedBox(
        height: 170,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.metadata, required this.message});

  final PermissionMetadata metadata;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(metadata.icon, size: 40),
            const SizedBox(height: 12),
            Text(
              metadata.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
