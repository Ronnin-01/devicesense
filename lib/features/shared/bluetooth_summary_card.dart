import 'package:flutter/material.dart';

class BluetoothSummaryCard extends StatelessWidget {
  const BluetoothSummaryCard({
    super.key,
    required this.bluetoothEnabled,
    required this.permissionGranted,
    required this.deviceCount,
    required this.lastUpdated,
  });

  final bool bluetoothEnabled;
  final bool permissionGranted;
  final int deviceCount;
  final DateTime lastUpdated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  height: 62,
                  width: 62,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.bluetooth_rounded,
                    size: 34,
                    color: scheme.primary,
                  ),
                ),

                const SizedBox(width: 18),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Paired Devices",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        "$deviceCount Device${deviceCount == 1 ? "" : "s"}",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            Row(
              children: [
                Expanded(
                  child: _StatusTile(
                    icon: bluetoothEnabled
                        ? Icons.bluetooth_connected
                        : Icons.bluetooth_disabled,
                    title: "Bluetooth",
                    value: bluetoothEnabled ? "Enabled" : "Disabled",
                    color: bluetoothEnabled ? Colors.green : scheme.error,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _StatusTile(
                    icon: permissionGranted
                        ? Icons.verified_user_rounded
                        : Icons.lock_outline,
                    title: "Permission",
                    value: permissionGranted ? "Granted" : "Required",
                    color: permissionGranted ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Divider(color: scheme.outlineVariant, height: 24),

            Row(
              children: [
                Icon(Icons.schedule_rounded, size: 18, color: scheme.outline),

                const SizedBox(width: 8),

                Text(
                  "Updated ${_format(lastUpdated)}",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.outline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _format(DateTime date) {
    String pad(int value) => value.toString().padLeft(2, "0");

    return "${pad(date.hour)}:${pad(date.minute)}";
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: .12),
            child: Icon(icon, color: color, size: 20),
          ),

          const SizedBox(height: 10),

          Text(title, style: theme.textTheme.labelMedium),

          const SizedBox(height: 4),

          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
