import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../game/engine.dart';
import '../game/generator.dart';
import '../game/level.dart';
import '../game/modes.dart';
import '../game/progress.dart';
import 'board_draw.dart';
import 'theme.dart';

class _Anim {
  _Anim(this.path, this.from, this.start, this.dur, this.dir);
  final List<int> path;
  final int from;
  final double start;
  final double dur;
  final int dir;
}

class _Particle {
  _Particle(this.x, this.y, this.vx, this.vy, this.life, this.color, this.size);
  double x, y, vx, vy;
  double age = 0;
  final double life;
  final Color color;
  final double size;
}

class _Ripple {
  _Ripple(this.x, this.y, this.t0);
  final double x, y, t0;
}

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.mode,
    this.index = 1,
    this.preset,
  });

  final Mode mode;
  final int index;

  /// Level yang sudah jadi (mode Harian dan Buat Sendiri).
  final Level? preset;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final ValueNotifier<int> repaint = ValueNotifier(0);
  final ValueNotifier<int> hud = ValueNotifier(0);
  final Map<int, Level> _cache = {};
  final List<_Particle> particles = [];
  final List<Offset> tail = [];
  final List<_Ripple> ripples = [];
  final Random _rnd = Random();

  Level? level;
  GameState? gs;
  int levelNo = 1;
  Color paint = kPalette[0];
  _Anim? anim;
  double bx = 0, by = 0;
  int hintDir = -1;
  double hintT = 0;
  double bumpT = -10;
  int bumpDir = 0;
  double _now = 0;
  Duration _last = Duration.zero;
  int _lastCount = 0;
  bool showWin = false, showFail = false, loading = true;
  int stars = 0;
  String msg = '';
  Size boardSize = Size.zero;
  int _token = 0;
  Offset? _origin;
  bool _fired = false;

  Mode get mode => widget.mode;
  Progress get _pr => Progress.instance;

  @override
  void initState() {
    super.initState();
    levelNo = widget.index;
    _load(levelNo);
  }

  @override
  void dispose() {
    _ticker.dispose();
    repaint.dispose();
    hud.dispose();
    super.dispose();
  }

  Future<Level> _make(int n) async {
    final code = mode.index * 1000000 + n;
    try {
      return await compute(generateByCode, code);
    } catch (_) {
      return generateByCode(code);
    }
  }

  Future<void> _load(int n) async {
    final token = ++_token;
    setState(() => loading = true);
    final lv = widget.preset ?? _cache[n] ?? await _make(n);
    if (!mounted || token != _token) return;
    _cache[n] = lv;
    setState(() {
      level = lv;
      levelNo = n;
      gs = GameState(lv);
      _lastCount = gs!.count;
      anim = null;
      particles.clear();
      tail.clear();
      ripples.clear();
      hintDir = -1;
      showWin = false;
      showFail = false;
      loading = false;
      paint = kPalette[(n - 1) % kPalette.length];
      msg = (mode == Mode.jelajah && n == 1)
          ? 'Geser ke arah mana saja. Bola meluncur sampai menabrak dinding.'
          : (lv.moveLimit > 0
              ? 'Langkah terbatas. Rencanakan dengan cermat.'
              : 'Warnai seluruh jalur.');
      bx = (lv.start % lv.w).toDouble();
      by = (lv.start ~/ lv.w).toDouble();
    });
    hud.value++;
    repaint.value++;
  }

  void _kick() {
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  bool get _reduceMotion =>
      WidgetsBinding.instance.platformDispatcher.accessibilityFeatures
          .disableAnimations;

  void _move(int d) {
    final g = gs, lv = level;
    if (g == null || lv == null || anim != null) return;
    if (loading || showWin || showFail || g.outOfMoves) return;
    final path = lv.slide(g.pos, d);
    if (path.isEmpty) return;
    g.begin();
    g.recordSlide(g.pos, path);
    hintDir = -1;
    final dur = _reduceMotion ? 0.06 : max(0.14, path.length * 0.055);
    anim = _Anim(path, g.pos, _now, dur, d);
    if (mode == Mode.jelajah && levelNo == 1) {
      setState(() => msg = 'Bagus. Terus geser sampai seluruh jalur terwarnai.');
    }
    hud.value++;
    _kick();
  }

  void _tick(Duration e) {
    final dt = ((e - _last).inMicroseconds / 1e6).clamp(0.0, 0.05).toDouble();
    _last = e;
    _now += dt;
    final a = anim, g = gs, lv = level;
    if (a != null && g != null && lv != null) {
      final len = a.path.length;
      final t = ((_now - a.start) / a.dur).clamp(0.0, 1.0).toDouble();
      final p = t * len;
      final upto = min(len, (p + .5).floor());
      for (var k = 0; k < upto; k++) {
        g.paintCell(a.path[k]);
      }
      final i = min(len - 1, p.floor());
      final f = p - i;
      final from = i == 0 ? a.from : a.path[i - 1];
      final to = a.path[i];
      bx = (from % lv.w) + ((to % lv.w) - (from % lv.w)) * f;
      by = (from ~/ lv.w) + ((to ~/ lv.w) - (from ~/ lv.w)) * f;
      tail.add(Offset(bx, by));
      if (tail.length > 14) tail.removeAt(0);
      if (t >= 1) {
        for (final c in a.path) {
          g.paintCell(c);
        }
        g.pos = a.path.last;
        bx = (g.pos % lv.w).toDouble();
        by = (g.pos ~/ lv.w).toDouble();
        anim = null;
        bumpT = _now;
        bumpDir = a.dir;
        ripples.add(_Ripple(bx, by, _now));
        HapticFeedback.selectionClick();
        _afterMove(g);
      }
      if (g.count != _lastCount) {
        _lastCount = g.count;
        hud.value++;
      }
    } else if (tail.isNotEmpty) {
      tail.removeAt(0);
    }
    ripples.removeWhere((r) => _now - r.t0 > .55);
    for (final q in particles) {
      q.age += dt;
      q.vy += 620 * dt;
      q.x += q.vx * dt;
      q.y += q.vy * dt;
    }
    particles.removeWhere((q) => q.age >= q.life);
    if (hintDir >= 0 && _now - hintT > 2.4) hintDir = -1;
    repaint.value++;
    if (anim == null &&
        particles.isEmpty &&
        tail.isEmpty &&
        ripples.isEmpty &&
        hintDir < 0 &&
        _now - bumpT > .3) {
      _ticker.stop();
    }
  }

  void _afterMove(GameState g) {
    hud.value++;
    if (g.complete) {
      _win(g);
    } else if (g.outOfMoves) {
      final n = levelNo;
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && n == levelNo && gs == g && g.outOfMoves) {
          setState(() => showFail = true);
        }
      });
    }
  }

  void _win(GameState g) {
    final lv = level!;
    stars = starsFor(g.moves, lv.par);
    if (mode != Mode.buatan) _pr.setStars(mode, levelNo, stars);
    if (mode.sequential) _pr.unlock(mode, levelNo + 1);
    HapticFeedback.mediumImpact();
    if (!_reduceMotion && boardSize != Size.zero) {
      final geo = Geo(lv, boardSize);
      final p = geo.center(bx, by);
      final cols = [
        paint,
        Colors.white,
        const Color(0xFFFFD166),
        const Color(0xFF4CC9F0),
      ];
      for (var k = 0; k < 80; k++) {
        final ang = _rnd.nextDouble() * pi * 2;
        final sp = 120 + _rnd.nextDouble() * 320;
        particles.add(_Particle(
            p.dx,
            p.dy,
            cos(ang) * sp,
            sin(ang) * sp - 120,
            1.1 + _rnd.nextDouble() * .6,
            cols[k % cols.length],
            4 + _rnd.nextDouble() * 5));
      }
    }
    final n = levelNo;
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && n == levelNo && gs == g && g.complete) {
        setState(() => showWin = true);
      }
    });
  }

  void _undo() {
    final g = gs;
    if (g == null || anim != null || !g.canUndo) return;
    g.undo();
    showWin = false;
    showFail = false;
    hintDir = -1;
    tail.clear();
    _lastCount = g.count;
    final lv = level!;
    bx = (g.pos % lv.w).toDouble();
    by = (g.pos ~/ lv.w).toDouble();
    setState(() {});
    hud.value++;
    repaint.value++;
  }

  void _hint() {
    final g = gs;
    if (g == null || anim != null || showWin) return;
    final d = g.hint();
    if (d == null) {
      setState(() => msg = 'Posisi buntu. Tekan Urungkan atau Ulangi.');
      return;
    }
    hintDir = d;
    hintT = _now;
    setState(() => msg = 'Coba geser ke ${dirNames[d]}.');
    _kick();
  }

  // ------------------------------------------------------------------ UI

  bool get _hasNext {
    if (!mode.sequential) return false;
    return mode != Mode.bentuk || levelNo < bentukCount;
  }

  @override
  Widget build(BuildContext context) {
    final lv = level, g = gs;
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 16, 14),
          child: Column(
            children: [
              _header(),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: ValueListenableBuilder<int>(
                  valueListenable: hud,
                  builder: (context, value, child) => _stats(lv, g),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(child: _board()),
              SizedBox(
                height: 38,
                child: Center(
                  child: Text(msg,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: kMuted, fontSize: 15)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: _buttons(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    final seq = mode.sequential;
    final canPrev = seq && levelNo > 1 && !loading;
    final canNext = _hasNext && levelNo < _pr.unlocked(mode) && !loading;
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Kembali',
          icon: const Icon(Icons.arrow_back),
          color: kInk,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(mode.title.toUpperCase(),
                  style: TextStyle(
                      color: paint,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4)),
              Text(seq ? 'Level $levelNo' : (level?.name ?? ''),
                  style: const TextStyle(
                      color: kInk, fontSize: 20, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
        if (seq)
          Container(
            decoration: BoxDecoration(
                color: kPanel, borderRadius: BorderRadius.circular(99)),
            child: Row(
              children: [
                _navBtn(Icons.chevron_left, canPrev,
                    () => _load(levelNo - 1), 'Level sebelumnya'),
                _navBtn(Icons.chevron_right, canNext,
                    () => _load(levelNo + 1), 'Level berikutnya'),
              ],
            ),
          ),
      ],
    );
  }

  Widget _navBtn(IconData icon, bool on, VoidCallback f, String tip) {
    return IconButton(
      onPressed: on ? f : null,
      tooltip: tip,
      icon: Icon(icon),
      color: kInk,
      disabledColor: kMuted.withValues(alpha: .3),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _stats(Level? lv, GameState? g) {
    if (lv == null || g == null) return const SizedBox(height: 40);
    final pct = (g.progress * 100).floor();
    final right = lv.moveLimit > 0
        ? 'Sisa ${max(0, g.movesLeft)} langkah'
        : '${g.moves} langkah \u00B7 target ${lv.par}';
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: g.progress,
            minHeight: 10,
            color: paint,
            backgroundColor: kPanel,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${lv.name} \u00B7 $pct% terwarnai',
                style: const TextStyle(color: kMuted, fontSize: 14)),
            Text(right, style: const TextStyle(color: kMuted, fontSize: 14)),
          ],
        ),
      ],
    );
  }

  Widget _board() {
    return LayoutBuilder(builder: (context, box) {
      boardSize = Size(box.maxWidth, box.maxHeight);
      return Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (d) {
                  _origin = d.localPosition;
                  _fired = false;
                },
                onPanUpdate: (d) {
                  final o = _origin;
                  if (_fired || o == null) return;
                  final dx = d.localPosition.dx - o.dx;
                  final dy = d.localPosition.dy - o.dy;
                  if (max(dx.abs(), dy.abs()) < 22) return;
                  _fired = true;
                  if (dx.abs() > dy.abs()) {
                    _move(dx > 0 ? 1 : 3);
                  } else {
                    _move(dy > 0 ? 2 : 0);
                  }
                },
                child: CustomPaint(painter: _BoardPainter(this)),
              ),
            ),
            if (loading)
              const Center(child: CircularProgressIndicator(color: kMuted)),
            if (showWin) Center(child: _winCard()),
            if (showFail) Center(child: _failCard()),
          ],
        ),
      );
    });
  }

  Widget _card(String title, Widget? mid, String body, List<Widget> actions) {
    return Container(
      width: min(320, boardSize.width * .86),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        color: kPanel,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 40)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: paint, fontSize: 26, fontWeight: FontWeight.w900)),
          if (mid != null) ...[const SizedBox(height: 8), mid],
          const SizedBox(height: 6),
          Text(body,
              textAlign: TextAlign.center,
              style: const TextStyle(color: kMuted, fontSize: 15)),
          const SizedBox(height: 16),
          ...actions,
        ],
      ),
    );
  }

  ButtonStyle get _mainBtn => FilledButton.styleFrom(
      backgroundColor: paint,
      foregroundColor: const Color(0xFF1A1230),
      minimumSize: const Size.fromHeight(48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)));

  Widget _winCard() {
    final g = gs!, lv = level!;
    final body = g.moves <= lv.par
        ? 'Sempurna, ${g.moves} langkah.'
        : '${g.moves} langkah. Target ${lv.par}.';
    return _card('Selesai!', starRow(stars, size: 34), body, [
      FilledButton(
        onPressed: _hasNext
            ? () => _load(levelNo + 1)
            : () => Navigator.of(context).maybePop(),
        style: _mainBtn,
        child: Text(_hasNext ? 'Lanjut' : 'Kembali',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
      ),
      const SizedBox(height: 4),
      TextButton(
        onPressed: () => _load(levelNo),
        child: const Text('Main lagi', style: TextStyle(color: kInk)),
      ),
    ]);
  }

  Widget _failCard() {
    return _card('Langkah habis', null,
        'Batas langkah level ini terpakai semua.', [
      FilledButton(
        onPressed: () => _load(levelNo),
        style: _mainBtn,
        child: const Text('Ulangi',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
      ),
      const SizedBox(height: 4),
      TextButton(
        onPressed: _undo,
        child: const Text('Urungkan langkah terakhir',
            style: TextStyle(color: kInk)),
      ),
    ]);
  }

  Widget _buttons() {
    Widget b(String t, VoidCallback f) => Expanded(
          child: FilledButton(
            onPressed: loading ? null : f,
            style: FilledButton.styleFrom(
                backgroundColor: kPanel,
                foregroundColor: kInk,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14))),
            child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        );
    return Row(children: [
      b('Urungkan', _undo),
      const SizedBox(width: 10),
      b('Ulangi', () => _load(levelNo)),
      const SizedBox(width: 10),
      b('Petunjuk', _hint),
    ]);
  }
}

