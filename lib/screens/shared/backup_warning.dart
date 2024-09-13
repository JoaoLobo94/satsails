import 'package:Satsails/providers/settings_provider.dart';
import 'package:Satsails/translations/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BackupWarning extends ConsumerWidget {
  const BackupWarning({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenSize = MediaQuery.of(context).size;
    final backupWarning = ref.watch(settingsProvider).backup;

    final dynamicFontSize = screenSize.width * 0.04;

    return !backupWarning
        ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.warning,
              color: Colors.red,
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/seed_words');
              },
              child: Text(
                'Backup your wallet'.i18n(ref),
                style: TextStyle(
                  color: Colors.red,
                  fontSize: dynamicFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        )
        : Container();
  }
}
