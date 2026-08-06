import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/service_locator.dart';
import '../permissions/bloc/permission_bloc.dart';
import '../permissions/bloc/permission_event.dart';
import '../permissions/bloc/permission_state.dart';
import '../shared/permission_metadata.dart';

class PermissionPage extends StatelessWidget {
  const PermissionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Permission Center")),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header Banner
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [scheme.primary, scheme.tertiary],
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
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_rounded,
                        size: 36,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'System Access',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manage OS-level permissions required to read hardware states.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Permissions List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final metadata = PermissionCatalog.permissions[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: BlocProvider(
                    create: (_) =>
                        sl<PermissionBloc>()
                          ..add(PermissionChecked(metadata.type)),
                    child: _PermissionCard(metadata: metadata),
                  ),
                );
              }, childCount: PermissionCatalog.permissions.length),
            ),
          ),

          // Bottom Padding
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

// =============================================================================
// Modern Permission Card (Handles BLoC State)
// =============================================================================
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

        return _buildInteractiveCard(context, result);
      },
    );
  }

  Widget _buildInteractiveCard(BuildContext context, dynamic result) {
    final theme = Theme.of(context);
    final isGranted = result.isGranted;
    final isPermDenied = result.isPermanentlyDenied;

    // Dynamic styling based on status
    final Color statusColor = isGranted
        ? Colors.green
        : (isPermDenied ? Colors.orange.shade700 : theme.colorScheme.error);

    final Color bgColor = isGranted
        ? Colors.green.withValues(alpha: 0.05)
        : theme.colorScheme.surfaceContainerHigh;

    final Color borderColor = isGranted
        ? Colors.green.withValues(alpha: 0.3)
        : theme.colorScheme.outlineVariant.withValues(alpha: 0.5);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Icon, Title, Status Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(metadata.icon, color: statusColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    metadata.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _StatusBadge(result: result, color: statusColor),
              ],
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              metadata.description,
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Action Buttons Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // 1. Check Button (Always present to refresh native state)
                TextButton.icon(
                  onPressed: () => context.read<PermissionBloc>().add(
                    PermissionChecked(metadata.type),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Check'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurfaceVariant,
                  ),
                ),

                const Spacer(),

                // 2. Main Action Button (Request or Settings)
                if (!isGranted) ...[
                  if (isPermDenied)
                    FilledButton.tonalIcon(
                      onPressed: () => context.read<PermissionBloc>().add(
                        const PermissionSettingsOpened(),
                      ),
                      icon: const Icon(Icons.settings_rounded, size: 18),
                      label: const Text('Open Settings'),
                    )
                  else
                    FilledButton.icon(
                      onPressed: () => context.read<PermissionBloc>().add(
                        PermissionRequested(metadata.type),
                      ),
                      icon: const Icon(Icons.verified_user_rounded, size: 18),
                      label: const Text('Request Access'),
                    ),
                ] else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: Colors.green.shade800,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Active',
                          style: TextStyle(
                            color: Colors.green.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Helper Widgets
// =============================================================================
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.result, required this.color});

  final dynamic result;
  final Color color;

  String get _label {
    if (result.isGranted) return 'GRANTED';
    if (result.isPermanentlyDenied) return 'DENIED (PERM)';
    if (result.isRestricted) return 'RESTRICTED';
    if (result.isNotRequired) return 'NOT REQUIRED';
    return 'DENIED';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.metadata, required this.message});

  final PermissionMetadata metadata;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.error.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(metadata.icon, size: 32, color: scheme.error),
          const SizedBox(height: 12),
          Text(
            metadata.title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: scheme.onErrorContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onErrorContainer,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            onPressed: () => context.read<PermissionBloc>().add(
              PermissionChecked(metadata.type),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
