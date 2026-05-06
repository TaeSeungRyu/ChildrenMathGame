import 'package:get/get.dart';

import '../../data/models/game_record.dart';

class RecordDetailController extends GetxController {
  late final GameRecord record;

  @override
  void onInit() {
    super.onInit();
    record = Get.arguments as GameRecord;
  }
}
