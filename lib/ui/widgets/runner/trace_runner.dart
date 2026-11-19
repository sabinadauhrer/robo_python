import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../audio/sfx.dart';
import '../../../audio/sound_player.dart';
import '../../../python/interpreter.dart';
import '../../theme.dart';
import '../kawaii/kawaii_robot.dart';
import '../lesson/code_view.dart';
import 'variable_box.dart';

/// Probelauf: spielt Python-Code Schritt für Schritt ab und erklärt jeden Schritt.
class TraceRunner extends ConsumerStatefulWidget {
  const TraceRunner({super.key, required this.code, this.inputs = const [], this.files = const {}});

  final String code;
  final List<String> inputs;
  final Map<String, String> files;

  @override
  ConsumerState<TraceRunner> createState() => _TraceRunnerState();
}

class _TraceRunnerState extends ConsumerState<TraceRunner> {
  late RunResult _result;
  int _index = 0;
  Timer? _timer;

  static const _stepDuration = Duration(milliseconds: 1100);

  @override
  void initState() {
    super.initState();
    _run();
  }

  @override
  void didUpdateWidget(TraceRunner old) {
    super.didUpdateWidget(old);
    if (old.code != widget.code) _run();
  }

  void _run() {
    _timer?.cancel();
    _result = const Interpreter().run(widget.code, inputs: widget.inputs, files: widget.files);
    _index = 0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool get _playing => _timer?.isActive ?? false;
  bool get _atEnd => _index >= _result.trace.length - 1;

  void _goTo(int i) {
    setState(() => _index = i.clamp(0, _result.trace.length - 1));
    final step = _result.trace[_index];
    playSfx(ref, step.kind == StepKind.error ? Sfx.error : Sfx.move);
  }

  void _togglePlay() {
    if (_playing) {
      setState(() => _timer?.cancel());
      return;
    }
    if (_atEnd) _goTo(0);
    _timer = Timer.periodic(_stepDuration, (t) {
      if (_atEnd) {
        t.cancel();
        setState(() {});
        return;
      }
      _goTo(_index + 1);
    });
    _goTo(_index + 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final step = _result.trace[_index];
    final isError = step.kind == StepKind.error;
    final globals = step.variables.where((v) => v.scope == null).toList();
    final locals = step.variables.where((v) => v.scope != null).toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.lavender, width: 2.5),
        boxShadow: softShadow(AppColors.lavender),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.play_circle_rounded, color: AppColors.lavenderDeep),
              const SizedBox(width: 6),
              Text('Probelauf', style: theme.textTheme.titleMedium),
              const Spacer(),
              Text('Schritt $_index von ${_result.trace.length - 1}',
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.inkSoft)),
            ],
          ),
          const SizedBox(height: 10),
          CodeView(
            code: widget.code,
            currentLine: isError ? null : step.line,
            errorLine: isError || (_result.isSyntaxError) ? _result.error?.line : null,
          ),
          const SizedBox(height: 10),
          // Robo erklärt den Schritt
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KawaiiRobot(mood: isError ? RobotMood.dizzy : (_atEnd ? RobotMood.happy : RobotMood.normal), size: 44),
              const SizedBox(width: 8),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    key: ValueKey(_index),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isError ? AppColors.errorLine : AppColors.lavender.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        _result.isSyntaxError
                            ? '${_result.error!.display}\nDeshalb kann das Programm gar nicht starten.'
                            : (step.line == null ? step.description : 'Zeile ${step.line}: ${step.description}'),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (step.variables.isNotEmpty) ...[
            _VarSection(title: 'Variablen', vars: globals),
            if (locals.isNotEmpty) _VarSection(title: 'In der Funktion ${locals.first.scope}', vars: locals),
          ],
          const SizedBox(height: 8),
          Text('Ausgabe', style: theme.textTheme.labelLarge),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 36),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFFF1FBF7), borderRadius: BorderRadius.circular(10)),
            child: Text(
              step.output.isEmpty ? '(noch nichts)' : step.output.trimRight(),
              style: codeTextStyle.copyWith(fontSize: 15, color: step.output.isEmpty ? AppColors.inkSoft : AppColors.ink),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.outlined(
                tooltip: 'Zum Anfang',
                onPressed: _index > 0 ? () => setState(() { _timer?.cancel(); _index = 0; }) : null,
                icon: const Icon(Icons.first_page_rounded),
              ),
              const SizedBox(width: 6),
              IconButton.outlined(
                tooltip: 'Schritt zurück',
                onPressed: _index > 0 ? () { _timer?.cancel(); _goTo(_index - 1); } : null,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              const SizedBox(width: 6),
              FilledButton.icon(
                onPressed: _result.trace.length > 1 ? _togglePlay : null,
                icon: Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                label: Text(_playing ? 'Pause' : (_atEnd ? 'Nochmal' : 'Abspielen')),
              ),
              const SizedBox(width: 6),
              IconButton.outlined(
                tooltip: 'Schritt vor',
                onPressed: !_atEnd ? () { _timer?.cancel(); _goTo(_index + 1); } : null,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VarSection extends StatelessWidget {
  const _VarSection({required this.title, required this.vars});

  final String title;
  final List<VarView> vars;

  @override
  Widget build(BuildContext context) {
    if (vars.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              for (final v in vars)
                VariableBox(key: ValueKey('${v.scope}:${v.name}'), name: v.name, value: v.repr, typeName: v.typeName, changed: v.changed),
            ],
          ),
        ],
      ),
    );
  }
}
