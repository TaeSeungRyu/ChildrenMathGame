import 'package:get/get.dart';

import '../modules/badges/badges_binding.dart';
import '../modules/badges/badges_view.dart';
import '../modules/game/game_binding.dart';
import '../modules/game/game_view.dart';
import '../modules/home/home_binding.dart';
import '../modules/home/home_view.dart';
import '../modules/level_select/level_select_binding.dart';
import '../modules/level_select/level_select_view.dart';
import '../modules/record_detail/record_detail_binding.dart';
import '../modules/record_detail/record_detail_view.dart';
import '../modules/records/records_binding.dart';
import '../modules/records/records_view.dart';
import '../modules/result/result_binding.dart';
import '../modules/result/result_view.dart';
import '../modules/review/review_binding.dart';
import '../modules/review/review_view.dart';
import '../modules/stats/stats_binding.dart';
import '../modules/stats/stats_view.dart';
import '../modules/splash/splash_binding.dart';
import '../modules/splash/splash_view.dart';
import '../modules/mixed_select/mixed_select_binding.dart';
import '../modules/mixed_select/mixed_select_view.dart';
import '../modules/times_table_select/times_table_select_binding.dart';
import '../modules/times_table_select/times_table_select_view.dart';
import '../modules/tutorial/tutorial_binding.dart';
import '../modules/tutorial/tutorial_view.dart';
import 'app_routes.dart';

abstract class AppPages {
  static final pages = <GetPage<dynamic>>[
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.levelSelect,
      page: () => const LevelSelectView(),
      binding: LevelSelectBinding(),
    ),
    GetPage(
      name: AppRoutes.game,
      page: () => const GameView(),
      binding: GameBinding(),
    ),
    GetPage(
      name: AppRoutes.result,
      page: () => const ResultView(),
      binding: ResultBinding(),
    ),
    GetPage(
      name: AppRoutes.records,
      page: () => const RecordsView(),
      binding: RecordsBinding(),
    ),
    GetPage(
      name: AppRoutes.recordDetail,
      page: () => const RecordDetailView(),
      binding: RecordDetailBinding(),
    ),
    GetPage(
      name: AppRoutes.badges,
      page: () => const BadgesView(),
      binding: BadgesBinding(),
    ),
    GetPage(
      name: AppRoutes.review,
      page: () => const ReviewView(),
      binding: ReviewBinding(),
    ),
    GetPage(
      name: AppRoutes.stats,
      page: () => const StatsView(),
      binding: StatsBinding(),
    ),
    GetPage(
      name: AppRoutes.timesTableSelect,
      page: () => const TimesTableSelectView(),
      binding: TimesTableSelectBinding(),
    ),
    GetPage(
      name: AppRoutes.mixedSelect,
      page: () => const MixedSelectView(),
      binding: MixedSelectBinding(),
    ),
    GetPage(
      name: AppRoutes.tutorial,
      page: () => const TutorialView(),
      binding: TutorialBinding(),
    ),
  ];
}
