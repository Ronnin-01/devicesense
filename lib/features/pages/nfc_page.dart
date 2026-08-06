import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/theme.dart';
import '../../core/di/service_locator.dart';
import '../nfc/bloc/nfc_capabilities_bloc/nfc_capabilities_bloc.dart';
import '../nfc/bloc/nfc_capabilities_bloc/nfc_capabilities_event.dart';
import '../nfc/bloc/nfc_capabilities_bloc/nfc_capabilities_state.dart';
import '../nfc/bloc/nfc_reader_bloc/nfc_reader_bloc.dart';
import '../nfc/bloc/nfc_reader_bloc/nfc_reader_event.dart';
import '../nfc/bloc/nfc_reader_bloc/nfc_reader_state.dart';
import '../nfc/models/nfc_record_model.dart';
import '../shared/reusable_widgets.dart';

class NfcPage extends StatelessWidget {
  const NfcPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              sl<NfcCapabilitiesBloc>()..add(const NfcCapabilitiesRequested()),
        ),
        BlocProvider(create: (_) => sl<NfcReaderBloc>()),
      ],
      child: const _NfcView(),
    );
  }
}

class _NfcView extends StatefulWidget {
  const _NfcView();

  @override
  State<_NfcView> createState() => _NfcViewState();
}

class _NfcViewObserver extends StatefulWidget {
  const _NfcViewObserver();

  @override
  State<_NfcViewObserver> createState() => _NfcViewObserverState();
}

