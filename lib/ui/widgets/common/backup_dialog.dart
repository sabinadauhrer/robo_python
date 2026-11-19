import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/backup_code.dart';
import '../../../state/providers.dart';
import '../../theme.dart';

/// Knopf in der Kopfzeile: Spielstand sichern oder wiederherstellen.
class BackupButton extends StatelessWidget {
  const BackupButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Spielstand sichern',
    icon: const Icon(Icons.save_rounded),
    onPressed: () => showDialog<void>(context: context, builder: (_) => const BackupDialog()),
  );
}

class BackupDialog extends ConsumerStatefulWidget {
  const BackupDialog({super.key});

  @override
  ConsumerState<BackupDialog> createState() => _BackupDialogState();
}

class _BackupDialogState extends ConsumerState<BackupDialog> {
  final _input = TextEditingController();
  String? _message;
  bool _ok = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _copy(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    setState(() {
      _ok = true;
      _message = 'Kopiert! Füge den Code z. B. in deine Notizen ein oder schick ihn dir selbst.';
    });
  }

  void _restore() {
    final profile = BackupCode.decode(_input.text);
    if (profile == null) {
      setState(() {
        _ok = false;
        _message = 'Dieser Code passt nicht. Er beginnt mit ROBO1- – kopiere ihn bitte komplett.';
      });
      return;
    }
    ref.read(profileProvider.notifier).restore(profile);
    setState(() {
      _ok = true;
      _message = 'Geschafft! Dein Spielstand ist wieder da: ${profile.lessonStars.length} Inseln, ${profile.totalStars} Sterne.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ref.watch(profileProvider);
    final code = BackupCode.encode(profile);
    return AlertDialog(
      title: const Text('Spielstand sichern'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dein Fortschritt wird nur in diesem Browser gespeichert. Mit diesem Code kannst du ihn sichern '
                'und auf jedem Gerät wiederherstellen – auch nach dem Löschen der Browserdaten.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: SelectableText(code, key: const Key('backup-code'), maxLines: 4,
                    style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12)),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                key: const Key('copy-code'),
                onPressed: () => _copy(code),
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Code kopieren'),
              ),
              const Divider(height: 32),
              Text('Spielstand wiederherstellen', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                key: const Key('restore-input'),
                controller: _input,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(hintText: 'Code hier einfügen (ROBO1-…)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const Key('restore'),
                onPressed: _restore,
                icon: const Icon(Icons.restore_rounded),
                label: const Text('Wiederherstellen'),
              ),
              if (_message != null) ...[
                const SizedBox(height: 12),
                Text(_message!, style: theme.textTheme.bodyMedium?.copyWith(color: _ok ? AppColors.mintDeep : AppColors.error)),
              ],
            ],
          ),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fertig'))],
    );
  }
}
