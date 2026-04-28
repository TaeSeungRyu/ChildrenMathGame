import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/game_record.dart';
import '../../data/services/record_service.dart';

class RecordsController extends GetxController {
  final records = <GameRecord>[].obs;

  RecordService get _service => Get.find<RecordService>();

  @override
  void onInit() {
    super.onInit();
    _reload();
  }

  void _reload() {
    final all = _service.all()
      ..sort((a, b) => b.finishedAt.compareTo(a.finishedAt));
    records.assignAll(all);
  }

  Future<void> confirmDelete(GameRecord record) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('기록 삭제'),
        content: const Text('이 기록을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Get.back<bool>(result: false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Get.back<bool>(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
      barrierDismissible: true,
    );
    if (confirmed != true) return;
    await _service.delete(record);
    records.remove(record);
  }
}
