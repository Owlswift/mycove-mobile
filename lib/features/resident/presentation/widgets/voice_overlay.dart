import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_responsive.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../state/app_notifier.dart';
import '../../../../state/app_state.dart';

/// The voice assistant's feedback surface — mounted once above every
/// resident screen (see ResidentShell) so what it hears/says stays visible
/// even after voice navigates somewhere else mid-flow. There's no mic
/// button here: the only way to start a session is the mic icon on the
/// Dashboard header, so this only ever needs to show status, never start
/// one — see [DashboardPage]'s own mic tap.
///
/// The transcript/response is a real wrapped paragraph, not a single
/// truncated line — a resident should be able to actually read back what
/// they said or what the assistant is about to do.
class VoiceOverlay extends ConsumerWidget {
  const VoiceOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);

    final visible = s.voiceStage != VoiceStage.idle || s.voiceResponse.isNotEmpty;
    if (!visible) return const SizedBox.shrink();

    final isListening = s.voiceStage == VoiceStage.listening;
    final text = isListening && s.voiceTranscript.isNotEmpty ? s.voiceTranscript : s.voiceResponse;

    return Padding(
      padding: EdgeInsets.fromLTRB(context.rs(16), 0, context.rs(16), context.rs(14)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(context.rs(16)),
        decoration: BoxDecoration(
          color: ChColors.surface,
          borderRadius: BorderRadius.circular(ChRadii.card),
          boxShadow: ChColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  s.voiceStage == VoiceStage.error ? Icons.error_outline : Icons.graphic_eq_rounded,
                  size: context.rs(16),
                  color: s.voiceStage == VoiceStage.error ? ChColors.danger : ChColors.accent2,
                ),
                SizedBox(width: context.rs(6)),
                Text(
                  _statusLabel(s.voiceStage),
                  style: ChTextStyles.body(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: s.voiceStage == VoiceStage.error ? ChColors.danger : ChColors.accent2,
                  ).copyWith(letterSpacing: 0.5),
                ),
                const Spacer(),
                if (isListening)
                  GestureDetector(
                    onTap: notifier.stopVoiceListening,
                    child: Icon(Icons.stop_circle_outlined, size: context.rs(20), color: ChColors.bodyText),
                  ),
                SizedBox(width: context.rs(12)),
                GestureDetector(
                  onTap: notifier.dismissVoice,
                  child: Icon(Icons.close_rounded, size: context.rs(20), color: ChColors.bodyText),
                ),
              ],
            ),
            if (text.isNotEmpty) ...[
              SizedBox(height: context.rs(10)),
              // No maxLines/ellipsis — this is meant to be fully readable,
              // however many lines that takes, not clipped to one.
              Text(
                text,
                style: ChTextStyles.body(fontSize: 12.5, color: ChColors.text, height: 1.45),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _statusLabel(VoiceStage stage) => switch (stage) {
    VoiceStage.idle => '',
    VoiceStage.listening => 'LISTENING',
    VoiceStage.processing => 'THINKING',
    VoiceStage.error => 'SOMETHING WENT WRONG',
  };
}
