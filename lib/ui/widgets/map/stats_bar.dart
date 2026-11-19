import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../state/providers.dart';
import '../../theme.dart';
import '../kawaii/kawaii_coin.dart';

/// Serie, XP und Münzen.
class StatsBar extends ConsumerWidget {
  const StatsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final streak = ref.read(profileProvider.notifier).visibleStreak;
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _Stat(
          tooltip: 'Tage in Folge gespielt',
          icon: Icon(Icons.local_fire_department_rounded, color: streak > 0 ? const Color(0xFFFF8A3D) : AppColors.inkSoft),
          value: '$streak',
        ),
        _Stat(tooltip: 'Erfahrungspunkte', icon: const Icon(Icons.star_rounded, color: AppColors.star), value: '${profile.xp} XP'),
        _Stat(tooltip: 'Münzen für den Shop', icon: const SizedBox(width: 22, height: 22, child: KawaiiCoin()), value: '${profile.coins}'),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.tooltip, required this.icon, required this.value});

  final String tooltip;
  final Widget icon;
  final String value;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 2),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        icon,
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ]),
    ),
  );
}
