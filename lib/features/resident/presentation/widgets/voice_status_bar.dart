import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_responsive.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../state/app_notifier.dart';
import '../../../../state/app_state.dart';

/// A small, always-reachable mic control mounted above every resident
/// screen (see ResidentShell) — not just the dashboard — so voice can be
/// invoked or corrected mid-wizard, not only from a dedicated page.
/// Collapses to a bare mic button when idle; expands to show live
/// transcript/response while listening/processing/erroring.
class VoiceStatusBar extends ConsumerWidget {
  const VoiceStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    // A read-only answer (e.g. balance) sets voiceResponse and returns to
    // idle in the same update — without the response.isNotEmpty check, the
    // bubble would collapse in that exact instant and never actually be
    // seen (it previously only reappeared once a stale response resurfaced
    // on the *next* unrelated mic tap, which looked like a bug).
    final expanded = s.voiceStage != VoiceStage.idle || s.voiceResponse.isNotEmpty;
    final text = s.voiceStage == VoiceStage.listening && s.voiceTranscript.isNotEmpty
        ? s.voiceTranscript
        : s.voiceResponse;

    return Padding(
      padding: EdgeInsets.only(bottom: context.rs(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (expanded)
            Flexible(
              child: Container(
                margin: EdgeInsets.only(right: context.rs(10)),
                padding: EdgeInsets.symmetric(horizontal: context.rs(14), vertical: context.rs(10)),
                decoration: BoxDecoration(
                  color: ChColors.surface,
                  borderRadius: BorderRadius.circular(ChRadii.pill),
                  boxShadow: ChColors.cardShadow,
                ),
                child: Text(
                  text.isEmpty ? _statusLabel(s.voiceStage) : text,
                  style: ChTextStyles.body(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: s.voiceStage == VoiceStage.error ? ChColors.danger : ChColors.text,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          if (expanded) ...[
            GestureDetector(
              onTap: notifier.dismissVoice,
              child: Container(
                width: context.rs(40),
                height: context.rs(40),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ChColors.surface,
                  boxShadow: ChColors.cardShadow,
                ),
                child: Icon(Icons.close_rounded, size: context.rs(22), color: ChColors.bodyText),
              ),
            ),
            SizedBox(width: context.rs(10)),
          ],
          GestureDetector(
            onTap: () => _onMicTap(notifier, s.voiceStage),
            child: Container(
              width: context.rs(48),
              height: context.rs(48),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: s.voiceStage == VoiceStage.listening ? ChColors.danger : ChColors.accent2,
                boxShadow: ChColors.cardShadow,
              ),
              child: s.voiceStage == VoiceStage.processing
                  ? SizedBox(
                      width: context.rs(18),
                      height: context.rs(18),
                      child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(
                      s.voiceStage == VoiceStage.listening ? Icons.stop_rounded : Icons.mic_rounded,
                      color: Colors.white,
                      size: context.rs(22),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _onMicTap(AppNotifier notifier, VoiceStage stage) {
    if (stage == VoiceStage.listening) {
      notifier.stopVoiceListening();
    } else if (stage != VoiceStage.processing) {
      notifier.startVoiceListening();
    }
  }

  String _statusLabel(VoiceStage stage) => switch (stage) {
    VoiceStage.idle => '',
    VoiceStage.listening => 'Listening…',
    VoiceStage.processing => 'Thinking…',
    VoiceStage.error => 'Something went wrong',
  };
}
