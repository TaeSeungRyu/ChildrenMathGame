import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../shared/action_intro_scaffold.dart';
import 'mole_game_controller.dart';

class MoleGameView extends GetView<MoleGameController> {
  const MoleGameView({super.key});

  static const _spec = ActionIntroSpec(
    title: '두더지 잡기',
    tagline: '빠르게 답을 입력해 두더지를 잡아요!',
    icon: Icons.gps_fixed,
    bg: Color(0xFFC5E1A5),
    accent: Color(0xFF33691E),
    fg: Color(0xFF1B5E20),
    howToPlay: [
      '두더지가 구멍에서 문제와 함께 튀어나와요.',
      '정답을 빠르게 입력하면 망치로 잡아요!',
      '두더지가 사라지기 전에 답을 맞춰요.',
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
