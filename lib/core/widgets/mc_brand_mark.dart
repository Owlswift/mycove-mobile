import 'package:flutter/material.dart';

import '../theme/mc_responsive.dart';

/// The real MyCove "M" logo mark — shared between the welcome screen and
/// the lock screen so the brand mark stays identical. A tightly-cropped,
/// transparent-background asset (see assets/images/mycove_logo_mark.png)
/// rather than the raw source file, which is mostly padding.
class McBrandMark extends StatelessWidget {
  const McBrandMark({super.key, this.size = 58});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: context.rs(size),
      height: context.rs(size),
      child: Image.asset(
        'assets/images/mycove_logo_mark.png',
        fit: BoxFit.contain,
      ),
    );
  }
}
