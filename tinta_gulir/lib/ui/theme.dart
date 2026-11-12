import 'package:flutter/material.dart';

import '../game/modes.dart';

const kBg = Color(0xFF15122E);
const kPanel = Color(0xFF211D45);
const kInk = Color(0xFFF4F1FF);
const kMuted = Color(0xFFA39ECF);
const kGroove = Color(0xFF0D0B22);
const kRim = Color(0xFF2C2860);
const kPeg = Color(0xFF3A3680);
const kPalette = <Color>[
  Color(0xFFFF6B57),
  Color(0xFFFFB627),
  Color(0xFF3DDC97),
  Color(0xFF4CC9F0),
  Color(0xFFB388FF),
  Color(0xFFFF5D9E),
];

Color modeColor(Mode m) => switch (m) {
      Mode.jelajah => const Color(0xFF4CC9F0),
      Mode.bentuk => const Color(0xFFFF5D9E),
      Mode.tantangan => const Color(0xFFFFB627),
      Mode.harian => const Color(0xFF3DDC97),
      Mode.buatan => const Color(0xFFB388FF),
    };

IconData modeIcon(Mode m) => switch (m) {
      Mode.jelajah => Icons.route,
      Mode.bentuk => Icons.interests,
      Mode.tantangan => Icons.bolt,
      Mode.harian => Icons.event_available,
      Mode.buatan => Icons.edit,
    };

/// Baris tiga bintang kecil.
Widget starRow(int n, {double size = 14}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < 3; i++)
        Icon(i < n ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: i < n ? const Color(0xFFFFC94A) : const Color(0xFF5A5690)),
    ],
  );
}
