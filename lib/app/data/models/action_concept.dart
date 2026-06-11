import '../../routes/app_routes.dart';

/// 액션 게임의 4가지 컨셉. 홈 "게임" 탭의 각 타일이 자신의 컨셉을 들고
/// 공통 진입 선택 화면(`/action-select`)으로 들어가며, 거기서 시작 버튼을
/// 누르면 [gameRoute]로 라우팅된다. 컨셉별 본편 화면(현재는 인트로 셸)이
/// [gameRoute]에 매핑돼 있다.
enum ActionConcept {
  monster('몬스터 처치', AppRoutes.monsterGame),
  balloon('풍선 터뜨리기', AppRoutes.balloonGame),
  tower('타워 디펜스', AppRoutes.towerDefense),
  mole('두더지 잡기', AppRoutes.moleGame);

  const ActionConcept(this.title, this.gameRoute);

  final String title;
  final String gameRoute;
}
