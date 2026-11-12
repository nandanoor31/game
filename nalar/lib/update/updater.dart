import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

/// Alamat berkas update.json untuk pembaruan APK penuh. Berisi, misalnya:
/// {"build": 3, "name": "0.3.0", "url": "https://.../app-release.apk",
///  "catatan": "Perbaikan petunjuk"}
/// Kosong = fitur APK penuh belum diatur. Nilai ini ada di kode Dart,
/// jadi bisa diganti lewat patch Shorebird tanpa APK baru.
const String kUpdateJsonUrl =
    'https://github.com/nandanoor31/game/releases/download/nalar/update.json';

class FullUpdate {
  FullUpdate(this.build, this.name, this.url, this.notes);
  final int build;
  final String name;
  final String url;
  final String notes;
}

class Updater {
  final ShorebirdUpdater _sb = ShorebirdUpdater();

  bool get patchSupported => _sb.isAvailable;
  bool get fullConfigured => kUpdateJsonUrl.isNotEmpty;

  Future<PackageInfo> info() => PackageInfo.fromPlatform();

  Future<int?> currentPatch() async {
    if (!_sb.isAvailable) return null;
    return (await _sb.readCurrentPatch())?.number;
  }

  /// Cek patch kecil (kode Dart) lewat Shorebird.
  Future<UpdateStatus> checkPatch() => _sb.checkForUpdate();

  /// Unduh patch; baru berlaku setelah aplikasi ditutup lalu dibuka lagi.
  Future<void> downloadPatch() => _sb.update();

  /// Cek apakah ada APK penuh yang lebih baru; null bila tidak ada.
  Future<FullUpdate?> checkFull() async {
    if (!fullConfigured) return null;
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 12);
    try {
      final req = await client.getUrl(Uri.parse(kUpdateJsonUrl));
      final res = await req.close().timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        throw HttpException('Server menjawab ${res.statusCode}');
      }
      final text = await res.transform(utf8.decoder).join();
      final m = jsonDecode(text) as Map<String, dynamic>;
      final build = (m['build'] as num).toInt();
      final now = int.tryParse((await info()).buildNumber) ?? 0;
      if (build <= now) return null;
      return FullUpdate(build, '${m['name'] ?? build}', '${m['url']}',
          '${m['catatan'] ?? ''}');
    } finally {
      client.close(force: true);
    }
  }

  /// Unduh APK penuh lalu buka pemasang Android.
  Future<void> downloadAndInstall(
      FullUpdate u, void Function(double) onProgress) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/nalar-update.apk');
    if (await file.exists()) await file.delete();
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final req = await client.getUrl(Uri.parse(u.url));
      final res = await req.close();
      if (res.statusCode != 200) {
        throw HttpException('Server menjawab ${res.statusCode}');
      }
      final total = res.contentLength;
      var got = 0;
      final sink = file.openWrite();
      try {
        await for (final chunk in res) {
          sink.add(chunk);
          got += chunk.length;
          if (total > 0) onProgress(got / total);
        }
      } finally {
        await sink.close();
      }
    } finally {
      client.close(force: true);
    }
    final r = await OpenFilex.open(file.path,
        type: 'application/vnd.android.package-archive');
    if (r.type != ResultType.done) {
      throw Exception(r.message);
    }
  }
}

