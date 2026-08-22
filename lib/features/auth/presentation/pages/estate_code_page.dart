import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_responsive.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_help_pill.dart';
import '../../../../core/widgets/ch_square_icon_button.dart';
import '../../../../state/app_notifier.dart';

/// Shown once, before login — this app is shared across estates, so a
/// fresh install needs to know which estate's backend data it's talking
/// to before a resident can even see a login form. Once validated, this
/// screen is skipped on every future launch (see AppNotifier._bootstrap).
class EstateCodePage extends ConsumerWidget {
  const EstateCodePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    // Sized to the source photo's own aspect ratio (1078x992) so the full
    // image renders — no BoxFit.cover cropping off the bottom of the shot.
    final imageHeight = MediaQuery.sizeOf(context).width * (992 / 1078);
    final cardOverlap = imageHeight * 0.11;

    return Scaffold(
      backgroundColor: ChColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 12, bottom: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.rs(20)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ChSquareIconButton(
                      icon: Icons.arrow_back,
                      onTap: notifier.backToWelcome,
                    ),
                    ChHelpPill(onTap: () => _showHelp(context)),
                  ],
                ),
              ),
              // The gate photo has a transparent top (chroma-keyed from its
              // original white background) with only the tree canopy poking
              // into it — the heading/subtitle sit directly on top of that
              // transparent zone, on the left, so the tree reads as though
              // it's growing up beside the text rather than behind a photo.
              // The code card is a normal (non-Positioned) Stack child too,
              // pushed down by `top` padding rather than placed after the
              // Stack and shifted with Transform.translate — Transform only
              // moves where a widget paints, not the space its parent
              // reserves for it, which left a phantom cardOverlap-sized gap
              // before _HelpBox. As a plain padded child, the Stack's own
              // reported height correctly includes the card's true position.
              Stack(
                children: [
                  // The source photo's sky isn't pure white right at its own
                  // top edge (it's a faint blue-gray gradient), so chroma-key
                  // alpha alone leaves a visible seam against the page's
                  // cream background there — this top ramp forces it fully
                  // transparent regardless of the photo's exact tone. Bottom
                  // ~10% fades the same way so the code card's overlap
                  // blends softly into the photo instead of a hard cut.
                  ShaderMask(
                    shaderCallback: (rect) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
                      stops: [0.0, 0.16, 0.9, 1.0],
                    ).createShader(rect),
                    blendMode: BlendMode.dstIn,
                    child: Image.asset(
                      'assets/images/estate_gate.png',
                      width: double.infinity,
                      height: imageHeight,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: context.rs(22)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: context.rs(20)),
                        child: RichText(
                          text: TextSpan(
                            style: ChTextStyles.heading(fontSize: 32),
                            children: [
                              const TextSpan(text: 'Find your '),
                              TextSpan(
                                text: 'estate',
                                style: ChTextStyles.heading(
                                  fontSize: 32,
                                  color: ChColors.accent2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: context.rs(8)),
                      Padding(
                        padding: EdgeInsets.only(left: context.rs(20), right: context.rs(160)),
                        child: Text(
                          'Join your residential community using the unique code provided by your estate management.',
                          textAlign: TextAlign.left,
                          style: ChTextStyles.body(
                            fontSize: 13.5,
                            height: 1.6,
                            color: ChColors.text
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      context.rs(24),
                      imageHeight + context.rs(48) - cardOverlap,
                      context.rs(24),
                      0,
                    ),
                    child: _EstateCodeCard(
                      value: s.estateCodeInput,
                      onChanged: notifier.onEstateCodeChange,
                      onClear: () => notifier.onEstateCodeChange(''),
                      error: s.estateCodeError,
                      loading: s.estateCodeLoading,
                      onSubmit: s.estateCodeLoading
                          ? null
                          : notifier.submitEstateCode,
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.rs(19)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.rs(20)),
                child: _HelpBox(onTap: () => _showHelp(context)),
              ),
              SizedBox(height: context.rs(24)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.rs(20)),
                child: const _SecureRow(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Don't have a code?"),
        content: const Text(
          'Ask your estate administrator or management office — every estate on CommunityHub has its own access code.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: ChColors.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _EstateCodeCard extends StatelessWidget {
  const _EstateCodeCard({
    required this.value,
    required this.onChanged,
    required this.onClear,
    required this.error,
    required this.loading,
    required this.onSubmit,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final String error;
  final bool loading;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ChColors.surface,
        borderRadius: BorderRadius.circular(ChRadii.card),
        boxShadow: ChColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Estate Access Code', style: ChTextStyles.heading(fontSize: 14.5)),
          const SizedBox(height: 12),
          _CodeField(value: value, onChanged: onChanged, onClear: onClear),
          const SizedBox(height: 8),
          Text(
            error.isNotEmpty
                ? error
                : 'Enter the code exactly as provided (case-sensitive).',
            style: ChTextStyles.body(
              fontSize: 12,
              color: error.isNotEmpty
                  ? ChColors.danger
                  : ChColors.text,
            ),
          ),
          const SizedBox(height: 26),
          GestureDetector(
            onTap: onSubmit,
            child: Opacity(
              opacity: onSubmit == null && !loading ? 0.6 : 1,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: ChColors.accent2,
                  borderRadius: BorderRadius.circular(ChRadii.button),
                ),
                child: loading
                    ? SizedBox(
                        width: context.rs(20),
                        height: context.rs(20),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            'Continue',
                            style: ChTextStyles.body(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: context.rs(22),
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeField extends StatefulWidget {
  const _CodeField({
    required this.value,
    required this.onChanged,
    required this.onClear,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  State<_CodeField> createState() => _CodeFieldState();
}

class _CodeFieldState extends State<_CodeField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );

  @override
  void didUpdateWidget(covariant _CodeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ChRadii.button),
        border: Border.all(color: ChColors.divider),
      ),
      child: Row(
        children: [
          SizedBox(
            width: context.rs(32),
            height: context.rs(32),
            child: Icon(
              Iconsax.key,
              size: context.rs(18),
              color: ChColors.accent2N(700),
            ),
          ),
          SizedBox(width: context.rs(10)),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: widget.onChanged,
              textCapitalization: TextCapitalization.characters,
              style: ChTextStyles.body(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                hintText: 'e.g. PALM001',
                hintStyle: ChTextStyles.body(
                  fontSize: 15,
                  color: ChColors.neutralN(500),
                ),
              ),
            ),
          ),
          if (widget.value.isNotEmpty)
            GestureDetector(
              onTap: widget.onClear,
              child: Icon(
                Iconsax.close_circle,
                size: context.rs(18),
                color: ChColors.neutralN(500),
              ),
            ),
        ],
      ),
    );
  }
}

class _HelpBox extends StatelessWidget {
  const _HelpBox({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ChColors.surfaceSunken,
          borderRadius: BorderRadius.circular(ChRadii.button),
          border: Border.all(color: ChColors.divider)
        ),
        child: Row(
          children: [
            Container(
              width: context.rs(42),
              height: context.rs(42),
              decoration: BoxDecoration(
                color: ChColors.accent2N(100),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.headphone,
                size: context.rs(24),
                color: ChColors.accent2N(700),
              ),
            ),
            SizedBox(width: context.rs(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Don't know your estate code?",
                    style: ChTextStyles.body(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: ChColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Padding(
                    padding: const EdgeInsets.only(left: 0, right: 50),
                    child: Text(
                      'Contact your estate management office to get your unique access code.',
                      textAlign: TextAlign.left,
                      style: ChTextStyles.body(
                        fontSize: 11,
                        height: 1.3,
                        color: ChColors.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: context.rs(22), color: ChColors.text),
          ],
        ),
      ),
    );
  }
}

class _SecureRow extends StatelessWidget {
  const _SecureRow();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Iconsax.shield_tick,
            size: context.rs(20),
            color: ChColors.accent2,
          ),
          SizedBox(width: context.rs(8)),
          RichText(
            text: TextSpan(
              style: ChTextStyles.body(
                fontSize: 11,
                color: ChColors.text,
              ),
              children: [
                const TextSpan(text: 'Your information is '),
                TextSpan(
                  text: 'secure',
                  style: ChTextStyles.body(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: ChColors.accent2,
                  ),
                ),
                const TextSpan(text: ' with us'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