class _NfcViewObserverState extends State<_NfcViewObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Battery Safeguard: Turn off NFC reader controller as soon as app goes to background
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      context.read<NfcReaderBloc>().add(const NfcReaderStopped());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('NFC Inspection'),
        actions: [
          IconButton.filledTonal(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              context.read<NfcCapabilitiesBloc>().add(
                const NfcCapabilitiesRequested(),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<NfcCapabilitiesBloc>().add(
            const NfcCapabilitiesRequested(),
          );
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. Live Reader Active Card
            _buildReaderHeroCard(context, scheme, theme),
            const SizedBox(height: 20),

            // 2. Detected Tag Details
            _buildTagDetailsSection(context, theme),
            const SizedBox(height: 20),

            // 3. Adapter Hardware Capabilities
            ModernSectionCard(
              title: 'Adapter Hardware',
              icon: Icons.developer_board_rounded,
              children: [
                BlocBuilder<NfcCapabilitiesBloc, NfcCapabilitiesState>(
                  builder: (context, state) {
                    if (state is NfcCapabilitiesLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is NfcCapabilitiesLoaded) {
                      final caps = state.capabilities;
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final halfWidth = (constraints.maxWidth - 12) / 2;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              ModernDetailTile(
                                width: halfWidth,
                                label: 'NFC Support',
                                value: caps.nfcSupported
                                    ? 'Present'
                                    : 'Not Supported',
                                icon: Icons.nfc_rounded,
                                isSupported: caps.nfcSupported,
                              ),
                              ModernDetailTile(
                                width: halfWidth,
                                label: 'Adapter State',
                                value: caps.nfcState,
                                icon: Icons.power_settings_new_rounded,
                                isSupported: caps.nfcEnabled,
                              ),
                              ModernDetailTile(
                                width: halfWidth,
                                label: 'NDEF Messaging',
                                value: caps.isNdefSupported
                                    ? 'Supported'
                                    : 'Unsupported',
                                icon: Icons.message_rounded,
                                isSupported: caps.isNdefSupported,
                              ),
                              ModernDetailTile(
                                width: halfWidth,
                                label: 'Mifare Classic',
                                value: caps.isMifareClassicSupported
                                    ? 'Supported'
                                    : 'No Chipset Support',
                                icon: Icons.credit_card_rounded,
                                isSupported: caps.isMifareClassicSupported,
                              ),
                              ModernDetailTile(
                                width: halfWidth,
                                label: 'Host Card Emulation',
                                value: caps.isHceSupported
                                    ? 'Supported'
                                    : 'Unsupported',
                                icon: Icons.contactless_rounded,
                                isSupported: caps.isHceSupported,
                              ),
                            ],
                          );
                        },
                      );
                    }
                    return const Text('Unable to load NFC capabilities');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReaderHeroCard(
    BuildContext context,
    ColorScheme scheme,
    ThemeData theme,
  ) {
    return BlocBuilder<NfcReaderBloc, NfcReaderState>(
      builder: (context, state) {
        final isReading = state is NfcReaderLoaded && state.snapshot.isReading;
        // 1. Capture the loading state to prevent button-spamming
        final isLoading = state is NfcReaderLoading;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isReading
                  ? [Colors.teal.shade600, Colors.teal.shade900]
                  : [scheme.primary, scheme.tertiary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: (isReading ? Colors.teal : scheme.primary).withValues(
                  alpha: 0.3,
                ),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isReading ? Icons.sensors_rounded : Icons.nfc_rounded,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isReading ? 'Ready to Scan Tag' : 'NFC Tag Reader',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          isReading
                              ? 'Hold tag near back of device...'
                              : 'Tap start to enable polling mode',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: isReading
                        ? Colors.teal.shade900
                        : scheme.primary,
                    // 2. Visually disable the button while loading
                    disabledBackgroundColor: Colors.white.withValues(
                      alpha: 0.5,
                    ),
                  ),
                  // 3. Prevent execution if already loading
                  onPressed: isLoading
                      ? null
                      : () {
                          if (isReading) {
                            context.read<NfcReaderBloc>().add(
                              const NfcReaderStopped(),
                            );
                          } else {
                            context.read<NfcReaderBloc>().add(
                              const NfcReaderStarted(),
                            );
                          }
                        },
                  icon: isLoading
                      ? Center(
                          child: const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : Icon(
                          isReading ? Icons.stop_rounded : Icons.radar_rounded,
                        ),
                  label: Text(
                    isLoading
                        ? 'Connecting to Adapter...'
                        : (isReading ? 'Cancel Scan' : 'Start Reading Tag'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTagDetailsSection(BuildContext context, ThemeData theme) {
    return BlocBuilder<NfcReaderBloc, NfcReaderState>(
      builder: (context, state) {
        if (state is NfcReaderLoaded &&
            state.snapshot.lastDetectedTag != null) {
          final tag = state.snapshot.lastDetectedTag!;
          return ModernSectionCard(
            title: 'Discovered Tag Details',
            icon: Icons.style_rounded,
            children: [_TagDetailsCard(tag: tag)],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _NfcViewState extends State<_NfcView> {
  @override
  Widget build(BuildContext context) {
    return const _NfcViewObserver();
  }
}

class _TagDetailsCard extends StatelessWidget {
  const _TagDetailsCard({required this.tag});

  final NfcTagModel tag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'UID: ${tag.id}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            StatusBadgeTag(
              label: tag.isWritable ? 'WRITABLE' : 'READ-ONLY',
              color: tag.isWritable ? Colors.green : Colors.amber.shade800,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: tag.techs
              .map((tech) => StatusBadgeTag(label: tech, color: scheme.primary))
              .toList(),
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final halfWidth = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ModernDetailTile(
                  width: halfWidth,
                  label: 'Max Capacity',
                  value: '${tag.maxSize} Bytes',
                  icon: Icons.sd_card_rounded,
                ),
                ModernDetailTile(
                  width: halfWidth,
                  label: 'Can Lock',
                  value: tag.canMakeReadOnly ? 'Yes' : 'No',
                  icon: Icons.lock_clock_rounded,
                ),
              ],
            );
          },
        ),
        if (tag.records.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'NDEF Payload Records (${tag.records.length})',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...tag.records.map(
            (rec) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Record Type: ${rec.type}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'TNF: ${rec.tnf}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  if (rec.parsedText.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      rec.parsedText,
                      style: TextStyle(
                        color: scheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    'HEX: ${rec.payloadHex}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
