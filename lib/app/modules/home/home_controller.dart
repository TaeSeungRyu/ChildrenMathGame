import 'package:get/get.dart';

import '../../data/models/action_concept.dart';
import '../../data/models/daily_mission.dart';
import '../../data/models/game_type.dart';
import '../../data/services/record_service.dart';
import '../../routes/app_routes.dart';
import '../../shared/daily_missions.dart';
import '../../shared/weakness.dart';

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

  /// 기록 탭의 "복습하기" 진입점. 날짜 선택 화면으로 보낸다 — 그 화면이
  /// 저장된 오답을 날짜별로 모아 보여 주고, 사용자가 하루를 고르면 그날 오답
  /// 전부를 인자로 채워서 `/review`로 다시 라우팅한다. 빈 목록 상태와 라우팅
  /// 계약은 [ReviewSelectController]가 책임진다.
  void openReview() {
    Get.toNamed(AppRoutes.reviewSelect);
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
