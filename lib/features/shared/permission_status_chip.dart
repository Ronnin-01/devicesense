import 'package:flutter/material.dart';

import '../../../../core/permissions/permission_status.dart';

/// Displays the current runtime permission status.
///
/// Uses Material 3 colors and animates smoothly whenever the status changes.
class PermissionStatusChip extends StatelessWidget {
  const PermissionStatusChip({super.key, required this.status});

  final PermissionStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final config = switch (status) {
      PermissionStatus.granted => (
        label: 'Granted',
        icon: Icons.check_circle_rounded,
        background: Colors.green.withValues(alpha: .12),
        foreground: Colors.green,
      ),

      PermissionStatus.denied => (
        label: 'Denied',
        icon: Icons.cancel_rounded,
        background: Colors.orange.withValues(alpha: .12),
        foreground: Colors.orange,
      ),

      PermissionStatus.permanentlyDenied => (
        label: 'Permanently Denied',
        icon: Icons.block_rounded,
        background: scheme.errorContainer,
        foreground: scheme.error,
      ),

      PermissionStatus.notRequired => (
        label: 'Not Required',
        icon: Icons.info_outline_rounded,
        background: Colors.blue.withValues(alpha: .12),
        foreground: Colors.blue,
      ),

      PermissionStatus.restricted => (
        label: 'Restricted',
        icon: Icons.cancel,
        background: Colors.red.withValues(alpha: .12),
        foreground: Colors.red,
      ),

      PermissionStatus.limited => (
        label: 'Limited',
        icon: Icons.back_hand_rounded,
        background: Colors.yellow.withValues(alpha: .12),
        foreground: Colors.yellow,
      ),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: Container(
        key: ValueKey(status),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: config.background,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: config.foreground.withValues(alpha: .18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(config.icon, size: 16, color: config.foreground),
            const SizedBox(width: 6),
            Text(
              config.label,
              style: TextStyle(
                color: config.foreground,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
