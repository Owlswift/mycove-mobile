import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/mc_colors.dart';
import '../../../../core/theme/mc_responsive.dart';
import '../../../../core/theme/mc_spacing.dart';
import '../../../../core/theme/mc_text_styles.dart';
import '../../../../core/widgets/mc_generic_header.dart';
import '../../../../data/models/utility_meter.dart';
import '../../../../state/app_notifier.dart';
import '../widgets/utility_wizard_stepper.dart';

class ElectricitySelectProviderPage extends ConsumerStatefulWidget {
  const ElectricitySelectProviderPage({super.key});

  @override
  ConsumerState<ElectricitySelectProviderPage> createState() => _ElectricitySelectProviderPageState();
}

class _ElectricitySelectProviderPageState extends ConsumerState<ElectricitySelectProviderPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    final query = _query.trim().toLowerCase();
    final discos = query.isEmpty
        ? s.discos
        : s.discos
              .where(
                (d) =>
                    d.name.toLowerCase().contains(query) ||
                    d.shortCode.toLowerCase().contains(query),
              )
              .toList();

    return Column(
      children: [
        McGenericHeader(
          title: 'Buy Electricity',
          centerTitle: true,
          onBack: () {
            notifier.clearUtilityError();
            context.pop();
          },
          trailing: const UtilityHistoryButton(type: 'ELECTRICITY'),
        ),
        SizedBox(height: context.rs(14)),
        const UtilityWizardStepper(currentStep: 1),
        SizedBox(height: context.rs(14)),
        Padding(
          padding: EdgeInsets.fromLTRB(context.rs(20), 0, context.rs(20), context.rs(14)),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Select Electricity Provider', style: McTextStyles.heading(fontSize: 16)),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(context.rs(20), 0, context.rs(20), context.rs(14)),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search provider',
              hintStyle: McTextStyles.body(color: McColors.bodyText, fontWeight: FontWeight.w600),
              prefixIcon: Icon(
                Icons.search,
                color: McColors.bodyText,
                size: context.rs(22),
                weight: 700,
              ),
            ),
          ),
        ),
        Expanded(
          child: s.discos.isEmpty
              ? Center(
                  child: Text(
                    'No providers available right now.',
                    style: McTextStyles.body(fontSize: 13.5, color: McColors.bodyText),
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(context.rs(20), 0, context.rs(20), context.rs(24)),
                  itemCount: discos.length,
                  separatorBuilder: (_, _) => Divider(height: 1, color: McColors.divider),
                  itemBuilder: (_, i) {
                    final disco = discos[i];
                    return _DiscoTile(
                      disco: disco,
                      onTap: () {
                        notifier.onElecDisco(disco.code, disco.name);
                        context.push('/resident/electricity/meter');
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _DiscoTile extends StatelessWidget {
  const _DiscoTile({required this.disco, required this.onTap});

  final Disco disco;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(McRadii.md),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.rs(10)),
        child: Row(
          children: [
            DiscoLogo(disco: disco, size: context.rs(42)),
            SizedBox(width: context.rs(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    disco.shortCode,
                    style: McTextStyles.body(fontSize: 14.5, fontWeight: FontWeight.w700, color: McColors.text),
                  ),
                  SizedBox(height: context.rs(2)),
                  Text(disco.name, style: McTextStyles.body(fontSize: 12.5, color: McColors.bodyText, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: McColors.bodyText, size: context.rs(20)),
          ],
        ),
      ),
    );
  }
}
