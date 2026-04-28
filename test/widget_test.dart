import 'package:children_math_game/app/data/services/record_service.dart';
import 'package:children_math_game/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Get.putAsync<RecordService>(() => RecordService().init());
  });

  tearDown(() async {
    await Get.deleteAll(force: true);
  });

  testWidgets('splash screen is shown on launch', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    expect(find.text('어린이 수학 게임'), findsOneWidget);
  });
}
