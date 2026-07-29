import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PairedDeviceDetailsSheet extends StatelessWidget {
  const PairedDeviceDetailsSheet({super.key, required this.device});

  final Map<String, dynamic> device;

  static Future<void> show(BuildContext context, Map<String, dynamic> device) {
    return showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => PairedDeviceDetailsSheet(device: device),
    );
  }

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
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final supportsAudio = device["supportsAudio"] == true;
    final supportsNetwork = device["supportsNetwork"] == true;
    final supportsObex = device["supportsObex"] == true;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: CircleAvatar(
              radius: 34,
              backgroundColor: _iconColor(context).withValues(alpha: .12),
              child: Icon(_icon, size: 34, color: _iconColor(context)),
            ),
          ),

          const SizedBox(height: 20),

          Center(
            child: Text(
              device["name"] ?? "Unknown Device",
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 4),

          Center(
            child: Text(
              device["deviceClass"] ?? "",
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),

          const SizedBox(height: 28),

          _InfoTile(
            title: "Bluetooth Address",
            value: device["address"] ?? "",
            copyable: true,
          ),

          _InfoTile(title: "Bond State", value: device["bondState"] ?? ""),

          _InfoTile(title: "Connection Type", value: device["type"] ?? ""),

          _InfoTile(title: "Device Class", value: device["deviceClass"] ?? ""),

          const SizedBox(height: 28),

          Text(
            "Capabilities",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 14),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _CapabilityChip(label: "Audio", supported: supportsAudio),
              _CapabilityChip(label: "Networking", supported: supportsNetwork),
              _CapabilityChip(
                label: "Object Transfer",
                supported: supportsObex,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.title,
    required this.value,
    this.copyable = false,
  });

  final String title;
  final String value;
  final bool copyable;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        title: Text(title),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            value.isEmpty ? "Unknown" : value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        trailing: copyable
            ? IconButton(
                icon: const Icon(Icons.copy_rounded),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: value));

                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Copied"),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              )
            : null,
      ),
    );
  }
}

class _CapabilityChip extends StatelessWidget {
  const _CapabilityChip({required this.label, required this.supported});

  final String label;
  final bool supported;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Chip(
      avatar: Icon(
        supported ? Icons.check_circle : Icons.cancel,
        size: 18,
        color: supported ? Colors.green : scheme.error,
      ),
      label: Text(label),
    );
  }
}
