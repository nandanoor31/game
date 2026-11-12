import 'package:flutter/material.dart';

import '../theme.dart';

class StarsRow extends StatelessWidget {
  final int stars;
  final double size;
  const StarsRow(this.stars, {super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Icon(
            i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: i < stars ? kGold : kSoft.withValues(alpha: 0.4),
          ),
      ],
    );
  }
}

/// Kerangka layar permainan: tombol kembali, judul, tombol bantuan.
class GameScaffold extends StatelessWidget {
  final Mode mode;
  final String title;
  final Widget body;
  const GameScaffold(
      {super.key, required this.mode, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final info = infoOf(mode);
    return Scaffold(
      backgroundColor: kBg,
      body: GameBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: kText),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(info.title,
                              style: TextStyle(
                                  color: info.color,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700)),
                          Text(title,
                              style: const TextStyle(
                                  color: kText,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.help_outline_rounded, color: kSoft),
                      onPressed: () => showHelp(context, mode),
                    ),
                  ],
                ),
              ),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showHelp(BuildContext context, Mode mode) {
  final info = infoOf(mode);
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: kCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text('Cara main: ${info.title}',
          style: const TextStyle(color: kText, fontWeight: FontWeight.w800)),
      content: Text(info.how,
          style: const TextStyle(color: kSoft, fontSize: 15, height: 1.4)),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('Mengerti')),
      ],
    ),
  );
}

/// Kotak hasil di akhir level. [onNext] kosong berarti tidak ada tombol Lanjut.
Future<void> showResult(
  BuildContext context, {
  required bool success,
  required String title,
  required String message,
  required Color color,
  int stars = 0,
  VoidCallback? onNext,
  required VoidCallback onRetry,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Dialog(
      backgroundColor: kCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 14),
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.75),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(success ? Icons.emoji_events_rounded : Icons.refresh_rounded,
                  color: success ? kGold : kBad, size: 44),
              const SizedBox(height: 8),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: kText, fontSize: 22, fontWeight: FontWeight.w800)),
              if (success) ...[
                const SizedBox(height: 8),
                StarsRow(stars, size: 34),
              ],
              const SizedBox(height: 10),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: kSoft, fontSize: 15, height: 1.4)),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.of(context).pop();
                      },
                      child: const Text('Menu'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        onRetry();
                      },
                      child: const Text('Ulangi'),
                    ),
                  ),
                  if (success && onNext != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: color,
                            foregroundColor: kBg),
                        onPressed: () {
                          Navigator.pop(ctx);
                          onNext();
                        },
                        child: const Text('Lanjut'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void snack(BuildContext context, String text, {Color? color}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(text, style: const TextStyle(color: kText)),
      backgroundColor: color ?? kCardHi,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(milliseconds: 1600),
    ));
}
