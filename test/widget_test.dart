import 'package:children_math_game/app/data/services/profile_service.dart';
import 'package:children_math_game/app/data/services/record_service.dart';
import 'package:children_math_game/app/data/services/sfx_service.dart';
import 'package:children_math_game/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SfxService.audioBackendEnabled = false;
    await Get.putAsync<ProfileService>(() => ProfileService().init());
    await Get.putAsync<RecordService>(() => RecordService().init());
    await Get.putAsync<SfxService>(() => SfxService().init());
  });

  tearDown(() async {
    await Get.deleteAll(force: true);
  });

  testWidgets('splash screen is shown on launch', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    expect(
      find.text('${ProfileService.defaultName}의 수학 게임'),
      findsOneWidget,
    );
  });
}
