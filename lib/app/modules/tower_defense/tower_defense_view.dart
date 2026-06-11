import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../shared/action_intro_scaffold.dart';
import 'tower_defense_controller.dart';

class TowerDefenseView extends GetView<TowerDefenseController> {
  const TowerDefenseView({super.key});

  static const _spec = ActionIntroSpec(
    title: '타워 디펜스',
    tagline: '문제를 풀어 성을 지켜요!',
    icon: Icons.castle,
    bg: Color(0xFF80DEEA),
    accent: Color(0xFF006064),
    fg: Color(0xFF004D40),
    howToPlay: [
      '몬스터들이 성을 향해 다가와요.',
      '문제를 풀면 마법을 발사해요!',
      '몬스터가 성에 닿기 전에 막아요.',
    ],
  );

  @override
  Widget build(BuildContext context) {
    return ActionIntroScaffold(
      spec: _spec,
      onStart: () => showComingSoonSnackbar(_spec.title),
    );
  }
}
