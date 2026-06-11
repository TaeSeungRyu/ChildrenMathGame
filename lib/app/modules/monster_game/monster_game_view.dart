import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../shared/action_intro_scaffold.dart';
import 'monster_game_controller.dart';

class MonsterGameView extends GetView<MonsterGameController> {
  const MonsterGameView({super.key});

  static const _spec = ActionIntroSpec(
    title: '몬스터 처치',
    tagline: '연산으로 공격해 몬스터를 물리쳐요!',
    icon: Icons.shield,
    bg: Color(0xFFCE93D8),
    accent: Color(0xFF4A148C),
    fg: Color(0xFF4A148C),
    howToPlay: [
      '몬스터가 문제를 들고 다가와요.',
      '정답을 입력하면 공격이 발사돼요!',
      '몬스터가 닿기 전에 모두 처치해요.',
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
