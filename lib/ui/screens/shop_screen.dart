import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../audio/sfx.dart';
import '../../audio/sound_player.dart';
import '../../exercises/outfits.dart';
import '../../state/providers.dart';
import '../theme.dart';
import '../widgets/kawaii/kawaii_coin.dart';
import '../widgets/kawaii/kawaii_robot.dart';
import '../widgets/map/stats_bar.dart';

/// Outfits für Robo kaufen und anziehen.
class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final notifier = ref.read(profileProvider.notifier);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Robos Shop')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(
                    child: Column(children: [
                      const StatsBar(),
                      const SizedBox(height: 12),
                      KawaiiRobot(size: 140, outfit: profile.outfit, mood: RobotMood.happy),
                      Text('Münzen bekommst du für jede geschaffte Insel.', style: theme.textTheme.bodyMedium),
                    ]),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverGrid.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: Outfit.values.length,
                    itemBuilder: (context, i) {
                      final outfit = Outfit.values[i];
                      final owned = profile.owned.contains(outfit);
                      final wearing = profile.outfit == outfit;
                      final canBuy = profile.coins >= outfit.price;
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: wearing ? AppColors.pinkDeep : AppColors.cardBorder, width: wearing ? 3 : 2),
                          boxShadow: softShadow(AppColors.pastels[i % AppColors.pastels.length]),
                        ),
                        child: Column(
                          children: [
                            Expanded(child: KawaiiRobot(outfit: outfit)),
                            Text(outfit.label, style: theme.textTheme.titleMedium),
                            const SizedBox(height: 6),
                            if (wearing)
                              const Chip(label: Text('Angezogen'), avatar: Icon(Icons.favorite_rounded, color: AppColors.pinkDeep, size: 18))
                            else if (owned)
                              OutlinedButton(onPressed: () => notifier.wear(outfit), child: const Text('Anziehen'))
                            else
                              FilledButton.icon(
                                onPressed: canBuy
                                    ? () {
                                        if (notifier.buy(outfit)) playSfx(ref, Sfx.coin);
                                      }
                                    : null,
                                icon: const SizedBox(width: 18, height: 18, child: KawaiiCoin()),
                                label: Text('${outfit.price}'),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
