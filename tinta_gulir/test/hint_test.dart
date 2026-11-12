import 'package:flutter_test/flutter_test.dart';
import 'package:gulir/game/engine.dart';
import 'package:gulir/game/generator.dart';
import 'package:gulir/game/modes.dart';

void main() {
  test('mengikuti petunjuk selalu selesai tanpa bolak-balik', () {
    for (final mode in [Mode.jelajah, Mode.bentuk, Mode.tantangan]) {
      for (var n = 1; n <= 12; n++) {
        final lv = levelFor(mode, n);
        final g = GameState(lv);
        var steps = 0;
        while (!g.complete && steps < 80) {
          final d = g.hint();
          expect(d, isNotNull, reason: '$mode $n buntu');
          final path = lv.slide(g.pos, d!);
          g.begin();
          for (final c in path) {
            g.paintCell(c);
          }
          g.pos = path.last;
          steps++;
        }
        expect(g.complete, true, reason: '$mode $n');
        expect(steps, lv.par, reason: '$mode $n tidak terpendek');
      }
    }
  });
}
