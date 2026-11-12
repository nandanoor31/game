import 'package:flutter/material.dart';

import '../games/shadow.dart';
import '../progress.dart';
import '../theme.dart';
import 'common.dart';
import 'detective_screen.dart';
import 'rule_screen.dart';
import 'scales_screen.dart';
import 'shadow_screen.dart';

Widget screenFor(Mode m, int level) => switch (m) {
      Mode.rule => RuleScreen(level: level),
      Mode.detective => DetectiveScreen(level: level),
      Mode.scales => ScalesScreen(level: level),
      Mode.shadow => ShadowScreen(level: level),
    };

/// Pindah ke level berikutnya (mengganti layar saat ini), atau kembali ke menu.
void goNext(BuildContext context, Mode m, int level) {
  if (level >= infoOf(m).levels) {
    Navigator.of(context).pop();
    return;
  }
  Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screenFor(m, level + 1)));
}

class LevelSelectScreen extends StatefulWidget {
  final Mode mode;
  const LevelSelectScreen({super.key, required this.mode});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  Future<void> _play(int level) async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => screenFor(widget.mode, level)));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final info = infoOf(widget.mode);
    return Scaffold(
      backgroundColor: kBg,
      body: GameBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: kText),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Icon(info.icon, color: info.color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(info.title,
                          style: const TextStyle(
                              color: kText,
                              fontSize: 22,
                              fontWeight: FontWeight.w800)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.help_outline_rounded, color: kSoft),
                      onPressed: () => showHelp(context, widget.mode),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.count(
                  padding: const EdgeInsets.all(16),
                  crossAxisCount: 4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.88,
                  children: [
                    for (var i = 1; i <= info.levels; i++) _tile(info, i),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(ModeInfo info, int level) {
    final open = Progress.unlocked(info.key, level);
    final stars = Progress.stars(info.key, level);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: open ? () => _play(level) : null,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: open ? info.color.withValues(alpha: 0.18) : kCard.withValues(alpha: 0.5),
            border: Border.all(
                color: open
                    ? info.color.withValues(alpha: stars > 0 ? 0.8 : 0.35)
                    : Colors.transparent),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (open) ...[
                Text('$level',
                    style: const TextStyle(
                        color: kText, fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                StarsRow(stars, size: 14),
                if (widget.mode == Mode.shadow)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(kShadowLevels[level - 1].name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: kSoft, fontSize: 10)),
                  ),
              ] else
                Icon(Icons.lock_rounded, color: kSoft.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}
