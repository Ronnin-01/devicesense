import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../bluetooth_info/models/bluetooth_device_model.dart';
import 'info_chip.dart';
import 'signal_bar.dart';

class DeviceCard extends StatelessWidget {
  const DeviceCard({super.key, required this.device});

  final BluetoothDeviceModel device;

  Color _signalColor(String strength, ColorScheme scheme) => switch (strength) {
    'Excellent' => const Color(0xFF00C853),
    'Good' => const Color(0xFF64DD17),
    'Fair' => const Color(0xFFFF6D00),
    'Weak' => scheme.error,
    _ => scheme.onSurfaceVariant,
  };

  double _signalFill(String strength) => switch (strength) {
    'Excellent' => 1.0,
    'Good' => 0.75,
    'Fair' => 0.5,
    'Weak' => 0.25,
    _ => 0.0,
  };

  IconData _categoryIcon(String category) => switch (category) {
    'audio' => Icons.headphones_rounded,
    'computer' => Icons.computer_rounded,
    'phone' => Icons.smartphone_rounded,
    'wearable' => Icons.watch_rounded,
    'peripheral' => Icons.keyboard_rounded,
    'health' => Icons.monitor_heart_rounded,
    'imaging' => Icons.camera_alt_rounded,
    'networking' => Icons.router_rounded,
    'toy' => Icons.toys_rounded,
    'ble' => Icons.bluetooth_searching_rounded,
    _ => Icons.devices_rounded,
  };

  Future<void> _copyToClipboard(
    BuildContext context,
    String text,
    String label,
  ) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$label copied'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final signalColor = _signalColor(device.signalStrength, scheme);
    final signalFill = _signalFill(device.signalStrength);
    final isBonded = device.bondState == 'Bonded';
    final lastSeen = DateTime.fromMillisecondsSinceEpoch(device.timestamp);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onLongPress: () => _copyToClipboard(context, device.address, 'Address'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- Header row ----------------------------------------
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _categoryIcon(device.category),
                      color: scheme.onPrimaryContainer,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.name,
                          style: theme.textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        GestureDetector(
                          onTap: () => _copyToClipboard(
                            context,
                            device.address,
                            'Address',
                          ),
                          child: Row(
                            children: [
                              Text(
                                device.address,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontFamily: 'monospace',
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.copy_rounded,
                                size: 12,
                                color: scheme.onSurfaceVariant.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // RSSI + signal label
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${device.rssi} dBm',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: signalColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SignalBar(fill: signalFill, color: signalColor),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // ---- Detail chips row ----------------------------------
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  InfoChip(
                    label: device.signalStrength,
                    color: signalColor,
                    icon: Icons.signal_cellular_alt_rounded,
                  ),
                  InfoChip(
                    label: device.type,
                    color: scheme.primary,
                    icon: Icons.bluetooth_rounded,
                  ),
                  InfoChip(
                    label: device.deviceClass,
                    color: scheme.secondary,
                    icon: _categoryIcon(device.category),
                  ),
                  if (isBonded)
                    InfoChip(
                      label: 'Paired',
                      color: const Color(0xFF00C853),
                      icon: Icons.link_rounded,
                    )
                  else
                    InfoChip(
                      label: device.bondState,
                      color: scheme.onSurfaceVariant,
                      icon: Icons.link_off_rounded,
                    ),
                ],
              ),

              const SizedBox(height: 10),

              // ---- Footer row: last seen timestamp -------------------
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 13,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Last seen ${_formatTime(lastSeen)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inSeconds < 10) return 'just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }
}
