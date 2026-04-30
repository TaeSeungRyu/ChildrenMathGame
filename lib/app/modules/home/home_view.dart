import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../../data/models/game_type.dart';
import 'home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '게임 선택',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SizedBox(
                height: 140,
                child: Lottie.asset(
                  'assets/lottie/home_banner.json',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Column(
                  children: [
                    Expanded(child: _tileRow(0, 1)),
                    const SizedBox(height: 16),
                    Expanded(child: _tileRow(2, 3)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.bar_chart),
                  label: const Text(
                    '결과보기',
                    style: TextStyle(fontSize: 18),
                  ),
                  onPressed: controller.openRecords,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tileRow(int leftIdx, int rightIdx) {
    final left = GameType.values[leftIdx];
    final right = GameType.values[rightIdx];
    return Row(
      children: [
        Expanded(
          child: _GameTile(
            type: left,
            onTap: () => controller.selectGame(left),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _GameTile(
            type: right,
            onTap: () => controller.selectGame(right),
          ),
        ),
      ],
    );
  }
}

class _GameTile extends StatelessWidget {
  const _GameTile({required this.type, required this.onTap});

  final GameType type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primaryContainer,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                type.symbol,
                style: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                type.label,
                style: TextStyle(
                  fontSize: 24,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
