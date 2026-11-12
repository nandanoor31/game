import 'package:flutter/material.dart';

import '../game/custom.dart';
import '../game/modes.dart';
import '../game/progress.dart';
import 'editor_screen.dart';
import 'game_screen.dart';
import 'theme.dart';

/// Daftar level buatan sendiri: main, ubah, hapus, atau buat baru.
class CustomListScreen extends StatefulWidget {
  const CustomListScreen({super.key});

  @override
  State<CustomListScreen> createState() => _CustomListScreenState();
}

class _CustomListScreenState extends State<CustomListScreen> {
  final col = modeColor(Mode.buatan);

  List<CustomDef?> get _defs =>
      Progress.instance.customs().map(CustomDef.decode).toList();

  void _snack(String t) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(t), duration: const Duration(seconds: 3)));
  }

  Future<void> _edit(int? slot) async {
    final d = slot == null ? null : _defs[slot];
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => EditorScreen(initial: d, slot: slot)));
    if (mounted) setState(() {});
  }

  Future<void> _play(int slot) async {
    final d = _defs[slot];
    if (d == null) return;
    final chk = checkCustom(d);
    if (!chk.ok) {
      _snack(chk.message);
      return;
    }
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => GameScreen(
            mode: Mode.buatan,
            index: slot + 1,
            preset: levelOfCustom(d, par: chk.par, number: slot + 1))));
    if (mounted) setState(() {});
  }

  Future<void> _delete(int slot) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kPanel,
        title: const Text('Hapus level ini?', style: TextStyle(color: kInk)),
        content: const Text('Level yang dihapus tidak bisa dikembalikan.',
            style: TextStyle(color: kMuted)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hapus')),
        ],
      ),
    );
    if (ok != true) return;
    final list = Progress.instance.customs()..removeAt(slot);
    Progress.instance.saveCustoms(list);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final defs = _defs;
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
                  Text(Mode.buatan.title,
                      style: TextStyle(
                          color: col,
                          fontSize: 22,
                          fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            Expanded(
              child: defs.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                            'Belum ada level buatan.\nTekan "Buat level baru" untuk mulai.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: kMuted, fontSize: 16)),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      itemCount: defs.length,
                      separatorBuilder: (context, i) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final d = defs[i];
                        return Container(
                          padding: const EdgeInsets.fromLTRB(16, 10, 6, 10),
                          decoration: BoxDecoration(
                              color: kPanel,
                              borderRadius: BorderRadius.circular(18)),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(d?.name ?? 'Rusak',
                                        style: const TextStyle(
                                            color: kInk,
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800)),
                                    Text(
                                        d == null
                                            ? 'Data tidak terbaca'
                                            : 'Papan ${d.w} x ${d.h}',
                                        style: const TextStyle(
                                            color: kMuted, fontSize: 13)),
                                  ],
                                ),
                              ),
                              if (d != null) ...[
                                IconButton(
                                    onPressed: () => _play(i),
                                    tooltip: 'Mainkan',
                                    icon: const Icon(Icons.play_arrow_rounded),
                                    color: col),
                                IconButton(
                                    onPressed: () => _edit(i),
                                    tooltip: 'Ubah',
                                    icon: const Icon(Icons.edit_outlined),
                                    color: kInk),
                              ],
                              IconButton(
                                  onPressed: () => _delete(i),
                                  tooltip: 'Hapus',
                                  icon: const Icon(Icons.delete_outline),
                                  color: kMuted),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: FilledButton(
                onPressed: () => _edit(null),
                style: FilledButton.styleFrom(
                    backgroundColor: col,
                    foregroundColor: const Color(0xFF1A1230),
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16))),
                child: const Text('Buat level baru',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
