import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/services/profile_service.dart';
import 'splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final profile = Get.find<ProfileService>();
    return Scaffold(
      backgroundColor: scheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calculate, size: 128, color: scheme.onPrimary),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Obx(
                  () => Text(
                    '${profile.name.value}의 수학 게임',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                    style: TextStyle(
                      fontFamily:
                          Theme.of(context).textTheme.displayLarge?.fontFamily,
                      fontSize: 56,
                      color: scheme.onPrimary,
                      height: 1.1,
                    ),
                  ),
                ),
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
