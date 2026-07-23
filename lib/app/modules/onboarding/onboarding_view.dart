import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/profile.dart';
import 'onboarding_controller.dart';

/// 첫 실행에서 이름·아바타를 정하고 튜토리얼로 넘어간다.
class OnboardingView extends GetView<OnboardingController> {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 32, 24, 24 + bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '반가워요! 👋',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '무엇이라고 부를까요?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 28),
              // Live big avatar preview.
              Obx(
                () => Text(
                  controller.avatar.value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 80),
                ),
              ),
              const SizedBox(height: 12),
              const _NameField(),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '내 캐릭터를 골라요',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 10),
              const _AvatarGrid(),
              const SizedBox(height: 28),
              Obx(
                () => FilledButton(
                  onPressed: controller.canSubmit ? controller.submit : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    '시작하기',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: controller.skip,
                child: const Text('나중에 할래요', style: TextStyle(fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NameField extends StatefulWidget {
  const _NameField();

  @override
  State<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<_NameField> {
  late final TextEditingController _tc;

  @override
  void initState() {
    super.initState();
    _tc = TextEditingController();
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<OnboardingController>();
    return TextField(
      controller: _tc,
      autofocus: true,
      textAlign: TextAlign.center,
      maxLength: OnboardingController.maxNameLength,
      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
      decoration: const InputDecoration(
        hintText: '이름 (최대 3자)',
        counterText: '',
        border: OutlineInputBorder(),
      ),
      onChanged: c.setName,
      onSubmitted: (_) => c.submit(),
    );
  }
}

class _AvatarGrid extends GetView<OnboardingController> {
  const _AvatarGrid();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.avatar.value;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: [
          for (final emoji in Profile.avatarChoices)
            InkWell(
              onTap: () => controller.setAvatar(emoji),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: emoji == selected
                      ? const Color(0xFF4FC3F7).withValues(alpha: 0.35)
                      : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: emoji == selected
                        ? const Color(0xFF1976D2)
                        : const Color(0xFFD7CCC8),
                    width: emoji == selected ? 2.5 : 1,
                  ),
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 30)),
              ),
            ),
        ],
      );
    });
  }
}
