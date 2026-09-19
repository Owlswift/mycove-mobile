import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_responsive.dart';
import '../../../../core/theme/mc_spacing.dart';
import '../../../../core/theme/mc_text_styles.dart';
import '../../../../core/widgets/mc_button.dart';
import '../../../../state/app_notifier.dart';
import '../widgets/chairman_widgets.dart';

const _categories = ['General', 'Security', 'Maintenance', 'Finance', 'Event'];

/// Announcements sent to residents, with a button to post a new one — the
/// one thing the chairman can do beyond viewing.
class ChairmanNoticesPage extends ConsumerWidget {
  const ChairmanNoticesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);

    return Stack(
      children: [
        ChairmanList(
          onRefresh: notifier.refreshChairman,
          emptyIcon: Icons.campaign_outlined,
          emptyMessage: 'No announcements yet. Tap “New announcement” to post one.',
          children: [
            for (final a in s.announcements)
              ChairmanCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(a.title, style: McTextStyles.body(fontSize: 14.5, fontWeight: FontWeight.w600))),
                        StatusPill(a.category, color: McColors.accent2),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      a.body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: McTextStyles.body(fontSize: 13.5, color: McColors.text, height: 1.35),
                    ),
                    const SizedBox(height: 8),
                    Text(a.date, style: McTextStyles.body(fontSize: 12, color: McColors.bodyText)),
                  ],
                ),
              ),
            // Room so the last card isn't hidden behind the button.
            const SizedBox(height: 64),
          ],
        ),
        Positioned(
          right: 20,
          bottom: 16,
          child: FloatingActionButton.extended(
            backgroundColor: McColors.accent2,
            foregroundColor: Colors.white,
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const _ComposeSheet(),
            ),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('New announcement'),
          ),
        ),
      ],
    );
  }
}

class _ComposeSheet extends ConsumerStatefulWidget {
  const _ComposeSheet();

  @override
  ConsumerState<_ComposeSheet> createState() => _ComposeSheetState();
}

class _ComposeSheetState extends ConsumerState<_ComposeSheet> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  String _category = _categories.first;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    if (_title.text.trim().isEmpty || _body.text.trim().isEmpty) {
      setState(() => _error = 'Add a title and a message before posting.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await ref
        .read(appStateProvider.notifier)
        .postAnnouncement(title: _title.text, category: _category, body: _body.text);
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement posted to all residents.')),
      );
      return;
    }
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        padding: EdgeInsets.fromLTRB(context.rs(20), context.rs(20), context.rs(20), context.rs(20)),
        decoration: BoxDecoration(
          color: McColors.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(McRadii.card)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: McColors.divider, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text('New announcement', style: McTextStyles.heading(fontSize: 20)),
              const SizedBox(height: 4),
              Text(
                'Every resident is notified as soon as you post.',
                style: McTextStyles.body(fontSize: 13, color: McColors.bodyText),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final c in _categories)
                    ChoiceChip(
                      label: Text(c),
                      selected: _category == c,
                      onSelected: (_) => setState(() => _category = c),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _body,
                minLines: 4,
                maxLines: 8,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: McTextStyles.body(fontSize: 13, color: McColors.danger)),
              ],
              const SizedBox(height: 16),
              McButton(label: 'Post to residents', onPressed: _busy ? null : _post, isLoading: _busy),
            ],
          ),
        ),
      ),
    );
  }
}
