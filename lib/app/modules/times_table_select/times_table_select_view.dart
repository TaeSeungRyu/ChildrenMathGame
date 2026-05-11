import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'times_table_select_controller.dart';

class TimesTableSelectView extends GetView<TimesTableSelectController> {
  const TimesTableSelectView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '구구단 연습',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewPadding.bottom + 16,
        ),
        child: Column(
          children: [
            const Text(
              '단을 골라 9문제를 풀어볼까요?',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.4,
                children: TimesTableSelectController.tables
                    .map(
                      (t) => _TableTile(
                        table: t,
                        onTap: () => controller.selectTable(t),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableTile extends StatelessWidget {
  const _TableTile({required this.table, required this.onTap});

  final int table;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primaryContainer,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$table',
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              Text(
                '단',
                style: TextStyle(
                  fontSize: 24,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
