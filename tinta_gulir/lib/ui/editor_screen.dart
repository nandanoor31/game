import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../game/custom.dart';
import '../game/generator.dart';
import '../game/level.dart';
import '../game/modes.dart';
import '../game/progress.dart';
import 'board_draw.dart';
import 'game_screen.dart';
import 'theme.dart';

/// Editor level: gambar jalur dan tonggak, tentukan posisi awal bola, lalu
/// periksa otomatis bahwa level bisa diselesaikan.
class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, this.initial, this.slot});
  final CustomDef? initial;
  final int? slot;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final Random _rnd = Random();
  final Color col = modeColor(Mode.buatan);
  int w = 6, h = 7;
  List<int> cells = [];
  int start = -1;
  int tool = 0; // 0 jalur, 1 tonggak, 2 posisi awal
  String msg = 'Gambar jalur, lalu tentukan posisi awal bola.';
  bool ok = false;
  Size boardSize = Size.zero;

  @override
  void initState() {
    super.initState();
    final d = widget.initial;
    if (d != null) {
      w = d.w;
      h = d.h;
      cells = [for (final ch in d.cells.split('')) ch == '1' ? 1 : 0];
      start = d.start;
    } else {
      _randomFill();
    }
  }

  void _randomFill() {
    final lv = generateLevel(LevelKind.acak, 1 + _rnd.nextInt(40));
    w = lv.w - 2;
    h = lv.h - 2;
    cells = [
      for (var y = 0; y < h; y++)
        for (var x = 0; x < w; x++) lv.floor[(y + 1) * lv.w + x + 1],
    ];
    start = ((lv.start ~/ lv.w) - 1) * w + (lv.start % lv.w) - 1;
  }

  CustomDef _def() => CustomDef(
        name: widget.initial?.name ?? 'Buatan',
        w: w,
        h: h,
        start: start,
        cells: cells.join(),
      );

  void _changed(String text) {
    ok = false;
    msg = text;
  }

  void _resize(int nw, int nh) {
    nw = nw.clamp(4, 8);
    nh = nh.clamp(4, 10);
    if (nw == w && nh == h) return;
    final old = cells;
    final ow = w;
    final oh = h;
    final nc = List<int>.filled(nw * nh, 0);
    for (var y = 0; y < min(oh, nh); y++) {
      for (var x = 0; x < min(ow, nw); x++) {
        nc[y * nw + x] = old[y * ow + x];
      }
    }
    var ns = -1;
    if (start >= 0) {
      final sx = start % ow, sy = start ~/ ow;
      if (sx < nw && sy < nh) ns = sy * nw + sx;
    }
    setState(() {
      w = nw;
      h = nh;
      cells = nc;
      start = ns;
      _changed('Ukuran papan diubah.');
    });
  }

  void _touch(Offset p) {
    if (boardSize == Size.zero) return;
    final lv = levelOfCustom(_def());
    final geo = Geo(lv, boardSize);
    final x = ((p.dx - geo.ox) / geo.c).floor() - 1;
    final y = ((p.dy - geo.oy) / geo.c).floor() - 1;
    if (x < 0 || y < 0 || x >= w || y >= h) return;
    final i = y * w + x;
    setState(() {
      switch (tool) {
        case 0:
          cells[i] = 1;
        case 1:
          cells[i] = 0;
          if (start == i) start = -1;
        default:
          cells[i] = 1;
          start = i;
      }
      _changed('Periksa dengan Uji main atau Simpan.');
    });
  }

  void _clear() {
    setState(() {
      cells = List<int>.filled(w * h, 0);
      start = -1;
      _changed('Papan dikosongkan. Gambar jalur baru.');
    });
  }

  Check _check() {
    final chk = checkCustom(_def());
    setState(() {
      ok = chk.ok;
      msg = chk.message;
    });
    return chk;
  }

  Future<void> _test() async {
    final chk = _check();
    if (!chk.ok) return;
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => GameScreen(
            mode: Mode.buatan,
            index: 1,
            preset: levelOfCustom(_def(), par: chk.par))));
  }

  void _save() {
    final chk = _check();
    if (!chk.ok) return;
    final pr = Progress.instance;
    final list = pr.customs();
    var d = _def();
    if (widget.slot == null) {
      d = CustomDef(
          name: 'Buatan ${list.length + 1}',
          w: d.w,
          h: d.h,
          start: d.start,
          cells: d.cells);
      list.add(d.encode());
    } else {
      list[widget.slot!] = d.encode();
    }
    pr.saveCustoms(list);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 14),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    tooltip: 'Kembali',
                    icon: const Icon(Icons.arrow_back),
                    color: kInk,
                  ),
                  Text('Buat level',
                      style: TextStyle(
                          color: col,
                          fontSize: 22,
                          fontWeight: FontWeight.w900)),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Row(
                  children: [
                    _stepper('Lebar', w, (v) => _resize(v, h)),
                    const Spacer(),
                    _stepper('Tinggi', h, (v) => _resize(w, v)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Row(
                  children: [
                    _toolChip('Jalur', 0),
                    const SizedBox(width: 8),
                    _toolChip('Tonggak', 1),
                    const SizedBox(width: 8),
                    _toolChip('Posisi awal', 2),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: LayoutBuilder(builder: (context, box) {
                    boardSize = Size(box.maxWidth, box.maxHeight);
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (d) => _touch(d.localPosition),
                      onPanStart: (d) => _touch(d.localPosition),
                      onPanUpdate: (d) => _touch(d.localPosition),
                      child: CustomPaint(
                          size: Size.infinite, painter: _EditorPainter(this)),
                    );
                  }),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Text(msg,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: ok ? const Color(0xFF3DDC97) : kMuted,
                        fontSize: 14.5)),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Column(
                  children: [
                    Row(children: [
                      _btn('Isi acak', () => setState(() {
                            _randomFill();
                            _changed('Papan acak dibuat. Ubah sesukamu.');
                          })),
                      const SizedBox(width: 10),
                      _btn('Kosongkan', _clear),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      _btn('Uji main', _test),
                      const SizedBox(width: 10),
                      _btn('Simpan', _save, primary: true),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepper(String label, int v, ValueChanged<int> f) {
    return Row(
      children: [
        Text('$label $v',
            style: const TextStyle(color: kInk, fontWeight: FontWeight.w600)),
        IconButton(
          onPressed: () => f(v - 1),
          icon: const Icon(Icons.remove_circle_outline),
          color: kMuted,
          visualDensity: VisualDensity.compact,
          tooltip: '$label kurang',
        ),
        IconButton(
          onPressed: () => f(v + 1),
          icon: const Icon(Icons.add_circle_outline),
          color: kMuted,
          visualDensity: VisualDensity.compact,
          tooltip: '$label tambah',
        ),
      ],
    );
  }

  Widget _toolChip(String t, int id) {
    final on = tool == id;
    return Expanded(
      child: Material(
        color: on ? col : kPanel,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => tool = id),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Center(
              child: Text(t,
                  style: TextStyle(
                      color: on ? const Color(0xFF1A1230) : kInk,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _btn(String t, VoidCallback f, {bool primary = false}) {
    return Expanded(
      child: FilledButton(
        onPressed: f,
        style: FilledButton.styleFrom(
            backgroundColor: primary ? col : kPanel,
            foregroundColor: primary ? const Color(0xFF1A1230) : kInk,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14))),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _EditorPainter extends CustomPainter {
  _EditorPainter(this.s);
  final _EditorScreenState s;

  @override
  bool shouldRepaint(covariant _EditorPainter old) => true;

  @override
  void paint(Canvas canvas, Size size) {
    final lv = levelOfCustom(s._def());
    final geo = Geo(lv, size);
    drawBoard(canvas, lv, geo, Uint8List(lv.floor.length), s.col);
    if (s.start >= 0) {
      final sx = s.start % s.w + 1, sy = s.start ~/ s.w + 1;
      drawBall(canvas, geo.center(sx.toDouble(), sy.toDouble()), geo.c, s.col);
    }
  }
}
