import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/game_type.dart';
import '../../data/models/problem_attempt.dart';
import '../../data/models/wrong_notebook_entry.dart';
import '../../data/services/record_service.dart';
import '../../routes/app_routes.dart';
import '../../shared/wrong_notebook.dart';

class WrongNotebookController extends GetxController {
  final RecordService _records = Get.find<RecordService>();

  final entries = <WrongNotebookEntry>[].obs;

  // null = 전체. Selected via filter chips at the top of the view.
  final selectedBucket = Rx<GameType?>(null);

  @override
  void onInit() {
    super.onInit();
    _reload();
  }

  void _reload() {
    entries.assignAll(
      aggregateWrongNotebook(
        _records.all(),
        dismissedAt: _records.dismissedWrongSignatures(),
      ),
    );
  }

  List<WrongNotebookEntry> get filtered {
    final b = selectedBucket.value;
    if (b == null) return entries;
    return entries.where((e) => e.bucket == b).toList();
  }

  int get totalWrongCount => entries.length;

  // Buckets that actually appear in the data, ordered by enum index — used to
  // populate filter chips. Empty when there are no wrong attempts.
  List<GameType> get availableBuckets {
    final set = <GameType>{for (final e in entries) e.bucket};
    return set.toList()..sort((a, b) => a.index.compareTo(b.index));
  }

  void selectBucket(GameType? bucket) {
    selectedBucket.value = bucket;
  }

  void retryFiltered() {
    final problems = filtered.map((e) => e.sample).toList();
    if (problems.isEmpty) return;
    Get.toNamed(AppRoutes.review, arguments: problems);
  }

  void retrySingle(ProblemAttempt attempt) {
    Get.toNamed(AppRoutes.review, arguments: [attempt]);
  }

  Future<void> confirmDelete(WrongNotebookEntry entry) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('오답 삭제'),
        content: const Text(
          '이 오답을 노트에서 지울까요?\n같은 문제를 다시 틀리면 다시 나타나요.',
        ),
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
    await _records.dismissWrongSignature(wrongNotebookSignature(entry.sample));
    _reload();
    final b = selectedBucket.value;
    if (b != null && !availableBuckets.contains(b)) {
      selectedBucket.value = null;
    }
  }
}
