import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_responsive.dart';
import '../../../../core/theme/mc_spacing.dart';
import '../../../../core/theme/mc_text_styles.dart';
import '../../../../core/widgets/mc_button.dart';
import '../../../../core/widgets/mc_generic_header.dart';
import '../../../../data/models/tts_voice_option.dart';
import '../../../../state/app_notifier.dart';

/// Lets a resident pick which on-device TTS voice the assistant speaks
/// with — populated from `flutter_tts`'s real `getVoices()` list (whatever
/// the phone actually has installed), not a fixed set this app ships with.
class VoiceSettingsPage extends ConsumerStatefulWidget {
  const VoiceSettingsPage({super.key});

  @override
  ConsumerState<VoiceSettingsPage> createState() => _VoiceSettingsPageState();
}

class _VoiceSettingsPageState extends ConsumerState<VoiceSettingsPage> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    ref.read(appStateProvider.notifier).loadAvailableVoices().then((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);

    return Column(
      children: [
        McGenericHeader(
          title: 'Assistant Voice',
          centerTitle: true,
          onBack: () => context.pop(),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            context.rs(20),
            0,
            context.rs(20),
            context.rs(10),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Tap a voice to hear it and use it for the assistant.',
              style: McTextStyles.body(fontSize: 13, color: McColors.bodyText),
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: notifier.loadAvailableVoices,
                  child: s.availableVoices.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            context.rs(20),
                            context.rs(40),
                            context.rs(20),
                            context.rs(24),
                          ),
                          children: [
                            Center(
                              child: Text(
                                "Couldn't find any voices on this device.",
                                textAlign: TextAlign.center,
                                style: McTextStyles.body(
                                  fontSize: 13.5,
                                  color: McColors.bodyText,
                                ),
                              ),
                            ),
                          ],
                        )
                       : ListView.separated(
                           physics: const AlwaysScrollableScrollPhysics(),
                           padding: EdgeInsets.fromLTRB(
                             context.rs(20),
                             0,
                             context.rs(20),
                             context.rs(24),
                           ),
                           // One extra slot after the voices for the
                           // developer-facing voice-log export section.
                           itemCount: s.availableVoices.length + 1,
                           separatorBuilder: (_, _) =>
                               SizedBox(height: context.rs(10)),
                           itemBuilder: (_, i) {
                             if (i == s.availableVoices.length) {
                               return const _VoiceLogsSection();
                             }
                             final voice = s.availableVoices[i];
                             final selected = s.selectedVoice == voice;
                             return _VoiceTile(
                               voice: voice,
                               selected: selected,
                               onTap: () => notifier.selectVoice(voice),
                             );
                           },
                         ),
                ),
        ),
      ],
    );
  }
}

/// Developer/diagnostics section at the bottom of the voice settings list —
/// exports or uploads the on-device voice-turn log (transcript, parser
/// decision, reply) that feeds the offline analysis loop improving the
/// assistant's keyword parser. Deliberately plain: it's tooling, not a
/// resident feature.
class _VoiceLogsSection extends ConsumerWidget {
  const _VoiceLogsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(appStateProvider.notifier);
    return Container(
      padding: EdgeInsets.all(context.rs(14)),
      decoration: BoxDecoration(
        color: McColors.surfaceSunken,
        borderRadius: BorderRadius.circular(McRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VOICE LOGS (DIAGNOSTICS)',
            style: McTextStyles.body(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: McColors.bodyText,
            ).copyWith(letterSpacing: 1),
          ),
          SizedBox(height: context.rs(10)),
          Row(
            children: [
              Expanded(
                child: McButton(
                  label: 'Share',
                  expand: false,
                  variant: ChButtonVariant.secondary,
                  onPressed: () async {
                    final file = await notifier.exportVoiceLogs();
                    if (!context.mounted) return;
                    if (file == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No voice logs recorded yet.')),
                      );
                      return;
                    }
                    await Share.shareXFiles(
                      [XFile(file.path)],
                      subject: 'MyCove voice logs',
                    );
                  },
                ),
              ),
              SizedBox(width: context.rs(10)),
              Expanded(
                child: McButton(
                  label: 'Upload',
                  expand: false,
                  onPressed: () async {
                    try {
                      final count = await notifier.uploadVoiceLogs();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            count == 0 ? 'No voice logs recorded yet.' : 'Uploaded $count voice logs.',
                          ),
                        ),
                      );
                    } catch (_) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Couldn't reach the estate server.")),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VoiceTile extends StatelessWidget {
  const _VoiceTile({
    required this.voice,
    required this.selected,
    required this.onTap,
  });

  final TtsVoiceOption voice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(McRadii.md),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(context.rs(14)),
        decoration: BoxDecoration(
          color: selected ? McColors.accent2N(100) : McColors.surface,
          borderRadius: BorderRadius.circular(McRadii.md),
          border: Border.all(
            color: selected ? McColors.accent2 : Colors.transparent,
          ),
          boxShadow: selected ? null : McColors.cardShadow,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    voice.name,
                    style: McTextStyles.body(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: McColors.text,
                    ),
                  ),
                  SizedBox(height: context.rs(2)),
                  Text(
                    voice.locale,
                    style: McTextStyles.body(
                      fontSize: 12,
                      color: McColors.bodyText,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(
                Icons.check_circle_rounded,
                color: McColors.accent2,
                size: context.rs(20),
              ),
          ],
        ),
      ),
    );
  }
}