class _BoardPainter extends CustomPainter {
  _BoardPainter(this.s) : super(repaint: s.repaint);
  final _GameScreenState s;

  @override
  bool shouldRepaint(covariant _BoardPainter old) => true;

  @override
  void paint(Canvas canvas, Size size) {
    final lv = s.level, g = s.gs;
    if (lv == null || g == null) return;
    final geo = Geo(lv, size);
    final c = geo.c;
    final ink = s.paint;
    drawBoard(canvas, lv, geo, g.painted, ink, edges: g.edges);

    final b = geo.center(s.bx, s.by);
    final rad = c * .27;

    // Ujung tinta yang mengalir mengikuti bola.
    final a = s.anim;
    if (a != null) {
      final from = geo.center(
          (a.from % lv.w).toDouble(), (a.from ~/ lv.w).toDouble());
      canvas.drawLine(
          from,
          b,
          Paint()
            ..strokeCap = StrokeCap.round
            ..strokeWidth = geo.trackW * .78
            ..color = ink);
    }

    // Ekor komet yang meruncing dan memudar.
    final n = s.tail.length;
    final tailCol = Color.lerp(ink, Colors.white, .55)!;
    for (var k = 1; k < n; k++) {
      final p0 = geo.center(s.tail[k - 1].dx, s.tail[k - 1].dy);
      final p1 = geo.center(s.tail[k].dx, s.tail[k].dy);
      final f = k / n;
      canvas.drawLine(
          p0,
          p1,
          Paint()
            ..strokeCap = StrokeCap.round
            ..strokeWidth = rad * 1.7 * f
            ..color = tailCol.withValues(alpha: .6 * f));
    }

    // Riak kecil saat bola berhenti.
    for (final r in s.ripples) {
      final age = (s._now - r.t0) / .5;
      if (age < 0 || age > 1) continue;
      final p = geo.center(r.x, r.y);
      canvas.drawCircle(
          p,
          rad * (1 + age * 1.9),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = max(1.5, c * .06 * (1 - age))
            ..color = Colors.white.withValues(alpha: .55 * (1 - age)));
    }

    // Bola, dengan penyok kecil saat berhenti.
    var sx = 1.0, sy = 1.0;
    final age = s._now - s.bumpT;
    if (s.anim == null && age < .22) {
      final k = sin(age / .22 * pi) * .16;
      if (s.bumpDir % 2 == 0) {
        sy = 1 - k;
        sx = 1 + k;
      } else {
        sx = 1 - k;
        sy = 1 + k;
      }
    }
    drawBall(canvas, b, c, ink, sx: sx, sy: sy);

    // Petunjuk arah.
    if (s.hintDir >= 0) {
      final e = s._now - s.hintT;
      final off = c * (.72 + .1 * sin(e * 9));
      canvas.save();
      canvas.translate(b.dx, b.dy);
      canvas.rotate(s.hintDir * pi / 2);
      final p = Path()
        ..moveTo(-c * .2, -off + c * .12)
        ..lineTo(0, -off - c * .1)
        ..lineTo(c * .2, -off + c * .12);
      canvas.drawPath(
          p,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = max(3, c * .09)
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color = Colors.white);
      canvas.restore();
    }

    // Konfeti.
    for (final q in s.particles) {
      final al = (1 - q.age / q.life).clamp(0.0, 1.0).toDouble();
      canvas.drawCircle(Offset(q.x, q.y), q.size / 2,
          Paint()..color = q.color.withValues(alpha: al));
    }
  }
}
