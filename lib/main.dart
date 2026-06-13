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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
