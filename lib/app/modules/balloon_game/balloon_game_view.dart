import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../shared/action_intro_scaffold.dart';
import 'balloon_game_controller.dart';

class BalloonGameView extends GetView<BalloonGameController> {
  const BalloonGameView({super.key});

  static const _spec = ActionIntroSpec(
    title: '풍선 터뜨리기',
    tagline: '같은 답을 가진 풍선을 골라요!',
    icon: Icons.celebration,
    bg: Color(0xFFFFE082),
    accent: Color(0xFFE65100),
    fg: Color(0xFF5D4037),
    howToPlay: [
      '화면 위에 풍선들이 떠다녀요.',
      '"목표 답"과 같은 풍선만 골라서 톡!',
      '오답 풍선은 피해야 해요.',
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
