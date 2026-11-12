import 'dart:math';

/// Satu aturan rahasia untuk Mesin Aturan.
class Rule {
  final String text;
  final int tier;
  final int Function(int) f;
  final bool twoDigit;
  const Rule(this.text, this.tier, this.f, {this.twoDigit = false});
}

int _digitSum(int x) {
  var s = 0;
  var n = x;
  while (n > 0) {
    s += n % 10;
    n ~/= 10;
  }
  return s;
}

int _reverse(int x) {
  var r = 0;
  var n = x;
  while (n > 0) {
    r = r * 10 + n % 10;
    n ~/= 10;
  }
  return r;
}

List<Rule> _buildAll() {
  final list = <Rule>[];
  for (var k = 1; k <= 20; k++) {
    list.add(Rule('Angka ditambah $k', 0, (x) => x + k));
  }
  for (var k = 2; k <= 12; k++) {
    list.add(Rule('Angka dikali $k', 0, (x) => x * k));
  }
  for (var c = 10; c <= 100; c++) {
    list.add(Rule('$c dikurangi angka', 1, (x) => c - x));
  }
  for (var k = 2; k <= 6; k++) {
    for (var c = -9; c <= 9; c++) {
      if (c == 0) continue;
      list.add(Rule(
          c > 0
              ? 'Angka dikali $k, lalu ditambah $c'
              : 'Angka dikali $k, lalu dikurangi ${-c}',
          2,
          (x) => x * k + c));
    }
  }
  list.add(Rule('Angka dikali dirinya sendiri', 3, (x) => x * x));
  for (var c = 1; c <= 9; c++) {
    list.add(Rule(
        'Angka dikali dirinya sendiri, lalu ditambah $c', 3, (x) => x * x + c));
  }
  list.add(Rule('Angka ditambah jumlah semua digitnya', 4,
      (x) => x + _digitSum(x)));
  list.add(Rule('Urutan digit angka dibalik', 4, _reverse, twoDigit: true));
  for (var a = 1; a <= 9; a++) {
    for (var b = 2; b <= 5; b++) {
      list.add(Rule('Jika genap ditambah $a, jika ganjil dikali $b', 5,
          (x) => x.isEven ? x + a : x * b));
    }
  }
  return list;
}

final List<Rule> _all = _buildAll();

class RulePuzzle {
  final List<(int, int)> examples;
  final List<(int, int)> extras;
  final int question;
  final int answer;
  final List<int> options;
  final String ruleText;
  const RulePuzzle(this.examples, this.extras, this.question, this.answer,
      this.options, this.ruleText);
}

List<int>? _pickInputs(Random rnd, int need, int lo, int hi, bool noTens) {
  final pool = <int>[
    for (var v = lo; v <= hi; v++)
      if (!(noTens && v % 10 == 0)) v
  ]..shuffle(rnd);
  if (pool.length < need) return null;
  return pool.take(need).toList();
}

/// Soal selalu punya jawaban pasti: semua aturan yang cocok dengan contoh
/// (dalam jenjang kesulitan itu) menghasilkan angka yang sama untuk pertanyaan.
RulePuzzle makeRulePuzzle(int level, {int variant = 0}) {
  final rnd = Random(level * 7919 + variant * 104729 + 13);
  final tier = ((level - 1) ~/ 5).clamp(0, 5);
  final pool = _all.where((r) => r.tier <= tier).toList();
  final newest = pool.where((r) => r.tier == tier).toList();
  final (lo, hi) = switch (tier) {
    0 => (1, 9),
    1 => (1, 12),
    2 => (2, 20),
    3 => (3, 30),
    _ => (10, 60),
  };
  final baseN = tier < 2 ? 3 : 4;

  for (var extra = 0; extra <= 3; extra++) {
    for (var t = 0; t < 150; t++) {
      final rule = (newest.isNotEmpty && rnd.nextDouble() < 0.6)
          ? newest[rnd.nextInt(newest.length)]
          : pool[rnd.nextInt(pool.length)];
      final n = baseN + extra;
      final ins = _pickInputs(rnd, n + 3, rule.twoDigit ? max(lo, 10) : lo,
          rule.twoDigit ? max(hi, 20) : hi, rule.twoDigit);
      if (ins == null) continue;
      final ex = ins.take(n).toList()..sort();
      final q = ins[n];
      final extraIns = ins.skip(n + 1).toList();
      bool okVal(int v) => v > 0 && v < 100000;
      if (![...ex, q, ...extraIns].every((x) => okVal(rule.f(x)))) continue;
      final cands =
          pool.where((r) => ex.every((x) => r.f(x) == rule.f(x))).toList();
      if (cands.any((r) => r.f(q) != rule.f(q))) continue;
      return _finish(rnd, pool, rule, ex, q, extraIns);
    }
  }
  // Cadangan: soal paling sederhana yang pasti jelas.
  final rule = _all.firstWhere((r) => r.text == 'Angka ditambah 3');
  return _finish(rnd, pool, rule, [2, 5, 7], 9, [4, 11]);
}

RulePuzzle _finish(Random rnd, List<Rule> pool, Rule rule, List<int> ex, int q,
    List<int> extraIns) {
  final answer = rule.f(q);
  final wrong = <int>{};
  final traps = pool
      .where((r) =>
          ex.take(ex.length - 1).every((x) => r.f(x) == rule.f(x)))
      .map((r) => r.f(q))
      .where((v) => v != answer && v > 0)
      .toSet()
      .toList()
    ..shuffle(rnd);
  for (final v in traps) {
    if (wrong.length >= 3) break;
    wrong.add(v);
  }
  while (wrong.length < 3) {
    final d = rnd.nextInt(8) + 1;
    final v = answer + (rnd.nextBool() ? d : -d);
    if (v > 0 && v != answer) wrong.add(v);
  }
  final options = [answer, ...wrong]..shuffle(rnd);
  return RulePuzzle(
    [for (final x in ex) (x, rule.f(x))],
    [for (final x in extraIns) (x, rule.f(x))],
    q,
    answer,
    options,
    rule.text,
  );
}
