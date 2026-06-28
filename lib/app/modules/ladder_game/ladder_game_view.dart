import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'ladder_game_controller.dart';

/// 숫자 사다리 — 인트로 셸(준비 중). 진입 선택에서 넘어온 설정만 보여 주고
/// "곧 만나요" 안내를 띄운다. 실제 플레이(정답 칸을 밟아 사다리를 오르는
/// 모델)는 추후 구현 예정.
class LadderGameView extends GetView<LadderGameController> {
  const LadderGameView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '숫자 사다리',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🪜', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 16),
              const Text(
                '곧 만나요!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE65100),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '정답 칸을 밟아 사다리를 올라가요.\n준비 중인 게임이에요.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, height: 1.4),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: FilledButton.icon(
                  onPressed: controller.exitToHome,
                  icon: const Icon(Icons.home, size: 26),
                  label: const Text(
                    '돌아가기',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
