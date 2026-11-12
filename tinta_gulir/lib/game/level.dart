import 'dart:typed_data';

/// Arah geser: atas, kanan, bawah, kiri.
const List<List<int>> dirs = [
  [0, -1],
  [1, 0],
  [0, 1],
  [-1, 0],
];
const List<String> dirNames = ['atas', 'kanan', 'bawah', 'kiri'];

enum LevelKind { acak, bentuk, tantangan, buatan }

/// Papan permainan. Grid diberi bingkai 1 kotak di semua sisi, sehingga
/// posisi jalur tidak pernah berada di tepi array.
class Level {
  Level({
    required this.number,
    required this.w,
    required this.h,
    required this.floor,
    required this.inMask,
    required this.start,
    required this.par,
    required this.kind,
    required this.name,
    this.moveLimit = 0,
  });

  final int number;
  final int w;
  final int h;
  final int start;
  final int par;
  final int moveLimit; // 0 = tanpa batas langkah
  final Uint8List floor; // 1 = posisi jalur yang bisa dilewati bola
  final Uint8List inMask; // 1 = bagian dari papan (jalur atau tonggak)
  final LevelKind kind;
  final String name;

  late final List<int> cells = [
    for (var i = 0; i < floor.length; i++)
      if (floor[i] == 1) i,
  ];

  int get cellCount => cells.length;

  int stepOf(int d) => dirs[d][1] * w + dirs[d][0];

  /// Posisi yang dilewati bola bila digeser dari [pos] ke arah [d].
  List<int> slide(int pos, int d) {
    final step = stepOf(d);
    final path = <int>[];
    var c = pos;
    while (floor[c + step] == 1) {
      c += step;
      path.add(c);
    }
    return path;
  }
}
