import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nalar/games/detective.dart';
import 'package:nalar/games/rule_machine.dart';
import 'package:nalar/games/scales.dart';
import 'package:nalar/games/shadow.dart';

void main() {
  test('Mesin Aturan: semua soal punya 4 pilihan unik dan jawaban benar ada', () {
    for (var level = 1; level <= 30; level++) {
      for (var v = 0; v < 6; v++) {
        final p = makeRulePuzzle(level, variant: v);
        expect(p.options.length, 4, reason: 'level $level v$v');
        expect(p.options.toSet().length, 4, reason: 'level $level v$v');
        expect(p.options.contains(p.answer), isTrue);
        expect(p.examples.length >= 3, isTrue);
        expect(p.extras.length, 2);
      }
    }
  });

  test('Detektif: tiap kasus punya tepat satu pelaku yang cocok dengan aturan', () {
    for (var level = 1; level <= 30; level++) {
      for (var v = 0; v < 4; v++) {
        final c = makeCase(level, variant: v);
        final sols = solutions(c.rule, c.statements, c.names.length);
        expect(sols, [c.culprit], reason: 'level $level v$v');
        expect(c.names.toSet().length, c.names.length);
      }
    }
  });

  test('Timbangan: tiap level memenuhi batas teori agar bisa diselesaikan', () {
    for (final lv in kScaleLevels) {
      final cap = lv.known
          ? pow(3, lv.weighings)
          : (pow(3, lv.weighings) - 3) / 2;
      expect(lv.coins <= cap, isTrue,
          reason: '${lv.coins} koin, ${lv.weighings} timbang');
    }
  });

  test('Timbangan: koin palsu selalu termasuk kandidat', () {
    final rnd = Random(1);
    for (var li = 0; li < kScaleLevels.length; li++) {
      for (var t = 0; t < 30; t++) {
        final g = ScaleGame(kScaleLevels[li], rnd.nextInt(1 << 30));
        for (var k = 0; k < kScaleLevels[li].weighings; k++) {
          final all = List.generate(kScaleLevels[li].coins, (i) => i)
            ..shuffle(rnd);
          final n = 1 + rnd.nextInt(all.length ~/ 2);
          g.weigh(all.take(n).toList(), all.skip(n).take(n).toList());
          expect(g.candidates().contains(g.fake), isTrue);
        }
      }
    }
  });

  test('Bayangan Diri: semua level terbukti bisa diselesaikan', () {
    for (var i = 0; i < kShadowLevels.length; i++) {
      expect(verifySolution(kShadowLevels[i]), isTrue,
          reason: 'level ${i + 1}: ${kShadowLevels[i].name}');
    }
  });

  test('Bayangan Diri: pintu tertutup menghalangi tanpa bayangan', () {
    final g = ShadowGame(kShadowLevels[0]);
    for (var i = 0; i < 3; i++) {
      g.step(Move.right);
    }
    expect(g.step(Move.right), StepResult.blocked);
  });
}
