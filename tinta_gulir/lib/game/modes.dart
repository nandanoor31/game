import 'dart:math';

enum Mode { jelajah, bentuk, tantangan, harian, buatan }

extension ModeInfo on Mode {
  String get title => switch (this) {
        Mode.jelajah => 'Jelajah',
        Mode.bentuk => 'Bentuk',
        Mode.tantangan => 'Tantangan',
        Mode.harian => 'Harian',
        Mode.buatan => 'Buat Sendiri',
      };

  String get blurb => switch (this) {
        Mode.jelajah => 'Level berurutan tanpa akhir, makin lama makin besar.',
        Mode.bentuk => 'Papan berbentuk hati, berlian, bintang, dan lainnya.',
        Mode.tantangan => 'Langkah dibatasi. Rencanakan dengan cermat.',
        Mode.harian => 'Satu level baru setiap hari.',
        Mode.buatan => 'Gambar papan sendiri dan mainkan.',
      };

  /// Mode yang levelnya dibuka satu per satu.
  bool get sequential =>
      this == Mode.jelajah || this == Mode.bentuk || this == Mode.tantangan;
}

/// Bintang dari jumlah langkah: 3 bila langkah <= par.
int starsFor(int moves, int par) {
  if (moves <= par) return 3;
  if (moves <= par + max(2, par ~/ 3)) return 2;
  return 1;
}
