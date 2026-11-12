import 'dart:math';

import 'package:flutter/material.dart';

import '../games/scales.dart';
import '../progress.dart';
import '../theme.dart';
import 'common.dart';
import 'level_select.dart';

class ScalesScreen extends StatefulWidget {
  final int level;
  const ScalesScreen({super.key, required this.level});

  @override
  State<ScalesScreen> createState() => _ScalesScreenState();
}

class _ScalesScreenState extends State<ScalesScreen> {
  static const _mode = Mode.scales;
  late ScaleGame game;
  final Map<int, int> pans = {}; // koin -> 0 meja, 1 kiri, 2 kanan
  int beam = 0;
  String resultText = 'Belum menimbang';
  bool guessMode = false;
  int fails = 0;

  ScaleLevel get lv => kScaleLevels[widget.level - 1];

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  void _newGame() {
    game = ScaleGame(lv, DateTime.now().microsecondsSinceEpoch);
    pans.clear();
    beam = 0;
    resultText = 'Belum menimbang';
    guessMode = false;
  }

  List<int> _on(int pan) =>
      [for (var i = 0; i < lv.coins; i++) if ((pans[i] ?? 0) == pan) i];

  void _tapCoin(int i) {
    if (guessMode) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: kCard,
          title: Text('Koin ${i + 1} palsu?',
              style: const TextStyle(color: kText, fontWeight: FontWeight.w800)),
          content: const Text('Tebakan yang salah membuat levelnya diulang.',
              style: TextStyle(color: kSoft)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                _guess(i);
              },
              child: const Text('Yakin'),
            ),
          ],
        ),
      );
      return;
    }
    setState(() => pans[i] = ((pans[i] ?? 0) + 1) % 3);
  }

  void _weigh() {
    final l = _on(1);
    final r = _on(2);
    if (game.remaining <= 0) {
      snack(context, 'Kesempatan menimbang habis. Tebak koin palsunya.');
      return;
    }
    if (l.isEmpty || l.length != r.length) {
      snack(context, 'Isi kedua sisi dengan jumlah koin yang sama.');
      return;
    }
    final w = game.weigh(l, r);
    setState(() {
      beam = w.result;
      resultText = w.result == 0
          ? 'Seimbang'
          : (w.result > 0 ? 'Sisi kiri lebih berat' : 'Sisi kanan lebih berat');
      pans.clear();
    });
  }

  void _guess(int i) {
    final info = infoOf(_mode);
    final cands = game.candidates();
    final fakeText = game.fakeHeavy ? 'lebih berat' : 'lebih ringan';
    if (i == game.fake) {
      final lucky = cands.length > 1;
      final stars = lucky ? 1 : (fails == 0 ? 3 : (fails == 1 ? 2 : 1));
      Progress.setStars(info.key, widget.level, stars);
      showResult(
        context,
        success: true,
        title: lucky ? 'Benar, tapi menebak' : 'Tepat sekali!',
        stars: stars,
        color: info.color,
        message: lucky
            ? 'Hasil timbangmu belum cukup: masih ada ${cands.length} koin yang mungkin palsu. '
                'Coba lagi dan pastikan dulu lewat penimbangan.'
            : 'Koin ${i + 1} memang palsu ($fakeText). Kamu memakai ${game.history.length} dari ${lv.weighings} penimbangan.',
        onNext: widget.level < info.levels
            ? () => goNext(context, _mode, widget.level)
            : null,
        onRetry: () => setState(() {
          fails = 0;
          _newGame();
        }),
      );
    } else {
      showResult(
        context,
        success: false,
        title: 'Belum tepat',
        color: info.color,
        message:
            'Koin palsunya nomor ${game.fake + 1} ($fakeText). Masih ada ${cands.length} koin yang mungkin saat kamu menebak.\n\nCoba lagi dengan susunan baru.',
        onRetry: () => setState(() {
          fails++;
          _newGame();
        }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = infoOf(_mode);
    final table = _on(0);
    final size = lv.coins > 12 ? 34.0 : 44.0;
    final leftDown = beam > 0 ? 18.0 : (beam == 0 ? 9.0 : 0.0);
    final rightDown = beam < 0 ? 18.0 : (beam == 0 ? 9.0 : 0.0);

    return GameScaffold(
      mode: _mode,
      title: 'Level ${widget.level}',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: info.color.withValues(alpha: 0.35)),
            ),
            child: Column(
              children: [
                Text('${lv.coins} koin. ${lv.clue}.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: kText, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('Timbang tersisa: ${game.remaining} dari ${lv.weighings}',
                    style: TextStyle(
                        color: info.color, fontWeight: FontWeight.w800, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Tuas timbangan
          SizedBox(
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(width: 6, height: 44, color: kSoft.withValues(alpha: 0.5)),
                AnimatedRotation(
                  turns: -0.11 * beam / (2 * pi),
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOutBack,
                  child: Container(
                    width: 260,
                    height: 10,
                    decoration: BoxDecoration(
                      color: info.color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(resultText,
              textAlign: TextAlign.center,
              style: const TextStyle(color: kSoft, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _pan('Kiri', _on(1), size, leftDown, info.color)),
              const SizedBox(width: 12),
              Expanded(child: _pan('Kanan', _on(2), size, rightDown, info.color)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kBg.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: kCardHi),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Meja',
                    style: TextStyle(color: kSoft, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [for (final i in table) _coin(i, size)],
                ),
                if (table.isEmpty)
                  const Text('Semua koin ada di timbangan',
                      style: TextStyle(color: kSoft, fontSize: 12.5)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (guessMode)
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: kBad.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Mode tebak: sentuh koin yang kamu kira palsu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kText, fontWeight: FontWeight.w700)),
            ),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor: info.color,
                      foregroundColor: kBg,
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: guessMode ? null : _weigh,
                  icon: const Icon(Icons.balance_rounded),
                  label: const Text('Timbang'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: guessMode ? kBad : kText,
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () => setState(() => guessMode = !guessMode),
                  icon: Icon(guessMode ? Icons.close_rounded : Icons.help_center_rounded),
                  label: Text(guessMode ? 'Batal tebak' : 'Tebak koin palsu'),
                ),
              ),
            ],
          ),
          if (game.history.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Catatan timbangan',
                style: TextStyle(color: kSoft, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            for (var i = 0; i < game.history.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(_line(i, game.history[i]),
                    style: const TextStyle(color: kText, fontSize: 14)),
              ),
          ],
        ],
      ),
    );
  }

  String _line(int i, Weighing w) {
    String s(List<int> l) => l.map((e) => e + 1).join(', ');
    final r = w.result == 0
        ? 'seimbang'
        : (w.result > 0 ? 'kiri lebih berat' : 'kanan lebih berat');
    return '${i + 1}. [${s(w.left)}] lawan [${s(w.right)}]: $r';
  }

  Widget _pan(String label, List<int> coins, double size, double top, Color color) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutBack,
      padding: EdgeInsets.only(top: top),
      child: Container(
        constraints: const BoxConstraints(minHeight: 96),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(8), bottom: Radius.circular(36)),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [for (final i in coins) _coin(i, size)],
            ),
          ],
        ),
      ),
    );
  }

  Widget _coin(int i, double size) {
    return GestureDetector(
      onTap: () => _tapCoin(i),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
              colors: [Color(0xFFFFE9A8), Color(0xFFE0A526)], center: Alignment(-0.3, -0.3)),
          border: Border.all(
              color: guessMode ? kBad : Colors.white.withValues(alpha: 0.5), width: 2),
        ),
        child: Text('${i + 1}',
            style: TextStyle(
                color: kBg, fontWeight: FontWeight.w900, fontSize: size * 0.4)),
      ),
    );
  }
}
