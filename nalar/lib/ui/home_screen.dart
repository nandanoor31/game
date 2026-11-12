import 'package:flutter/material.dart';

import '../logo.dart';
import '../progress.dart';
import '../theme.dart';
import 'update_screen.dart';
import 'level_select.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _open(Mode m) async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => LevelSelectScreen(mode: m)));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: GameBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: 'Pembaruan',
                  icon: const Icon(Icons.system_update_rounded, color: kSoft),
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const UpdateScreen())),
                ),
              ),
              const Center(
                child: SizedBox(
                  width: 96,
                  height: 96,
                  child: CustomPaint(painter: LogoPainter()),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Nalar',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: kText,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5)),
              const SizedBox(height: 4),
              const Text('Asah pikiranmu, satu teka-teki demi satu',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kSoft, fontSize: 15)),
              const SizedBox(height: 26),
              for (final m in kModes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _ModeCard(info: m, onTap: () => _open(m.mode)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final ModeInfo info;
  final VoidCallback onTap;
  const _ModeCard({required this.info, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final got = Progress.totalStars(info.key, info.levels);
    final all = info.levels * 3;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [info.color.withValues(alpha: 0.28), kCard],
            ),
            border: Border.all(color: info.color.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: info.color.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: Icon(info.icon, color: info.color, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(info.title,
                        style: const TextStyle(
                            color: kText,
                            fontSize: 19,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(info.subtitle,
                        style: const TextStyle(color: kSoft, fontSize: 13.5)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: kGold, size: 16),
                        const SizedBox(width: 3),
                        Text('$got / $all',
                            style: const TextStyle(
                                color: kGold,
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: info.color),
            ],
          ),
        ),
      ),
    );
  }
}



