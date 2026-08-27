import 'package:flutter/material.dart';

import '../theme/mc_colors.dart';
import '../theme/mc_responsive.dart';

/// House-with-family mark — no single Material icon matches the mockup's
/// custom logo, so this composites the closest built-in shapes: a house
/// outline with a family silhouette nested inside it. Shared between the
/// welcome screen and the lock screen so the brand mark stays identical.
class McBrandMark extends StatelessWidget {
  const McBrandMark({super.key, this.size = 58});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: context.rs(size),
      height: context.rs(size),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.home_rounded, size: context.rs(size), color: McColors.accent2),
          Padding(
            padding: EdgeInsets.only(top: context.rs(size * 0.38)),
            child: Icon(
              Icons.family_restroom_rounded,
              size: context.rs(size * 0.38),
              color: McColors.accent2N(100),
            ),
          ),
        ],
      ),
    );
  }
}
