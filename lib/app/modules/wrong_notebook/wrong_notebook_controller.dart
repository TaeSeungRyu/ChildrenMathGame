import 'package:get/get.dart';

import '../../data/models/game_type.dart';
import '../../data/models/problem_attempt.dart';
import '../../data/models/wrong_notebook_entry.dart';
import '../../data/services/record_service.dart';
import '../../routes/app_routes.dart';
import '../../shared/wrong_notebook.dart';

class WrongNotebookController extends GetxController {
  final RecordService _records = Get.find<RecordService>();

  late final List<WrongNotebookEntry> _all = aggregateWrongNotebook(
    _records.all(),
  );

  // null = 전체. Selected via filter chips at the top of the view.
  final selectedBucket = Rx<GameType?>(null);

  List<WrongNotebookEntry> get filtered {
    final b = selectedBucket.value;
    if (b == null) return _all;
    return _all.where((e) => e.bucket == b).toList();
  }

  int get totalWrongCount => _all.length;

  // Buckets that actually appear in the data, ordered by enum index — used to
  // populate filter chips. Empty when there are no wrong attempts.
  late final List<GameType> availableBuckets = (() {
    final set = <GameType>{for (final e in _all) e.bucket};
    return set.toList()..sort((a, b) => a.index.compareTo(b.index));
  })();

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
}
