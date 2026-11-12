import 'dart:math';

enum StType { accuse, deny, either, neither }

class Statement {
  final StType type;
  final int a;
  final int b;
  const Statement(this.type, this.a, [this.b = -1]);

  bool truth(int culprit) => switch (type) {
        StType.accuse => culprit == a,
        StType.deny => culprit != a,
        StType.either => culprit == a || culprit == b,
        StType.neither => culprit != a && culprit != b,
      };
}

/// rule 1: tepat satu orang berbohong
/// rule 2: pelaku pasti berbohong, yang lain pasti jujur
/// rule 3: tepat dua orang berbohong
bool _consistent(int rule, List<Statement> st, int c) {
  final truths = [for (final s in st) s.truth(c)];
  final lies = truths.where((t) => !t).length;
  switch (rule) {
    case 1:
      return lies == 1;
    case 2:
      for (var i = 0; i < truths.length; i++) {
        if (truths[i] != (i != c)) return false;
      }
      return true;
    default:
      return lies == 2;
  }
}

List<int> solutions(int rule, List<Statement> st, int n) =>
    [for (var c = 0; c < n; c++) if (_consistent(rule, st, c)) c];

class DetectiveCase {
  final String title;
  final String question;
  final List<String> names;
  final List<Statement> statements;
  final int rule;
  final int culprit;
  const DetectiveCase(this.title, this.question, this.names, this.statements,
      this.rule, this.culprit);

  String get ruleText => switch (rule) {
        1 => 'Tepat satu orang berbohong. Yang lain jujur.',
        2 => 'Pelaku pasti berbohong. Yang bukan pelaku pasti jujur.',
        _ => 'Tepat dua orang berbohong. Yang lain jujur.',
      };

  String _ref(int j, int speaker) => j == speaker ? 'saya' : names[j];

  String say(int i) {
    final s = statements[i];
    switch (s.type) {
      case StType.accuse:
        return s.a == i ? 'Saya pelakunya.' : '${names[s.a]} pelakunya.';
      case StType.deny:
        return s.a == i
            ? 'Bukan saya pelakunya.'
            : 'Bukan ${names[s.a]} pelakunya.';
      case StType.either:
        return 'Pelakunya ${_ref(s.a, i)} atau ${_ref(s.b, i)}.';
      case StType.neither:
        return 'Pelakunya bukan ${_ref(s.a, i)} dan bukan ${_ref(s.b, i)}.';
    }
  }

  /// Penjelasan setelah kasus terpecahkan.
  List<String> explain() => [
        for (var i = 0; i < names.length; i++)
          '${names[i]}: "${say(i)}" → '
              '${statements[i].truth(culprit) ? "benar" : "bohong"}',
      ];
}

const _namePool = [
  'Andi', 'Budi', 'Citra', 'Dewi', 'Eko', 'Fajar',
  'Gita', 'Hana', 'Indra', 'Joko', 'Kiki', 'Lala',
];

const _scenes = [
  ('Toples kue kosong!', 'Siapa yang menghabiskan kuenya?'),
  ('Lampu ruang tamu pecah!', 'Siapa yang memecahkannya?'),
  ('Mainan hilang dari kamar!', 'Siapa yang mengambilnya?'),
  ('Dinding dicoret-coret!', 'Siapa yang mencoretnya?'),
  ('Kunci motor menghilang!', 'Siapa yang menyembunyikannya?'),
];

/// Kasus selalu punya tepat satu jawaban yang cocok dengan aturan.
DetectiveCase makeCase(int level, {int variant = 0}) {
  final rnd = Random(level * 6007 + variant * 7777 + 5);
  final n = level <= 5 ? 3 : (level <= 12 ? 4 : (level <= 22 ? 5 : 6));
  var rule = level <= 5 ? 2 : (level <= 12 ? 1 : 0);
  if (rule == 0) {
    final opts = n >= 5 ? [1, 2, 3] : [1, 2];
    rule = opts[rnd.nextInt(opts.length)];
  }
  final names = [..._namePool]..shuffle(rnd);
  final people = names.take(n).toList();
  final scene = _scenes[rnd.nextInt(_scenes.length)];
  final basic = level <= 5;

  Statement randomStatement() {
    final kind = basic ? rnd.nextInt(2) : rnd.nextInt(4);
    if (kind == 0) return Statement(StType.accuse, rnd.nextInt(n));
    if (kind == 1) return Statement(StType.deny, rnd.nextInt(n));
    final a = rnd.nextInt(n);
    var b = rnd.nextInt(n - 1);
    if (b >= a) b++;
    return Statement(kind == 2 ? StType.either : StType.neither, a, b);
  }

  for (var attempt = 0; attempt < 200000; attempt++) {
    final st = [for (var i = 0; i < n; i++) randomStatement()];
    final sol = solutions(rule, st, n);
    if (sol.length == 1) {
      return DetectiveCase(scene.$1, scene.$2, people, st, rule, sol.first);
    }
  }
  // Cadangan yang pasti valid: kasus 3 orang paling sederhana.
  final st = [
    const Statement(StType.accuse, 1),
    const Statement(StType.accuse, 2),
    const Statement(StType.deny, 2),
  ];
  return DetectiveCase(
      scene.$1, scene.$2, people.take(3).toList(), st, 1, solutions(1, st, 3).first);
}
