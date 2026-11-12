import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../games/shadow.dart';
import '../progress.dart';
import '../theme.dart';
import 'common.dart';
import 'level_select.dart';

const _doorColors = {
  'a': Color(0xFF5BE3A1),
  'b': Color(0xFF6EC1FF),
};

const _ghostColors = [
  Color(0xFFFF8FA3), Color(0xFFFFB86B), Color(0xFFFFE066), Color(0xFFC4A1FF),
];

class ShadowScreen extends StatefulWidget {
  final int level;
  const ShadowScreen({super.key, required this.level});

  @override
  State<ShadowScreen> createState() => _ShadowScreenState();
}

class _ShadowScreenState extends State<ShadowScreen> {
  static const _mode = Mode.shadow;
  late ShadowGame g;
  int manualResets = 0;
  Offset _acc = Offset.zero;

  ShadowLevel get lv => kShadowLevels[widget.level - 1];

  @override
  void initState() {
    super.initState();
    g = ShadowGame(lv);
  }

  void _do(Move m) {
    final res = g.step(m);
    switch (res) {
      case StepResult.blocked:
        HapticFeedback.selectionClick();
      case StepResult.limit:
        snack(context, 'Waktu putaran habis. Tekan Selesai putaran atau Ulang putaran.');
      case StepResult.crushed:
        HapticFeedback.heavyImpact();
        snack(context, 'Pintu menutup di atasmu! Putaran diulang.',
            color: kBad.withValues(alpha: 0.8));
      case StepResult.won:
        _win();
      case StepResult.moved:
        break;
    }
    setState(() {});
  }

  void _win() {
    final info = infoOf(_mode);
    final errors = manualResets + g.mistakes;
    final stars = errors == 0 ? 3 : (errors <= 2 ? 2 : 1);
    Progress.setStars(info.key, widget.level, stars);
    showResult(
      context,
      success: true,
      title: 'Berhasil!',
      stars: stars,
      color: info.color,
      message:
          'Kamu bekerja sama dengan ${g.recordings.length} bayangan dirimu sendiri.',
      onNext: widget.level < info.levels
          ? () => goNext(context, _mode, widget.level)
          : null,
      onRetry: () => setState(() {
        g = ShadowGame(lv);
        manualResets = 0;
      }),
    );
  }

  void _swipeEnd() {
    final d = _acc;
    _acc = Offset.zero;
    if (d.distance < 20) return;
    if (d.dx.abs() > d.dy.abs()) {
      _do(d.dx > 0 ? Move.right : Move.left);
    } else {
      _do(d.dy > 0 ? Move.down : Move.up);
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = infoOf(_mode);
    return GameScaffold(
      mode: _mode,
      title: 'Level ${widget.level}: ${lv.name}',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Text(
                    'Putaran ${g.round + 1} dari ${g.rounds}   •   Langkah ${g.tick}/${lv.maxTicks}   •   Bayangan ${g.recordings.length}',
                    style: TextStyle(
                        color: info.color, fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    g.isLastRound
                        ? 'Putaran terakhir: capai bendera.'
                        : 'Rekam gerakanmu, lalu tekan "Selesai putaran".',
                    style: const TextStyle(color: kSoft, fontSize: 12.5),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: g.cols * 72.0),
                  child: AspectRatio(
                    aspectRatio: g.cols / g.rows,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: (_) => _acc = Offset.zero,
                      onPanUpdate: (d) => _acc += d.delta,
                      onPanEnd: (_) => _swipeEnd(),
                      child: CustomPaint(painter: _BoardPainter(g)),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _dpad(info.color),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!g.isLastRound)
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                              backgroundColor: info.color, foregroundColor: kBg),
                          onPressed: () {
                            g.endRound();
                            snack(context,
                                'Rekaman tersimpan. Bayanganmu akan mengulang gerakan tadi.');
                            setState(() {});
                          },
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('Selesai putaran'),
                        ),
                      OutlinedButton.icon(
                        onPressed: () => setState(() => g.undo()),
                        icon: const Icon(Icons.undo_rounded),
                        label: const Text('Mundur 1 langkah'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => setState(() {
                          manualResets++;
                          g.resetRound();
                        }),
                        icon: const Icon(Icons.restart_alt_rounded),
                        label: const Text('Ulang putaran'),
                      ),
                      TextButton.icon(
                        onPressed: () => showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: kCard,
                            title: const Text('Petunjuk',
                                style: TextStyle(
                                    color: kText, fontWeight: FontWeight.w800)),
                            content: Text(lv.hint,
                                style: const TextStyle(color: kSoft, fontSize: 15)),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Tutup')),
                            ],
                          ),
                        ),
                        icon: const Icon(Icons.lightbulb_outline_rounded),
                        label: const Text('Petunjuk'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, Move m, Color color) => SizedBox(
        width: 56,
        height: 56,
        child: FilledButton(
          style: FilledButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: color.withValues(alpha: 0.25),
            foregroundColor: kText,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: () => _do(m),
          child: Icon(icon, size: 28),
        ),
      );

  Widget _dpad(Color color) {
    const gap = SizedBox(width: 56, height: 56);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          gap,
          _btn(Icons.keyboard_arrow_up_rounded, Move.up, color),
          gap,
        ]),
        Row(mainAxisSize: MainAxisSize.min, children: [
          _btn(Icons.keyboard_arrow_left_rounded, Move.left, color),
          _btn(Icons.hourglass_bottom_rounded, Move.wait, kGold),
          _btn(Icons.keyboard_arrow_right_rounded, Move.right, color),
        ]),
        Row(mainAxisSize: MainAxisSize.min, children: [
          gap,
          _btn(Icons.keyboard_arrow_down_rounded, Move.down, color),
          gap,
        ]),
      ],
    );
  }
}

