import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_responsive.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_generic_header.dart';
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
        ChGenericHeader(title: 'Assistant Voice', centerTitle: true, onBack: () => context.pop()),
        Padding(
          padding: EdgeInsets.fromLTRB(context.rs(20), 0, context.rs(20), context.rs(10)),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Tap a voice to hear it and use it for the assistant.',
              style: ChTextStyles.body(fontSize: 13, color: ChColors.bodyText),
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : s.availableVoices.isEmpty
                  ? Center(
                      child: Text(
                        "Couldn't find any voices on this device.",
                        style: ChTextStyles.body(fontSize: 13.5, color: ChColors.bodyText),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(context.rs(20), 0, context.rs(20), context.rs(24)),
                      itemCount: s.availableVoices.length,
                      separatorBuilder: (_, _) => SizedBox(height: context.rs(10)),
                      itemBuilder: (_, i) {
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
      ],
    );
  }
}

class _VoiceTile extends StatelessWidget {
  const _VoiceTile({required this.voice, required this.selected, required this.onTap});

  final TtsVoiceOption voice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(ChRadii.md),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(context.rs(14)),
        decoration: BoxDecoration(
          color: selected ? ChColors.accent2N(100) : ChColors.surface,
          borderRadius: BorderRadius.circular(ChRadii.md),
          border: Border.all(color: selected ? ChColors.accent2 : Colors.transparent),
          boxShadow: selected ? null : ChColors.cardShadow,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    voice.name,
                    style: ChTextStyles.body(fontSize: 14, fontWeight: FontWeight.w700, color: ChColors.text),
                  ),
                  SizedBox(height: context.rs(2)),
                  Text(voice.locale, style: ChTextStyles.body(fontSize: 12, color: ChColors.bodyText)),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle_rounded, color: ChColors.accent2, size: context.rs(20)),
          ],
        ),
      ),
    );
  }
}
