import 'dart:math';

import 'package:flutter/material.dart';

import '../games/detective.dart';
import '../progress.dart';
import '../theme.dart';
import 'common.dart';
import 'level_select.dart';

const _avatarColors = [
  Color(0xFFFF8FA3), Color(0xFF6EC1FF), Color(0xFFFFB86B),
  Color(0xFF8CE99A), Color(0xFFC4A1FF), Color(0xFFFFE066),
];

class DetectiveScreen extends StatefulWidget {
  final int level;
  const DetectiveScreen({super.key, required this.level});

  @override
  State<DetectiveScreen> createState() => _DetectiveScreenState();
}

class _DetectiveScreenState extends State<DetectiveScreen> {
  static const _mode = Mode.detective;
  late DetectiveCase c;
  late List<int> marks; // 0 kosong, 1 benar, 2 bohong
  final Set<int> eliminated = {};
  int? selected;
  int wrongs = 0;
  int variant = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    c = makeCase(widget.level, variant: variant);
    marks = List.filled(c.names.length, 0);
    eliminated.clear();
    selected = null;
    wrongs = 0;
  }

  void _accuse() {
    final s = selected;
    if (s == null) return;
    final info = infoOf(_mode);
    if (s == c.culprit) {
      final stars = max(1, 3 - wrongs);
      Progress.setStars(info.key, widget.level, stars);
      showResult(
        context,
        success: true,
        title: '${c.names[s]} pelakunya!',
        stars: stars,
        color: info.color,
        message: 'Aturan: ${c.ruleText}\n\n${c.explain().join("\n")}',
        onNext: widget.level < info.levels
            ? () => goNext(context, _mode, widget.level)
            : null,
        onRetry: () => setState(_load),
      );
    } else {
      setState(() {
        wrongs++;
        eliminated.add(s);
        selected = null;
      });
      snack(context, 'Bukan ${c.names[s]}. Periksa lagi pernyataannya.',
          color: kBad.withValues(alpha: 0.8));
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = infoOf(_mode);
    return GameScaffold(
      mode: _mode,
      title: 'Kasus ${widget.level}',
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: info.color.withValues(alpha: 0.35)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.title,
                          style: const TextStyle(
                              color: kText, fontSize: 19, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(c.question,
                          style: const TextStyle(color: kSoft, fontSize: 14.5)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: info.color.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.rule_rounded, color: info.color, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(c.ruleText,
                                  style: TextStyle(
                                      color: info.color,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text('Sentuh pernyataan untuk menandai: benar / bohong',
                    style: TextStyle(color: kSoft, fontSize: 12.5)),
                const SizedBox(height: 6),
                for (var i = 0; i < c.names.length; i++) _suspect(i),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            decoration: BoxDecoration(
              color: kBg.withValues(alpha: 0.8),
              border: Border(top: BorderSide(color: kCardHi.withValues(alpha: 0.6))),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Siapa pelakunya?',
                    style: TextStyle(color: kText, fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    for (var i = 0; i < c.names.length; i++)
                      ChoiceChip(
                        label: Text(c.names[i]),
                        selected: selected == i,
                        selectedColor: info.color.withValues(alpha: 0.45),
                        backgroundColor: kCard,
                        disabledColor: kCard.withValues(alpha: 0.4),
                        labelStyle: TextStyle(
                            color: eliminated.contains(i) ? kSoft.withValues(alpha: 0.4) : kText,
                            decoration: eliminated.contains(i)
                                ? TextDecoration.lineThrough
                                : null),
                        onSelected: eliminated.contains(i)
                            ? null
                            : (_) => setState(() => selected = i),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: info.color, foregroundColor: kBg),
                    onPressed: selected == null ? null : _accuse,
                    child: Text(selected == null
                        ? 'Pilih satu orang'
                        : 'Tuduh ${c.names[selected!]}'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _suspect(int i) {
    final color = _avatarColors[i % _avatarColors.length];
    final m = marks[i];
    final out = eliminated.contains(i);
    final markColor = m == 1 ? kGood : (m == 2 ? kBad : kSoft.withValues(alpha: 0.5));
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Opacity(
        opacity: out ? 0.45 : 1,
        child: Material(
          color: kCard,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => setState(() => marks[i] = (marks[i] + 1) % 3),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: m == 0 ? Colors.transparent : markColor.withValues(alpha: 0.7)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color,
                    radius: 22,
                    child: Text(c.names[i][0],
                        style: const TextStyle(
                            color: kBg, fontWeight: FontWeight.w900, fontSize: 20)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.names[i],
                            style: TextStyle(
                                color: color, fontWeight: FontWeight.w800, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text('"${c.say(i)}"',
                            style: const TextStyle(color: kText, fontSize: 16, height: 1.25)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                          m == 1
                              ? Icons.check_circle_rounded
                              : (m == 2 ? Icons.cancel_rounded : Icons.help_outline_rounded),
                          color: markColor,
                          size: 28),
                      Text(m == 1 ? 'benar' : (m == 2 ? 'bohong' : 'tandai'),
                          style: TextStyle(color: markColor, fontSize: 10.5)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
