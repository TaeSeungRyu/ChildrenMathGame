import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calculate, size: 128, color: scheme.onPrimary),
            const SizedBox(height: 24),
            Text(
              '어린이 수학 게임',
              style: TextStyle(
                fontFamily: Theme.of(context).textTheme.displayLarge?.fontFamily,
                fontSize: 56,
                color: scheme.onPrimary,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Children Math Game',
              style: TextStyle(
                fontFamily: Theme.of(context).textTheme.titleMedium?.fontFamily,
                fontSize: 18,
                color: scheme.onPrimary.withValues(alpha: 0.85),
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
