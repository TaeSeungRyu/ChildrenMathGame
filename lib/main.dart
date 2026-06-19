import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'app/data/services/custom_stamp_service.dart';
import 'app/data/services/profile_service.dart';
import 'app/data/services/record_service.dart';
import 'app/data/services/sfx_service.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // 세로 고정 — 모든 화면(키패드/아레나/오버레이)이 세로 비율 기준으로 레이아웃
  // 되어 있어 가로로 돌리면 의도와 다르게 잘리거나 늘어진다.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await Get.putAsync<ProfileService>(() => ProfileService().init());
  await Get.putAsync<RecordService>(() => RecordService().init());
  await Get.putAsync<SfxService>(() => SfxService().init());
  await Get.putAsync<CustomStampService>(() => CustomStampService().init());
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  // 백그라운드 진입 시각. 다시 포그라운드로 돌아왔을 때 얼마나 자리비웠는지
  // 계산해 임계치를 넘으면 스플래시로 강제 복귀시킨다.
  DateTime? _pausedAt;

  // 백그라운드 5분 이상이면 "긴 자리비움"으로 간주. 너무 짧으면 알림 하나
  // 확인하고 돌아온 사용자도 끊겨 짜증나고, 너무 길면 다른 앱 한참 쓰다
  // 돌아왔는데도 게임 중간이 그대로 떠 있어 "어디까지 했지?" 흐름이 깨진다.
  // 5분이면 짧은 끼어들기는 통과시키되, 한참 다른 일 하다 돌아온 경우는
  // 새로 시작하는 느낌을 주는 합리적 절충.
  static const _resetAfter = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final pausedAt = _pausedAt;
      _pausedAt = null;
      if (pausedAt == null) return;
      if (DateTime.now().difference(pausedAt) < _resetAfter) return;
      // 이미 스플래시면 또 보낼 필요 없음. 그 외 어디에 있었든(게임 중,
      // 결과 화면 등) 스택을 비우고 처음부터 다시 흐르게 한다.
      if (Get.currentRoute == AppRoutes.splash) return;
      Get.offAllNamed(AppRoutes.splash);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: '연산 히어로',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        // Warm cream rather than clinical white — pairs with the light-sky
        // AppBar as a warm/cool complement and reads more "놀이감" than
        // "교과서" for the 6–9세 target. Cards (primaryContainer /
        // secondaryContainer / tertiaryContainer) are saturated enough to
        // stand out against it.
        scaffoldBackgroundColor: const Color(0xFFFFF8E7),
        appBarTheme: const AppBarTheme(
          // Light sky (#4FC3F7) for a softer, playful tone; deep-blue fg
          // (#0D47A1) keeps WCAG contrast comfortably above 4.5 — white text
          // on the lighter sky would dip below 2.5.
          backgroundColor: Color(0xFF4FC3F7),
          foregroundColor: Color(0xFF0D47A1),
        ),
        // Bundled in assets/fonts/Jua-Regular.ttf — pubspec.yaml registers
        // the family. No runtime fetch, works offline from first launch.
        fontFamily: 'Jua',
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
      debugShowCheckedModeBanner: false,
    );
  }
}
