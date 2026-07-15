abstract class AppRoutes {
  static const splash = '/splash';
  static const home = '/home';
  static const levelSelect = '/level-select';
  static const game = '/game';
  static const result = '/result';
  static const records = '/records';
  static const recordDetail = '/record-detail';
  static const badges = '/badges';
  static const review = '/review';
  static const reviewSelect = '/review-select';
  static const stats = '/stats';
  static const timesTableSelect = '/times-table-select';
  static const mixedSelect = '/mixed-select';
  static const equationSelect = '/equation-select';
  static const flashSelect = '/flash-select';
  static const estimationSelect = '/estimation-select';
  static const tutorial = '/tutorial';
  static const wrongNotebook = '/wrong-notebook';

  // 부모와 함께하는 학습 (Nearby Connections). 로비 → 아이(학습)/부모(코치) 화면.
  static const coopLobby = '/coop-lobby';
  static const coopLearn = '/coop-learn';
  static const coopCoach = '/coop-coach';
  static const coopRecords = '/coop-records';
  static const coopRecordDetail = '/coop-record-detail';

  // Action game modes — intro/select shells in 1st pass; play logic added later.
  // `actionSelect` is the common entry-select screen shared by all concepts;
  // it routes onward to the per-concept route below with chosen op/digit args.
  static const actionSelect = '/action-select';
  static const monsterGame = '/monster-game';
  static const balloonGame = '/balloon-game';
  static const towerDefense = '/tower-defense';
  static const moleGame = '/mole-game';
  static const ladderGame = '/ladder-game';
  static const fishingGame = '/fishing-game';
}
