import 'package:flutter/material.dart';

class PairedDeviceCard extends StatelessWidget {
  const PairedDeviceCard({
    super.key,
    required this.device,
    required this.onTap,
  });

  final Map<String, dynamic> device;
  final VoidCallback onTap;

  IconData get _icon {
    switch ((device["category"] ?? "").toString()) {
      case "audio":
        return Icons.headphones_rounded;

      case "computer":
        return Icons.laptop_mac_rounded;

      case "phone":
        return Icons.smartphone_rounded;

      case "wearable":
        return Icons.watch_rounded;

      case "peripheral":
        return Icons.keyboard_rounded;

      case "health":
        return Icons.monitor_heart_rounded;

      case "networking":
        return Icons.router_rounded;

      case "imaging":
        return Icons.camera_alt_rounded;

      case "toy":
        return Icons.toys_rounded;

      default:
        return Icons.bluetooth_rounded;
    }
  }

  Color _iconColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    switch ((device["category"] ?? "").toString()) {
      case "audio":
        return Colors.deepPurple;

      case "computer":
        return Colors.blue;

      case "phone":
        return Colors.green;

      case "wearable":
        return Colors.orange;

      case "health":
        return Colors.red;

      case "networking":
        return Colors.teal;

      default:
        return scheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final name = device["name"] ?? "Unknown Device";
    final deviceClass = device["deviceClass"] ?? "Unknown";
    final bondState = device["bondState"] ?? "";
    final type = device["type"] ?? "";

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                height: 58,
                width: 58,
                decoration: BoxDecoration(
                  color: _iconColor(context).withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(_icon, size: 28, color: _iconColor(context)),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      deviceClass,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Chip(label: bondState),

                        _Chip(label: type),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}
