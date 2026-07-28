import 'package:flutter/material.dart';

import '../../../../core/permissions/permission_result.dart';
import '../../core/permissions/permission_status.dart';
import 'permission_metadata.dart';
import 'permission_status_chip.dart';

class PermissionCard extends StatelessWidget {
  const PermissionCard({
    super.key,
    required this.metadata,
    required this.result,
    required this.onCheck,
    required this.onRequest,
    required this.onOpenSettings,
  });

  final PermissionMetadata metadata;
  final PermissionResult result;

  final VoidCallback onCheck;
  final VoidCallback onRequest;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(metadata.icon, color: scheme.primary, size: 28),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              metadata.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          PermissionStatusChip(status: result.status),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Text(
              metadata.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: scheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 20),

            PermissionActionButtons(
              status: result.status,
              onCheck: onCheck,
              onRequest: onRequest,
              onOpenSettings: onOpenSettings,
            ),
          ],
        ),
      ),
    );
  }
}

class PermissionActionButtons extends StatelessWidget {
  const PermissionActionButtons({
    super.key,
    required this.status,
    required this.onCheck,
    required this.onRequest,
    required this.onOpenSettings,
  });

  final PermissionStatus status;

  final VoidCallback onCheck;
  final VoidCallback onRequest;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case PermissionStatus.granted:
        return _GrantedButtons(onCheck: onCheck);

      case PermissionStatus.denied:
        return _DeniedButtons(onCheck: onCheck, onRequest: onRequest);

      case PermissionStatus.permanentlyDenied:
        return _PermanentlyDeniedButtons(onOpenSettings: onOpenSettings);

      case PermissionStatus.notRequired:
        return _NotRequiredButtons(onCheck: onCheck);

      case PermissionStatus.limited:
        return _PermanentlyDeniedButtons(onOpenSettings: onOpenSettings);

      case PermissionStatus.restricted:
        return _PermanentlyDeniedButtons(onOpenSettings: onOpenSettings);
    }
  }
}

class _GrantedButtons extends StatelessWidget {
  const _GrantedButtons({required this.onCheck});

  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: OutlinedButton.icon(
        onPressed: onCheck,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text("Refresh"),
      ),
    );
  }
}

class _DeniedButtons extends StatelessWidget {
  const _DeniedButtons({required this.onCheck, required this.onRequest});

  final VoidCallback onCheck;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onCheck,
            icon: const Icon(Icons.search_rounded),
            label: const Text("Check"),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: FilledButton.icon(
            onPressed: onRequest,
            icon: const Icon(Icons.security_rounded),
            label: const Text("Request"),
          ),
        ),
      ],
    );
  }
}

class _PermanentlyDeniedButtons extends StatelessWidget {
  const _PermanentlyDeniedButtons({required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onOpenSettings,
        icon: const Icon(Icons.settings_rounded),
        label: const Text("Open Settings"),
      ),
    );
  }
}

class _NotRequiredButtons extends StatelessWidget {
  const _NotRequiredButtons({required this.onCheck});

  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: onCheck,
        icon: const Icon(Icons.info_outline_rounded),
        label: const Text("Check"),
      ),
    );
  }
}
