import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../bluetooth_info/models/bluetooth_device_model.dart';

// =============================================================================
// Reusable Modern Section Card
// =============================================================================
class ModernSectionCard extends StatelessWidget {
  const ModernSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.backgroundColor,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: backgroundColor ?? theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 22),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Reusable Modern Grid Detail Tile
// =============================================================================
class ModernDetailTile extends StatelessWidget {
  const ModernDetailTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.width = 150,
    this.isSupported,
  });

  final String label;
  final String value;
  final IconData icon;
  final double width;
  final bool? isSupported;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Auto-color capabilities if isSupported is passed
    Color iconColor = theme.colorScheme.primary;
    if (isSupported == true) iconColor = Colors.green;
    if (isSupported == false) iconColor = Colors.red;

    return Container(
      width: width,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
// Reusable Status Badge Tag
// =============================================================================
class StatusBadgeTag extends StatelessWidget {
  const StatusBadgeTag({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

// =============================================================================
// Comprehensive Bluetooth Device Card (Uses ALL model fields)
// =============================================================================

// =============================================================================
// Dynamic 4-Bar Signal Indicator Widget
// =============================================================================
class SignalBarIndicator extends StatelessWidget {
  const SignalBarIndicator({
    super.key,
    required this.rssi,
    required this.signalStrengthLabel,
  });

  final int rssi;
  final String signalStrengthLabel;

  /// Calculates the 0–4 signal level matching the Kotlin native threshold logic:
  /// Level 4 (Excellent): >= -60 dBm
  /// Level 3 (Good)     : >= -70 dBm
  /// Level 2 (Fair)     : >= -80 dBm
  /// Level 1 (Weak)     : < -80 dBm
  /// Level 0 (Unknown)  : Invalid / Short.MIN_VALUE
  int get _signalLevel {
    final label = signalStrengthLabel.toLowerCase();

    if (label == 'excellent' || (rssi >= -60 && rssi != -32768)) return 4;
    if (label == 'good' || rssi >= -70) return 3;
    if (label == 'fair' || rssi >= -80) return 2;
    if (label == 'weak' || (rssi < -80 && rssi > -120)) return 1;

    return 0; // Unknown or invalid RSSI
  }

  Color _getSignalColor(BuildContext context, int level) {
    switch (level) {
      case 4:
      case 3:
        return Colors.green.shade600;
      case 2:
        return Colors.amber.shade700;
      case 1:
        return Colors.red.shade600;
      default:
        return Theme.of(context).colorScheme.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final level = _signalLevel;
    final activeColor = _getSignalColor(context, level);
    final inactiveColor = Theme.of(
      context,
    ).colorScheme.outlineVariant.withValues(alpha: 0.3);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (index) {
        final barLevel = index + 1;
        final isFilled = barLevel <= level;
        // Ascending heights: 6px, 10px, 14px, 18px
        final double barHeight = 3.0 + (index * 3.0);

        return Container(
          width: 3.0,
          height: barHeight,
          margin: const EdgeInsets.symmetric(horizontal: 1.2),
          decoration: BoxDecoration(
            color: isFilled ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}

// =============================================================================
// Production-Ready Bluetooth Device Card
// =============================================================================
class BluetoothDeviceCard extends StatelessWidget {
  const BluetoothDeviceCard({super.key, required this.device, this.onTap});

  final BluetoothDeviceModel device;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isBle = device.source == 'ble';
    final isBonded = device.bondState == 'BOND_BONDED';
    final isNameless = device.name == 'Unknown Device';

    final displayName = isNameless && device.shortAddress.isNotEmpty
        ? 'Device-${device.shortAddress}'
        : device.name;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: BorderSide(
          color: isBonded
              ? colorScheme.primary.withValues(alpha: 0.35)
              : colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isBonded
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getCategoryIcon(device.category),
            color: isBonded
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                displayName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  fontStyle: isNameless ? FontStyle.italic : FontStyle.normal,
                  color: isNameless
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SignalBarIndicator(
              rssi: device.rssi,
              signalStrengthLabel: device.signalStrength,
            ),
            const SizedBox(width: 8),
            if (isBonded) ...[
              const SizedBox(width: 6),
              Tooltip(
                message: 'Bonded Device',
                child: Icon(
                  Icons.link_rounded,
                  size: 16,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            children: [
              // Dynamic Signal Bar Indicator
              // SignalBarIndicator(
              //   rssi: device.rssi,
              //   signalStrengthLabel: device.signalStrength,
              // ),
              // const SizedBox(width: 8),

              // Numeric RSSI & Label Text
              Text(
                device.rssi == -32768 ? 'N/A' : '${device.rssi} dBm',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${device.signalStrength})',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),

              const Spacer(),

              // Protocol & Type Badges
              StatusBadgeTag(
                label: device.source,
                color: isBle
                    ? Colors.blue.shade700
                    : Colors.deepPurple.shade600,
              ),
              const SizedBox(width: 4),
              StatusBadgeTag(label: device.type, color: Colors.teal.shade700),
            ],
          ),
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(AppTheme.radiusMedium),
                bottomRight: Radius.circular(AppTheme.radiusMedium),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SpecRow(label: 'MAC Address', value: device.address),
                _SpecRow(label: 'Bond State', value: device.bondState),
                _SpecRow(label: 'Device Class', value: device.deviceClass),
                _SpecRow(label: 'Category', value: device.category),
                _SpecRow(
                  label: 'Signal Quality',
                  value: '${device.signalStrength} (${device.rssi} dBm)',
                ),
                _SpecRow(
                  label: 'Discovered At',
                  value: DateTime.fromMillisecondsSinceEpoch(
                    device.timestamp,
                  ).toLocal().toString().split('.')[0],
                ),
                if (onTap != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.info_outline_rounded, size: 18),
                      label: const Text('View Full Details'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('audio') ||
        cat.contains('headset') ||
        cat.contains('headphone')) {
      return Icons.headphones_rounded;
    }
    if (cat.contains('phone')) return Icons.smartphone_rounded;
    if (cat.contains('computer') || cat.contains('laptop')) {
      return Icons.computer_rounded;
    }
    if (cat.contains('wearable') || cat.contains('watch')) {
      return Icons.watch_rounded;
    }
    if (cat.contains('health')) return Icons.monitor_heart_rounded;
    return Icons.bluetooth_rounded;
  }
}

class _SpecRow extends StatelessWidget {
  const _SpecRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          SelectableText(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
