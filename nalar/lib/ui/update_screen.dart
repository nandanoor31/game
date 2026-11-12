import 'package:flutter/material.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

import '../update/updater.dart';
import '../theme.dart';

/// Halaman Pembaruan: patch kecil (Shorebird) dan APK penuh.
class UpdateScreen extends StatefulWidget {
  const UpdateScreen({super.key});
  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  final _u = Updater();
  String version = '...';
  String patchInfo = '';
  String patchMsg = 'Belum diperiksa.';
  String fullMsg = 'Belum diperiksa.';
  bool busy = false;
  bool patchReady = false; // ada patch yang bisa diunduh
  bool patchDone = false; // patch sudah diunduh, tinggal buka ulang
  FullUpdate? full;
  double? progress;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    final i = await _u.info();
    final p = await _u.currentPatch();
    if (!mounted) return;
    setState(() {
      version = 'Versi ${i.version} (build ${i.buildNumber})';
      patchInfo = p == null ? '' : 'Patch terpasang: $p';
    });
  }

  Future<void> _check() async {
    setState(() {
      busy = true;
      patchReady = false;
      full = null;
      patchMsg = 'Memeriksa...';
      fullMsg = 'Memeriksa...';
    });
    // Patch kecil.
    try {
      if (!_u.patchSupported) {
        patchMsg = 'Tidak aktif di versi ini. Aktif di APK yang dibuat dengan Shorebird.';
      } else {
        final s = await _u.checkPatch();
        switch (s) {
          case UpdateStatus.outdated:
            patchMsg = 'Ada patch kecil baru.';
            patchReady = true;
          case UpdateStatus.restartRequired:
            patchMsg = 'Patch sudah diunduh. Tutup aplikasi lalu buka lagi.';
            patchDone = true;
          case UpdateStatus.upToDate:
            patchMsg = 'Sudah yang terbaru.';
          case UpdateStatus.unavailable:
            patchMsg = 'Tidak tersedia saat ini.';
        }
      }
    } catch (e) {
      patchMsg = 'Gagal memeriksa. Cek sambungan internet.';
    }
    // APK penuh.
    try {
      if (!_u.fullConfigured) {
        fullMsg = 'Alamat pembaruan belum diatur.';
      } else {
        full = await _u.checkFull();
        fullMsg = full == null
            ? 'Sudah yang terbaru.'
            : 'Ada versi baru ${full!.name}.'
                '${full!.notes.isEmpty ? '' : '\n${full!.notes}'}';
      }
    } catch (e) {
      fullMsg = 'Gagal memeriksa. Cek sambungan internet.';
    }
    if (!mounted) return;
    setState(() => busy = false);
  }

  Future<void> _downloadPatch() async {
    setState(() {
      busy = true;
      patchMsg = 'Mengunduh patch...';
    });
    try {
      await _u.downloadPatch();
      patchMsg = 'Patch sudah diunduh. Tutup aplikasi lalu buka lagi.';
      patchReady = false;
      patchDone = true;
    } catch (e) {
      patchMsg = 'Gagal mengunduh patch. Coba lagi.';
    }
    if (!mounted) return;
    setState(() => busy = false);
  }

  Future<void> _installFull() async {
    final f = full;
    if (f == null) return;
    setState(() {
      busy = true;
      progress = 0;
      fullMsg = 'Mengunduh versi ${f.name}...';
    });
    try {
      await _u.downloadAndInstall(f, (p) {
        if (mounted) setState(() => progress = p);
      });
      fullMsg = 'Pemasang Android sudah dibuka. Ikuti petunjuknya, '
          'lalu pilih Perbarui.';
    } catch (e) {
      fullMsg = 'Gagal mengunduh atau membuka pemasang. Coba lagi.';
    }
    if (!mounted) return;
    setState(() {
      busy = false;
      progress = null;
    });
  }

  Widget _card(String title, String msg, {List<Widget> extra = const []}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: kCard, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                color: kText, fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(msg, style: const TextStyle(color: kSoft, fontSize: 15)),
        ...extra,
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        foregroundColor: kText,
        title: const Text('Pembaruan'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(version, style: const TextStyle(color: kText, fontSize: 16)),
          if (patchInfo.isNotEmpty)
            Text(patchInfo,
                style: const TextStyle(color: kSoft, fontSize: 14)),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: busy ? null : _check,
            child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Periksa pembaruan')),
          ),
          const SizedBox(height: 16),
          _card('Pembaruan kecil (patch)', patchMsg, extra: [
            if (patchReady && !busy) ...[
              const SizedBox(height: 10),
              FilledButton.tonal(
                  onPressed: _downloadPatch, child: const Text('Unduh patch')),
            ],
          ]),
          const SizedBox(height: 12),
          _card('Pembaruan penuh (APK)', fullMsg, extra: [
            if (progress != null) ...[
              const SizedBox(height: 10),
              LinearProgressIndicator(value: progress),
            ],
            if (full != null && !busy) ...[
              const SizedBox(height: 10),
              FilledButton.tonal(
                  onPressed: _installFull,
                  child: const Text('Unduh dan pasang')),
            ],
          ]),
          const SizedBox(height: 16),
          const Text(
            'Patch kecil mengganti isi permainan tanpa memasang ulang. '
            'Pembaruan penuh dipakai bila ada perubahan besar.',
            style: TextStyle(color: kSoft, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