class _BoardPainter extends CustomPainter {
  final ShadowGame g;
  _BoardPainter(this.g);

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / g.cols;
    Rect rectOf(P p, [double inset = 0]) => Rect.fromLTWH(
        p.c * cell + inset, p.r * cell + inset, cell - inset * 2, cell - inset * 2);
    final clones = g.clonesAt(g.tick);
    final actors = [...clones, g.live];

    for (var r = 0; r < g.rows; r++) {
      for (var c = 0; c < g.cols; c++) {
        final p = P(r, c);
        if (c >= g.level.grid[r].length) continue;
        if (g.walls.contains(p)) {
          canvas.drawRRect(
              RRect.fromRectAndRadius(rectOf(p, 1.5), Radius.circular(cell * 0.18)),
              Paint()..color = const Color(0xFF141642));
        } else {
          canvas.drawRRect(
              RRect.fromRectAndRadius(rectOf(p, 1.5), Radius.circular(cell * 0.18)),
              Paint()..color = const Color(0xFF2F3380));
        }
      }
    }

    // Bendera
    final e = rectOf(g.exit);
    canvas.drawCircle(e.center, cell * 0.36,
        Paint()..color = kGold.withValues(alpha: 0.22));
    final pole = Paint()
      ..color = kGold
      ..strokeWidth = cell * 0.06
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(e.center.dx - cell * 0.1, e.center.dy - cell * 0.26),
        Offset(e.center.dx - cell * 0.1, e.center.dy + cell * 0.26), pole);
    canvas.drawPath(
        Path()
          ..moveTo(e.center.dx - cell * 0.1, e.center.dy - cell * 0.26)
          ..lineTo(e.center.dx + cell * 0.26, e.center.dy - cell * 0.12)
          ..lineTo(e.center.dx - cell * 0.1, e.center.dy + cell * 0.02)
          ..close(),
        Paint()..color = kGold);

    // Tombol
    g.buttons.forEach((color, list) {
      final col = _doorColors[color]!;
      for (final b in list) {
        final on = actors.contains(b);
        final c = rectOf(b).center;
        canvas.drawCircle(
            c,
            cell * 0.3,
            Paint()
              ..color = col.withValues(alpha: on ? 0.95 : 0.25));
        canvas.drawCircle(
            c,
            cell * 0.3,
            Paint()
              ..color = col
              ..style = PaintingStyle.stroke
              ..strokeWidth = cell * 0.06);
      }
    });

    // Pintu
    g.doors.forEach((p, color) {
      final col = _doorColors[color]!;
      final open = g.doorOpen(color, g.tick, g.live);
      final rr = RRect.fromRectAndRadius(rectOf(p, cell * 0.06), Radius.circular(cell * 0.14));
      if (open) {
        canvas.drawRRect(rr, Paint()..color = col.withValues(alpha: 0.16));
        canvas.drawRRect(
            rr,
            Paint()
              ..color = col.withValues(alpha: 0.7)
              ..style = PaintingStyle.stroke
              ..strokeWidth = cell * 0.05);
      } else {
        canvas.drawRRect(rr, Paint()..color = col.withValues(alpha: 0.92));
        final c = rectOf(p).center;
        canvas.drawRect(
            Rect.fromCenter(center: c, width: cell * 0.34, height: cell * 0.06),
            Paint()..color = const Color(0xFF141642));
      }
    });

    // Bayangan
    for (var k = 0; k < clones.length; k++) {
      final c = rectOf(clones[k]).center;
      final col = _ghostColors[k % _ghostColors.length];
      canvas.drawCircle(c, cell * 0.3, Paint()..color = col.withValues(alpha: 0.55));
      canvas.drawCircle(
          c,
          cell * 0.3,
          Paint()
            ..color = col
            ..style = PaintingStyle.stroke
            ..strokeWidth = cell * 0.05);
    }

    // Kamu
    final lc = rectOf(g.live).center;
    canvas.drawCircle(
        lc,
        cell * 0.42,
        Paint()
          ..color = const Color(0xFFB28CFF).withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawCircle(lc, cell * 0.28, Paint()..color = Colors.white);
    canvas.drawCircle(lc, cell * 0.12, Paint()..color = const Color(0xFF5B4BE8));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
