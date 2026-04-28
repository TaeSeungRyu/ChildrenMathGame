import 'package:get/get.dart';

import '../../data/models/game_record.dart';
import '../../data/services/record_service.dart';

class RecordsController extends GetxController {
  final records = <GameRecord>[].obs;

  @override
  void onInit() {
    super.onInit();
    final all = Get.find<RecordService>().all()
      ..sort((a, b) => b.finishedAt.compareTo(a.finishedAt));
    records.assignAll(all);
  }
}
