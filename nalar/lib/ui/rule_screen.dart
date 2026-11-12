import 'dart:math';

import 'package:flutter/material.dart';

import '../games/rule_machine.dart';
import '../progress.dart';
import '../theme.dart';
import 'common.dart';
import 'level_select.dart';

class RuleScreen extends StatefulWidget {
  final int level;
  const RuleScreen({super.key, required this.level});

  @override
  State<RuleScreen> createState() => _RuleScreenState();
}

class _RuleScreenState extends State<RuleScreen> {
  static const _mode = Mode.rule;
  late RulePuzzle p;
  int variant = 0;
  int wrongs = 0;
  int hints = 0;
  final Set<int> tried = {};

  @override
  void initState() {
    super.initState();
    p = makeRulePuzzle(widget.level);
  }

  void _restart({bool newPuzzle = false}) {
    setState(() {
      if (newPuzzle) {
        variant++;
        p = makeRulePuzzle(widget.level, variant: variant);
      }
      wrongs = 0;
      hints = 0;
      tried.clear();
    });
  }

  void _pick(int v) {
    if (tried.contains(v)) return;
    final info = infoOf(_mode);
    if (v == p.answer) {
      final stars = max(1, 3 - wrongs - hints);
      Progress.setStars(info.key, widget.level, stars);
      showResult(
        context,
        success: true,
        title: 'Benar!',
        stars: stars,
        color: info.color,
        message: 'Aturannya: ${p.ruleText}.',
        onNext: widget.level < info.levels
            ? () => goNext(context, _mode, widget.level)
            : null,
        onRetry: () => _restart(),
      );
      return;
    }
    setState(() {
      wrongs++;
      tried.add(v);
    });
    if (wrongs >= 3) {
      showResult(
        context,
        success: false,
        title: 'Nyawa habis',
        color: info.color,
        message:
            'Jawaban yang benar: ${p.answer}.\nAturannya: ${p.ruleText}.\n\nCoba lagi dengan soal baru.',
        onRetry: () => _restart(newPuzzle: true),
      );
    } else {
      snack(context, 'Belum tepat. Perhatikan lagi contohnya.', color: kBad.withValues(alpha: 0.8));
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = infoOf(_mode);
    final shownExtras = p.extras.take(hints).toList();
    final rows = [...p.examples, ...shownExtras];
    return GameScaffold(
      mode: _mode,
      title: 'Level ${widget.level}',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Icon(
                    i < 3 - wrongs ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: kBad,
                    size: 26,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: info.color.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.settings_rounded, color: info.color, size: 18),
                    const SizedBox(width: 6),
                    const Text('Contoh dari mesin',
                        style: TextStyle(color: kSoft, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 10),
                for (final e in rows) _line(e.$1, '${e.$2}', info.color, false),
                const Divider(color: kCardHi, height: 22),
                _line(p.question, '?', kGold, true),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text('Berapa hasil untuk angka terakhir?',
              textAlign: TextAlign.center,
              style: TextStyle(color: kText, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: [
              for (final o in p.options)
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: tried.contains(o)
                        ? kCard.withValues(alpha: 0.4)
                        : info.color.withValues(alpha: 0.22),
                    foregroundColor: tried.contains(o) ? kSoft.withValues(alpha: 0.4) : kText,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: tried.contains(o) ? null : () => _pick(o),
                  child: Text('$o',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (hints < p.extras.length)
            Center(
              child: TextButton.icon(
                onPressed: () => setState(() => hints++),
                icon: const Icon(Icons.lightbulb_outline_rounded),
                label: const Text('Contoh tambahan (kurangi 1 bintang)'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _line(int input, String output, Color color, bool question) {
    Widget box(String t, Color c) => Container(
          constraints: const BoxConstraints(minWidth: 84),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(t,
              textAlign: TextAlign.center,
              style: TextStyle(color: c, fontSize: 22, fontWeight: FontWeight.w800)),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          box('$input', kText),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.arrow_forward_rounded, color: color),
          ),
          box(output, color),
        ],
      ),
    );
  }
}
