import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/mc_text_styles.dart';

/// The intro illustration for Domestic staff: a house, a staff member with
/// WhatsApp open, and the access code they receive. The drawing is an SVG
/// without its text (flutter_svg does not draw text elements), so the three text
/// lines on the code card are laid over it at the same scale.
class DomesticIllustration extends StatelessWidget {
  const DomesticIllustration({super.key});

  static const _viewWidth = 420.0;
  static const _viewHeight = 240.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final s = width / _viewWidth;
        return SizedBox(
          width: width,
          height: _viewHeight * s,
          child: Stack(
            children: [
              SvgPicture.string(_svg, width: width, height: _viewHeight * s),
              _text('ACCESS CODE', 312, 102, 11, FontWeight.w600, const Color(0xFF68756E), s),
              _text('465297', 286, 129, 21, FontWeight.w700, const Color(0xFF075C38), s, spacing: 2),
              _text('Valid for 10 minutes', 286, 144, 9, FontWeight.w400, const Color(0xFF8A958F), s),
            ],
          ),
        );
      },
    );
  }

  /// [x], [y] are the SVG's text origin (left edge, baseline) in its 420×240 space.
  Widget _text(String value, double x, double y, double size, FontWeight weight, Color color, double s, {double spacing = 0}) {
    return Positioned(
      left: x * s,
      top: (y - size * 0.92) * s,
      child: Text(
        value,
        style: McTextStyles.body(
          fontSize: size * s,
          fontWeight: weight,
          color: color,
          height: 1.0,
          letterSpacing: spacing * s,
        ),
      ),
    );
  }
}

const _svg = '''
<svg width="420" height="240" viewBox="0 0 420 240" fill="none" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="bg" x1="50" y1="10" x2="370" y2="230" gradientUnits="userSpaceOnUse">
      <stop stop-color="#F1FAF5"/>
      <stop offset="1" stop-color="#E4F4EC"/>
    </linearGradient>
    <linearGradient id="house" x1="115" y1="65" x2="285" y2="205" gradientUnits="userSpaceOnUse">
      <stop stop-color="#FFFFFF"/>
      <stop offset="1" stop-color="#F4F8F6"/>
    </linearGradient>
  </defs>
  <rect x="0" y="0" width="420" height="240" rx="30" fill="url(#bg)"/>
  <circle cx="47" cy="49" r="20" fill="#D5EEE2"/>
  <circle cx="375" cy="188" r="28" fill="#D8F0E5"/>
  <circle cx="350" cy="44" r="8" fill="#BFE4D1"/>
  <circle cx="73" cy="185" r="4" fill="#A8D9C2"/>
  <circle cx="91" cy="201" r="3" fill="#C1E6D4"/>
  <circle cx="330" cy="198" r="4" fill="#A8D9C2"/>
  <g>
    <path d="M115 104L210 43L305 104V195C305 201.627 299.627 207 293 207H127C120.373 207 115 201.627 115 195V104Z" fill="url(#house)"/>
    <path d="M96 105L202.6 34.8C207.1 31.8 212.9 31.8 217.4 34.8L324 105" stroke="#075C38" stroke-width="10" stroke-linecap="round" stroke-linejoin="round"/>
    <path d="M115 106L210 44L305 106" stroke="#BBDCCB" stroke-width="2" stroke-linecap="round"/>
    <rect x="187" y="140" width="46" height="67" rx="8" fill="#E8F4EE"/>
    <rect x="191" y="144" width="38" height="63" rx="6" fill="#075C38"/>
    <circle cx="220" cy="176" r="3" fill="#D7EFE2"/>
    <rect x="139" y="123" width="36" height="36" rx="7" fill="#DDF2E8"/>
    <path d="M157 123V159M139 141H175" stroke="#8DC9AA" stroke-width="3"/>
    <rect x="245" y="123" width="36" height="36" rx="7" fill="#DDF2E8"/>
    <path d="M263 123V159M245 141H281" stroke="#8DC9AA" stroke-width="3"/>
  </g>
  <g>
    <path d="M87 184C87 159.147 107.147 139 132 139H139C163.853 139 184 159.147 184 184V197H87V184Z" fill="#075C38"/>
    <path d="M111 157C116 164 123 168 131 168C139 168 146 164 151 157" stroke="#BDE4D0" stroke-width="3" stroke-linecap="round"/>
    <path d="M121 134V145C121 150 125 154 131 154C137 154 141 150 141 145V134" fill="#C98D67"/>
    <ellipse cx="131" cy="115" rx="29" ry="31" fill="#D89A70"/>
    <path d="M103 115C103 94 114 81 132 81C151 81 161 96 160 115C153 105 145 100 132 100C120 100 111 105 103 115Z" fill="#272522"/>
    <path d="M105 112C105 96 115 87 131 87" stroke="#3B342E" stroke-width="7" stroke-linecap="round"/>
    <circle cx="103" cy="117" r="5" fill="#D89A70"/>
    <circle cx="159" cy="117" r="5" fill="#D89A70"/>
    <circle cx="121" cy="116" r="2.2" fill="#342821"/>
    <circle cx="141" cy="116" r="2.2" fill="#342821"/>
    <path d="M125 128C129 131 134 131 138 128" stroke="#925D48" stroke-width="2.5" stroke-linecap="round"/>
  </g>
  <g>
    <rect x="151" y="145" width="48" height="82" rx="9" transform="rotate(-9 151 145)" fill="#17221D"/>
    <rect x="156" y="150" width="38" height="70" rx="6" transform="rotate(-9 156 150)" fill="white"/>
    <circle cx="176" cy="177" r="13" fill="#0BB66F"/>
    <path d="M169 186L171 181" stroke="white" stroke-width="2.5" stroke-linecap="round"/>
    <path d="M170.5 177.5C171.8 181 175 183 178.5 182.3C181.5 181.7 183 179.5 183 177C183 173.1 179.8 170 176 170C172.2 170 169 173.1 169 177C169 178.3 169.4 179.5 170 180.5" stroke="white" stroke-width="2" stroke-linecap="round"/>
    <circle cx="175" cy="211" r="2" fill="#C9D3CE"/>
  </g>
  <g>
    <rect x="270" y="76" width="118" height="77" rx="18" fill="white"/>
    <circle cx="292" cy="98" r="13" fill="#E2F5EB"/>
    <path d="M286 98L290 102L298 93" stroke="#087047" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
  </g>
  <path d="M196 129C220 117 242 112 270 112" stroke="#8BC9A9" stroke-width="2.5" stroke-linecap="round" stroke-dasharray="5 6"/>
  <g transform="translate(321 171)">
    <rect x="0" y="10" width="51" height="35" rx="7" fill="white" stroke="#CFE5D9" stroke-width="2"/>
    <path d="M8 10V5C8 2.2 10.2 0 13 0H38C40.8 0 43 2.2 43 5V10" stroke="#075C38" stroke-width="3" stroke-linecap="round"/>
    <path d="M25 10V45" stroke="#CFE5D9" stroke-width="2"/>
    <circle cx="25" cy="27" r="4" fill="#0BB66F"/>
  </g>
</svg>
''';
