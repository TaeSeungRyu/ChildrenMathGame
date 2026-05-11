import 'package:get/get.dart';

import '../../routes/app_routes.dart';

class TimesTableSelectController extends GetxController {
  static const tables = [2, 3, 4, 5, 6, 7, 8, 9];

  void selectTable(int table) {
    Get.toNamed(
      AppRoutes.game,
      arguments: {'tableNumber': table},
    );
  }
}
