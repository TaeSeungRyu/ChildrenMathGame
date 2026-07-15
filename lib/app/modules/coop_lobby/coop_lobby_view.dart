import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/coop_role.dart';
import '../../data/services/multiplayer/multiplayer_service.dart';
import 'coop_lobby_controller.dart';

/// 부모와 함께하기 로비. 상태(MultiplayerState + 역할 선택)에 따라 화면이
/// 전환된다: 학습 선택 → 방 개설/참여 → (탐색/대기/연결) → 역할 선택.
class CoopLobbyView extends GetView<CoopLobbyController> {
  const CoopLobbyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '부모와 함께하기',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Obx(() {
            if (controller.permissionBlocked.value) {
              return const _PermissionBlocked();
            }
            final connected = controller.state == MultiplayerState.connected ||
                controller.state == MultiplayerState.inSession;
            if (connected) {
              return controller.role.value == null
                  ? const _RolePicker()
                  : const _ConnectedPlaceholder();
            }
            switch (controller.state) {
              case MultiplayerState.advertising:
                return const _Waiting(
                  message: '방을 열었어요.\n상대가 참여하기를 기다리는 중...',
                );
              case MultiplayerState.discovering:
                return const _Discovering();
              case MultiplayerState.connecting:
                return const _Waiting(message: '연결하는 중...');
              case MultiplayerState.idle:
              case MultiplayerState.error:
              case MultiplayerState.disconnected:
              case MultiplayerState.permissionDenied:
              case MultiplayerState.connected:
              case MultiplayerState.inSession:
                return const _Setup();
            }
          }),
        ),
      ),
    );
  }
}

/// 학습 선택 + 방 개설/참여.
class _Setup extends GetView<CoopLobbyController> {
  const _Setup();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (controller.state == MultiplayerState.error ||
              controller.state == MultiplayerState.disconnected)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: _Notice('연결이 끊겼어요. 다시 시도해 주세요.'),
            ),
          const _SectionTitle('무엇을 함께 풀까요?'),
          const SizedBox(height: 8),
          const _OpPicker(),
          const SizedBox(height: 16),
          const _SectionTitle('난이도'),
          const SizedBox(height: 8),
          const _LevelPicker(),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: controller.hostRoom,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(60),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.wifi_tethering, size: 26),
            label: const Text(
              '방 개설',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: controller.joinRoom,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(60),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.search, size: 26),
            label: const Text(
              '참여',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _OpPicker extends GetView<CoopLobbyController> {
  const _OpPicker();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.selectedOp.value;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final op in CoopLobbyController.opChoices)
            ChoiceChip(
              label: Text(
                op == null ? '🎲 랜덤' : '${op.symbol} ${op.label}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              selected: op == selected,
              onSelected: (_) => controller.setOp(op),
            ),
        ],
      );
    });
  }
}

class _LevelPicker extends GetView<CoopLobbyController> {
  const _LevelPicker();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.selectedLevel.value;
      return Row(
        children: [
          for (final level in CoopLobbyController.levelChoices) ...[
            Expanded(
              child: ChoiceChip(
                label: SizedBox(
                  width: double.infinity,
                  child: Text(
                    '$level',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                selected: level == selected,
                onSelected: (_) => controller.setLevel(level),
              ),
            ),
            if (level != CoopLobbyController.levelChoices.last)
              const SizedBox(width: 6),
          ],
        ],
      );
    });
  }
}

/// 참여자: 발견된 방 목록.
class _Discovering extends GetView<CoopLobbyController> {
  const _Discovering();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle('주변의 방을 찾는 중...'),
        const SizedBox(height: 8),
        Expanded(
          child: Obx(() {
            final peers = controller.mp.peers;
            if (peers.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('상대가 방을 열면 여기에 나타나요'),
                  ],
                ),
              );
            }
            return ListView.separated(
              itemCount: peers.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final peer = peers[i];
                return Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: const Icon(Icons.person, size: 30),
                    title: Text(
                      peer.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => controller.connectToPeer(peer.endpointId),
                  ),
                );
              },
            );
          }),
        ),
        const _CancelButton(),
      ],
    );
  }
}

class _Waiting extends GetView<CoopLobbyController> {
  const _Waiting({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        const CircularProgressIndicator(),
        const SizedBox(height: 20),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        const _CancelButton(),
      ],
    );
  }
}

/// 연결 직후 역할 선택.
class _RolePicker extends GetView<CoopLobbyController> {
  const _RolePicker();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        const Icon(Icons.link, size: 56, color: Color(0xFF1976D2)),
        const SizedBox(height: 12),
        const Text(
          '연결됐어요! 이 기기는 누구인가요?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => controller.chooseRole(CoopRole.parent),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(64),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text(
            '👩‍👦 나는 부모예요',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.tonal(
          onPressed: () => controller.chooseRole(CoopRole.child),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(64),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text(
            '🧒 나는 아이예요',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const Spacer(),
        const _CancelButton(),
      ],
    );
  }
}

/// 단계 4 종료 지점 — 학습/코치 화면은 다음 단계에서 연결.
class _ConnectedPlaceholder extends GetView<CoopLobbyController> {
  const _ConnectedPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        const Icon(Icons.check_circle, size: 64, color: Color(0xFF2E7D32)),
        const SizedBox(height: 16),
        Text(
          '연결 완료! (${controller.role.value?.label})\n학습 화면은 곧 준비돼요.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        const _CancelButton(label: '연결 끊기'),
      ],
    );
  }
}

class _CancelButton extends GetView<CoopLobbyController> {
  const _CancelButton({this.label = '취소'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: controller.cancel,
      child: Text(label, style: const TextStyle(fontSize: 16)),
    );
  }
}

class _PermissionBlocked extends GetView<CoopLobbyController> {
  const _PermissionBlocked();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock, size: 56, color: Colors.orange),
        const SizedBox(height: 16),
        const Text(
          '근처 기기 연결 권한이 필요해요.\n설정에서 권한을 켜 주세요.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: controller.openSettings,
          child: const Text('설정 열기'),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEF9A9A)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}
