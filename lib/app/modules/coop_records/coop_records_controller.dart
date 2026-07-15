import 'package:get/get.dart';

import '../../data/models/coop_session_record.dart';
import '../../data/services/coop_record_service.dart';

class CoopRecordsController extends GetxController {
  final CoopRecordService _service = Get.find();

  RxList<CoopSessionRecord> get records => _service.records;

  Future<void> delete(CoopSessionRecord record) => _service.delete(record);
}
