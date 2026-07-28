import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A rounded card that groups related [InfoRow]s under a titled header.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.children,
    this.icon,
  });

  final String title;
  final IconData? icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: scheme.primary),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: scheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ...children,
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

enum TileStatus {
  supported,
  notSupported,
  enabled,
  disabled,
  charging,
  discharging,
  good,
  warning,
  unknown,
}

class ExpandableInfoTile extends StatefulWidget {
  const ExpandableInfoTile({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.description,
    this.leading,
    this.status = TileStatus.unknown,
    this.copyable = true,
  });

  final String title;
  final String value;
  final String? subtitle;
  final String? description;
  final IconData? leading;
  final TileStatus status;
  final bool copyable;

  @override
  State<ExpandableInfoTile> createState() => _ExpandableInfoTileState();
}

class _ExpandableInfoTileState extends State<ExpandableInfoTile> {
  bool _expanded = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.value));

    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text("${widget.title} copied"),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final expandable =
        widget.description != null && widget.description!.trim().isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: expandable
              ? () {
                  setState(() {
                    _expanded = !_expanded;
                  });
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    if (widget.leading != null) ...[
                      Icon(
                        widget.leading,
                        size: 22,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                    ],

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.title, style: theme.textTheme.titleSmall),
                          if (widget.subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.subtitle!,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),

                    Spacer(),

                    Expanded(
                      child: Text(
                        widget.value,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                    ),

                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          onPressed: _copy,
                          icon: const Icon(Icons.copy_rounded, size: 18),
                        ),
                      ),
                    ),

                    // if (expandable)
                    //   AnimatedRotation(
                    //     turns: _expanded ? .5 : 0,
                    //     duration: const Duration(milliseconds: 250),
                    //     child: const Padding(
                    //       padding: EdgeInsets.only(left: 6),
                    //       child: Icon(Icons.expand_more_rounded),
                    //     ),
                    //   ),
                  ],
                ),

                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: !_expanded
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Column(
                            children: [
                              Divider(color: theme.colorScheme.outlineVariant),

                              const SizedBox(height: 10),

                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  widget.description!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    height: 1.55,
                                  ),
                                ),
                              ),

                              // if (widget.copyable) ...[
                              //   const SizedBox(height: 16),

                              //   Align(
                              //     alignment: Alignment.centerRight,
                              //     child: TextButton.icon(
                              //       onPressed: _copy,
                              //       icon: const Icon(
                              //         Icons.copy_rounded,
                              //         size: 18,
                              //       ),
                              //       label: const Text("Copy"),
                              //     ),
                              //   ),
                              // ],
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A tappable card used on the dashboard grid to navigate to a hardware
/// category (Battery, Bluetooth, Sensors, ...).
class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const Spacer(),
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Generic placeholder screen for hardware categories whose native
/// implementation isn't wired up yet (Battery, Bluetooth, Wi-Fi, NFC,
/// Sensors). Swap for a real page once that platform channel exists.
class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.description,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: color),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'COMING SOON',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: color,
                    letterSpacing: 0.6,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "$title data isn't wired up yet",
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
