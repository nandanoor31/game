import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalar/games/rule_machine.dart';
import 'package:nalar/progress.dart';
import 'package:nalar/theme.dart';
import 'package:nalar/ui/home_screen.dart';
import 'package:nalar/ui/level_select.dart';
import 'package:nalar/ui/update_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Progress.init();
  });

  Future<void> phone(WidgetTester t) async {
    t.view.physicalSize = const Size(1080, 2340);
    t.view.devicePixelRatio = 2.75;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
  }

  testWidgets('Menu utama dan daftar level tampil tanpa error', (t) async {
    await phone(t);
    await t.pumpWidget(const MaterialApp(home: HomeScreen()));
    expect(find.text('Nalar'), findsOneWidget);
    for (final m in kModes) {
      expect(find.text(m.title), findsOneWidget);
    }
    for (final m in kModes) {
      await t.pumpWidget(MaterialApp(home: LevelSelectScreen(mode: m.mode)));
      await t.pump();
      expect(t.takeException(), isNull, reason: m.title);
    }
  });

  testWidgets('Semua layar permainan tampil tanpa error', (t) async {
    await phone(t);
    for (final m in kModes) {
      final levels = <int>[1, m.levels ~/ 2 == 0 ? 1 : m.levels ~/ 2, m.levels];
      for (final l in levels) {
        await t.pumpWidget(MaterialApp(home: screenFor(m.mode, l)));
        await t.pump();
        expect(t.takeException(), isNull, reason: '${m.title} level $l');
      }
    }
  });

  testWidgets('Mesin Aturan: memilih jawaban benar menampilkan hasil', (t) async {
    await phone(t);
    await t.pumpWidget(MaterialApp(home: screenFor(Mode.rule, 1)));
    final p = makeRulePuzzle(1);
    await t.tap(find.text('${p.answer}').last);
    await t.pumpAndSettle();
    expect(find.text('Benar!'), findsOneWidget);
    expect(Progress.stars('rule', 1), 3);
  });

  testWidgets('Halaman Pembaruan tampil tanpa error', (t) async {
    await phone(t);
    await t.pumpWidget(const MaterialApp(home: UpdateScreen()));
    await t.pump();
    expect(find.text('Pembaruan'), findsOneWidget);
    expect(find.text('Periksa pembaruan'), findsOneWidget);
    expect(t.takeException(), isNull);
  });}

