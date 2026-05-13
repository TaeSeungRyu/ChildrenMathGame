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
      title: '어린이의 수학 게임',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
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
