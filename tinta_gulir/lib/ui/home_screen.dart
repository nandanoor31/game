import 'package:flutter/material.dart';

import '../game/generator.dart';
import '../game/modes.dart';
import '../game/progress.dart';
import 'custom_list.dart';
import 'game_screen.dart';
import 'level_select.dart';
import 'update_screen.dart';
import 'theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Progress get _pr => Progress.instance;

  Future<void> _open(Mode m) async {
    final Widget page;
    switch (m) {
      case Mode.harian:
        final now = DateTime.now();
        page = GameScreen(
            mode: Mode.harian,
            index: dailyKey(now),
            preset: dailyLevel(now));
      case Mode.buatan:
        page = const CustomListScreen();
      default:
        page = LevelSelectScreen(mode: m);
    }
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    if (mounted) setState(() {});
  }

  String _status(Mode m) {
    switch (m) {
      case Mode.jelajah:
      case Mode.tantangan:
        return 'Terbuka sampai level ${_pr.unlocked(m)}';
      case Mode.bentuk:
        var done = 0;
        for (var n = 1; n <= bentukCount; n++) {
          if (_pr.stars(Mode.bentuk, n) > 0) done++;
        }
        return '$done dari $bentukCount selesai';
      case Mode.harian:
        final key = dailyKey(DateTime.now());
        return _pr.stars(Mode.harian, key) > 0
            ? 'Hari ini selesai'
            : 'Level baru hari ini';
      case Mode.buatan:
        return '${_pr.customs().length} level buatan';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
          children: [
            const Text.rich(
              TextSpan(children: [
                TextSpan(text: 'TINTA '),
                TextSpan(text: 'GULIR', style: TextStyle(color: Color(0xFF4CC9F0))),
              ]),
              style: TextStyle(
                  color: kInk,
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2),
            ),
            const SizedBox(height: 6),
            Row(children: [
              const Expanded(
                child: Text('Geser, gulirkan, warnai.',
                    style: TextStyle(color: kMuted, fontSize: 16)),
              ),
              IconButton(
                tooltip: 'Pembaruan',
                icon: const Icon(Icons.system_update, color: kMuted),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const UpdateScreen())),
              ),
            ]),
            const SizedBox(height: 28),
            for (final m in Mode.values) ...[
              _card(m),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  Widget _card(Mode m) {
    final col = modeColor(m);
    return Material(
      color: kPanel,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _open(m),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                    color: col.withValues(alpha: .18), shape: BoxShape.circle),
                child: Icon(modeIcon(m), color: col, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.title,
                        style: const TextStyle(
                            color: kInk,
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(m.blurb,
                        style: const TextStyle(color: kMuted, fontSize: 13.5)),
                    const SizedBox(height: 4),
                    Text(_status(m),
                        style: TextStyle(
                            color: col,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: kMuted),
            ],
          ),
        ),
      ),
    );
  }
}
