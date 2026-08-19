import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/ch_colors.dart';
import '../../../../core/theme/ch_responsive.dart';
import '../../../../core/theme/ch_spacing.dart';
import '../../../../core/theme/ch_text_styles.dart';
import '../../../../core/widgets/ch_generic_header.dart';
import '../../../../data/models/notification_item.dart';
import '../../../../data/models/session_info.dart';
import '../../../../state/app_notifier.dart';

class ManageDevicesPage extends ConsumerStatefulWidget {
  const ManageDevicesPage({super.key});

  @override
  ConsumerState<ManageDevicesPage> createState() => _ManageDevicesPageState();
}

class _ManageDevicesPageState extends ConsumerState<ManageDevicesPage> {
  String? _currentJti;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final notifier = ref.read(appStateProvider.notifier);
    final jti = await notifier.currentSessionJti();
    await notifier.loadSessions();
    if (!mounted) return;
    setState(() {
      _currentJti = jti;
      _loading = false;
    });
  }

  Future<void> _revoke(SessionInfo session) async {
    final isCurrent = session.jti == _currentJti;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out this device?'),
        content: Text(
          isCurrent
              ? "This is the device you're using right now — you'll be logged out immediately."
              : '${session.deviceName ?? 'This device'} will be signed out and will need to log in again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: ChColors.danger),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final notifier = ref.read(appStateProvider.notifier);
    if (isCurrent) {
      await notifier.logout();
      return;
    }
    await notifier.revokeSession(session.id);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Device logged out')));
  }

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(appStateProvider.select((s) => s.sessions));

    return Column(
      children: [
        const ChGenericHeader(title: 'Manage Devices'),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: ChColors.accent2),
                )
              : sessions.isEmpty
              ? Center(
                  child: Text(
                    'No other devices are logged in.',
                    style: ChTextStyles.body(
                      fontSize: 14,
                      color: ChColors.bodyText,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: sessions.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _DeviceTile(
                    session: sessions[i],
                    isCurrent: sessions[i].jti == _currentJti,
                    onRevoke: () => _revoke(sessions[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({
    required this.session,
    required this.isCurrent,
    required this.onRevoke,
  });

  final SessionInfo session;
  final bool isCurrent;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ChColors.surface,
        borderRadius: BorderRadius.circular(ChRadii.card),
      ),
      child: Row(
        children: [
          Container(
            width: context.rs(40),
            height: context.rs(40),
            decoration: BoxDecoration(
              color: ChColors.accent2N(100),
              shape: BoxShape.circle,
            ),
            child: Icon(
              session.platform == 'IOS'
                  ? Icons.phone_iphone
                  : Icons.phone_android,
              size: context.rs(20),
              color: ChColors.accent2N(700),
            ),
          ),
          SizedBox(width: context.rs(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        session.deviceName ??
                            (session.platform == 'IOS'
                                ? 'iPhone'
                                : 'Android device'),
                        overflow: TextOverflow.ellipsis,
                        style: ChTextStyles.body(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: ChColors.accent2N(100),
                          borderRadius: BorderRadius.circular(ChRadii.pill),
                        ),
                        child: Text(
                          'This device',
                          style: ChTextStyles.body(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: ChColors.accent2N(700),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Active ${relativeTime(session.lastUsedAt)}',
                  style: ChTextStyles.body(
                    fontSize: 12,
                    color: ChColors.neutralN(500),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onRevoke,
            style: TextButton.styleFrom(foregroundColor: ChColors.danger),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}
