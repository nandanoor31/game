import 'package:flutter/material.dart';

import '../game/generator.dart';
import '../game/modes.dart';
import '../game/progress.dart';
import 'game_screen.dart';
import 'theme.dart';

/// Daftar level untuk mode berurutan: lingkaran bernomor dengan bintang.
class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key, required this.mode});
  final Mode mode;

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  Mode get mode => widget.mode;

  Future<void> _play(int n) async {
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => GameScreen(mode: mode, index: n)));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final pr = Progress.instance;
    final unlocked = pr.unlocked(mode);
    final total = mode == Mode.bentuk ? bentukCount : unlocked + 11;
    final col = modeColor(mode);
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    tooltip: 'Kembali',
                    icon: const Icon(Icons.arrow_back),
                    color: kInk,
                  ),
                  Text(mode.title,
                      style: TextStyle(
                          color: col,
                          fontSize: 22,
                          fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                ),
                itemCount: total,
                itemBuilder: (context, i) {
                  final n = i + 1;
                  final locked = n > unlocked;
                  final st = pr.stars(mode, n);
                  return Material(
                    color: locked ? kPanel.withValues(alpha: .5) : kPanel,
                    shape: CircleBorder(
                        side: BorderSide(
                            color: st == 3
                                ? col
                                : (locked ? Colors.transparent : kRim),
                            width: 2)),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: locked ? null : () => _play(n),
                      child: Center(
                        child: locked
                            ? const Icon(Icons.lock_outline,
                                color: kMuted, size: 20)
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('$n',
                                      style: const TextStyle(
                                          color: kInk,
                                          fontSize: 19,
                                          fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 2),
                                  starRow(st, size: 12),
                                ],
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
