import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/action_concept.dart';
import '../../data/models/daily_mission.dart';
import '../../data/models/game_type.dart';
import '../../data/services/record_service.dart';
import '../../routes/app_routes.dart';
import '../../shared/daily_missions.dart';
import '../../shared/weakness.dart';
import '../../shared/wrong_notebook.dart';

class HomeController extends GetxController {
  final RecordService _records = Get.find<RecordService>();

  // Current bottom-tab index. 0 = 학습, 1 = 게임, 2 = 기록.
  // Survives within the lifetime of the Home controller; reset to 0 on cold
  // start since the binding lazy-instantiates fresh.
  final RxInt tabIndex = 0.obs;

  // 시스템 백 버튼 두 번 눌러 종료 패턴용. 직전 백 시각을 기록만 하고
  // UI 리빌드를 트리거할 일이 없으므로 Rx가 아니라 평범한 필드.
  DateTime? lastBackPressedAt;

  late final int streakDays = _records.currentStreak();
  late final WeaknessAnalysis weakness = analyzeWeakness(_records.all());
  late final List<DailyMissionStatus> missions = evaluateDailyMissions(
    _records.all(),
  );

  WeaknessBucket? get recommendation => weakness.recommendation;
  int get missionsCompleted => missions.where((m) => m.isComplete).length;

  void setTab(int i) => tabIndex.value = i;

  void selectGame(GameType type) {
    Get.toNamed(AppRoutes.levelSelect, arguments: type);
  }

  void openRecords() {
    Get.toNamed(AppRoutes.records);
  }

  void openBadges() {
    Get.toNamed(AppRoutes.badges);
  }

  void openTimesTable() {
    Get.toNamed(AppRoutes.timesTableSelect);
  }

  void openMixed() {
    Get.toNamed(AppRoutes.mixedSelect);
  }

  void openEquation() {
    Get.toNamed(AppRoutes.equationSelect);
  }

  void openFlash() {
    Get.toNamed(AppRoutes.flashSelect);
  }

  void openEstimation() {
    Get.toNamed(AppRoutes.estimationSelect);
  }

  void openWrongNotebook() {
    Get.toNamed(AppRoutes.wrongNotebook);
  }

  void openStats() {
    Get.toNamed(AppRoutes.stats);
  }

  /// 기록 탭의 "복습하기" 진입점. 저장된 모든 기록에서 오답을 자동 집계해
  /// 가장 자주/최근에 틀린 상위 [_reviewMaxProblems]개를 골라 review 화면으로
  /// 넘긴다. 오답이 하나도 없으면 안내 스낵바를 띄우고 라우팅하지 않는다.
  ///
  /// 이전에는 인자 없이 `/review`로만 라우팅해서 ReviewController가 null을
  /// List로 캐스팅하다 죽었다. 복습 대상은 호출자가 항상 채워서 넘기는 것이
  /// 본 화면의 계약이므로, 여기서 직접 채워 준다.
  static const int _reviewMaxProblems = 10;
  void openReview() {
    final wrongs = aggregateWrongNotebook(
      _records.all(),
      dismissedAt: _records.dismissedWrongSignatures(),
    );
    if (wrongs.isEmpty) {
      Get.snackbar(
        '복습 거리 없음',
        '아직 틀린 문제가 없어요. 게임 한 판 어때요?',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      );
      return;
    }
    final problems = wrongs
        .take(_reviewMaxProblems)
        .map((e) => e.sample)
        .toList();
    Get.toNamed(AppRoutes.review, arguments: problems);
  }

  /// 게임 탭의 4개 타일이 공유하는 진입점. 컨셉을 인자로 들고 공통 진입
  /// 선택 화면(`/action-select`)으로 이동한다. 거기서 연산·자릿수를 고른 뒤
  /// 컨셉별 본편 라우트로 넘어간다.
  void openActionSelect(ActionConcept concept) {
    Get.toNamed(AppRoutes.actionSelect, arguments: {'concept': concept});
  }

  void startRecommended(WeaknessBucket bucket) {
    Get.toNamed(
      AppRoutes.game,
      arguments: {
        'type': bucket.type,
        'level': bucket.level,
        'isPractice': true,
      },
    );
  }
}
