import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/services/problem_generator.dart';
import '../../routes/app_routes.dart';

/// 부호 맞추기 레벨 선택. 레벨별로 맞혀야 하는 기호 개수와 후보 연산이 다르다.
class SignGuessSelectView extends StatelessWidget {
  const SignGuessSelectView({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '부호 맞추기',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
        children: [
          const Text(
            '식의 숨은 기호를 맞혀 보세요!',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          for (var level = 1; level <= 5; level++) ...[
            _LevelCard(level: level),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    final count = ProblemGenerator.signGuessOpCount(level);
    final pool = ProblemGenerator.signGuessPool(level)
        .map((t) => t.symbol)
        .join(' ');
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Get.toNamed(
          AppRoutes.signGuess,
          arguments: {'level': level},
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFF4FC3F7),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$level',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '레벨 $level · 기호 $count개',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '사용 기호: $pool',
                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
