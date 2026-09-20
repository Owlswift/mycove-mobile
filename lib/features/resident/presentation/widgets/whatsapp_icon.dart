import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The WhatsApp logo as a line icon (speech bubble outline with the handset),
/// drawn in [color] on a 24×24 grid.
class WhatsappIcon extends StatelessWidget {
  const WhatsappIcon({super.key, this.size = 22, this.color = Colors.white});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final hex = color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2);
    return SvgPicture.string(
      '<svg viewBox="0 0 24 24" fill="none" stroke="#$hex" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round" xmlns="http://www.w3.org/2000/svg">'
      '<path d="M3 21l1.65-3.8a9 9 0 1 1 3.4 2.9L3 21"/>'
      '<path d="M9 10a.5.5 0 0 0 1 0V9a.5.5 0 0 0-1 0v1a5 5 0 0 0 5 5h1a.5.5 0 0 0 0-1h-1a.5.5 0 0 0 0 1"/>'
      '</svg>',
      width: size,
      height: size,
    );
  }
}
