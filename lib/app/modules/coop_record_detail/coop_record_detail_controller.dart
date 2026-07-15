import 'package:get/get.dart';

import '../../data/models/coop_session_record.dart';
import '../../routes/app_routes.dart';

class CoopRecordDetailController extends GetxController {
  late final CoopSessionRecord record;

  @override
  void onInit() {
    super.onInit();
    record = Get.arguments as CoopSessionRecord;
  }

  bool get hasWrong => record.wrongAttempts.isNotEmpty;
  int get wrongCount => record.wrongAttempts.length;

  /// Re-solve just the wrong problems, reusing the shared review flow.
  void retryWrong() {
    final wrong = record.wrongAttempts;
    if (wrong.isEmpty) return;
    Get.toNamed(AppRoutes.review, arguments: wrong);
  }
}
