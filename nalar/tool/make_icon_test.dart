// Membuat ikon aplikasi Nalar dari kode (tanpa alat gambar).
// Jalankan: flutter test tool/make_icon_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:nalar/logo.dart';

Future<void> _save(int size, String path) async {
  final rec = ui.PictureRecorder();
  final canvas = ui.Canvas(rec);
  paintLogo(canvas, size.toDouble());
  final img = await rec.endRecording().toImage(size, size);
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  File(path).writeAsBytesSync(data!.buffer.asUint8List());
}

void main() {
  testWidgets('buat ikon', (tester) async {
    await tester.runAsync(() async {
      const res = 'android/app/src/main/res';
      const sizes = {
        'mdpi': 48,
        'hdpi': 72,
        'xhdpi': 96,
        'xxhdpi': 144,
        'xxxhdpi': 192,
      };
      for (final e in sizes.entries) {
        await _save(e.value, '$res/mipmap-${e.key}/ic_launcher.png');
      }
      await _save(512, 'icon_preview.png');
    });
  });
}
