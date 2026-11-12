import 'package:flutter/material.dart';

const kBg = Color(0xFF0D0F2B);
const kBg2 = Color(0xFF1B1C4F);
const kCard = Color(0xFF252866);
const kCardHi = Color(0xFF30347F);
const kGold = Color(0xFFFFC857);
const kText = Color(0xFFF3F3FF);
const kSoft = Color(0xFFA9ADE6);
const kGood = Color(0xFF5BE3A1);
const kBad = Color(0xFFFF6B7A);

enum Mode { rule, detective, scales, shadow }

class ModeInfo {
  final Mode mode;
  final String key;
  final String title;
  final String subtitle;
  final String how;
  final Color color;
  final IconData icon;
  final int levels;
  const ModeInfo(this.mode, this.key, this.title, this.subtitle, this.how,
      this.color, this.icon, this.levels);
}

const kModes = <ModeInfo>[
  ModeInfo(
    Mode.rule,
    'rule',
    'Mesin Aturan',
    'Tebak aturan rahasia',
    'Sebuah mesin mengubah angka memakai SATU aturan rahasia. '
        'Perhatikan contoh masuk dan keluarnya, temukan aturannya, '
        'lalu pilih hasil untuk angka yang baru. '
        'Kamu punya 3 nyawa. Tombol "Contoh tambahan" membantu, tetapi mengurangi bintang.',
    Color(0xFF3DDBC0),
    Icons.settings_suggest_rounded,
    30,
  ),
  ModeInfo(
    Mode.detective,
    'detective',
    'Detektif Kilat',
    'Temukan siapa yang berbohong',
    'Tiap orang mengucapkan satu pernyataan. Ada satu pelaku. '
        'Aturan kasus (tertulis di atas) memberitahu siapa yang boleh berbohong. '
        'Sentuh sebuah pernyataan untuk menandainya: benar, bohong, atau kosong. '
        'Lalu pilih pelakunya. Setiap tuduhan yang salah mengurangi bintang.',
    Color(0xFFFF7A7A),
    Icons.search_rounded,
    30,
  ),
  ModeInfo(
    Mode.scales,
    'scales',
    'Timbangan Ajaib',
    'Cari koin palsu',
    'Salah satu koin itu palsu. Sentuh koin untuk memindahkannya: meja, '
        'lalu timbangan kiri, lalu timbangan kanan. Kedua sisi harus berisi '
        'jumlah koin yang sama. Jumlah timbang terbatas, jadi rencanakan dulu. '
        'Setelah yakin, tekan "Tebak koin palsu". Menebak asal-asalan hanya mendapat 1 bintang.',
    Color(0xFFFFC857),
    Icons.balance_rounded,
    9,
  ),
  ModeInfo(
    Mode.shadow,
    'shadow',
    'Bayangan Diri',
    'Bekerja sama dengan dirimu',
    'Setiap putaran, semua gerakanmu direkam. Di putaran berikutnya rekaman itu '
        'muncul sebagai bayangan yang bergerak persis sama. Tombol di lantai '
        'membuka pintu yang warnanya sama selama ada yang menginjaknya. '
        'Di putaran terakhir, capai bendera. Geser jarimu di papan atau pakai tombol arah. '
        'Tombol "Tunggu" membuat waktu berjalan satu langkah tanpa bergerak.',
    Color(0xFFB28CFF),
    Icons.blur_on_rounded,
    6,
  ),
];

ModeInfo infoOf(Mode m) => kModes.firstWhere((e) => e.mode == m);

class GameBackground extends StatelessWidget {
  final Widget child;
  const GameBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [kBg2, kBg],
        ),
      ),
      child: child,
    );
  }
}
