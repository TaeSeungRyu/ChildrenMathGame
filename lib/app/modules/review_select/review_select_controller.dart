import 'package:get/get.dart';

import '../../data/services/record_service.dart';
import '../../routes/app_routes.dart';
import '../../shared/wrong_notebook.dart';

class ReviewSelectController extends GetxController {
  final RecordService _records = Get.find<RecordService>();

  late final List<DayWrongs> days = aggregateWrongsByDay(
    _records.all(),
    dismissedAt: _records.dismissedWrongSignatures(),
  );

  bool get isEmpty => days.isEmpty;

  void startDay(DayWrongs day) {
    Get.toNamed(AppRoutes.review, arguments: day.attempts);
  }
}
