/// Chart Domain — Riverpod provider for chart calculation and polling
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/chart_repository.dart';
import 'chart_model.dart';

part 'chart_provider.g.dart';

/// Fetches (or triggers) a chart for a given profile ID.
/// The profile ID is passed as argument to allow per-profile caching.
@riverpod
class ChartNotifier extends _$ChartNotifier {
  @override
  Future<BirthChartFacts?> build(String profileId) async {
    return await _loadOrTrigger(profileId);
  }

  Future<BirthChartFacts?> _loadOrTrigger(String profileId) async {
    final repo = ref.read(chartRepositoryProvider);

    // Step 1: Trigger calculation (returns immediately with chart_id)
    final chartId = await repo.triggerCalculation(profileId);

    // Step 2: Poll until complete
    await _pollUntilComplete(repo, chartId);

    // Step 3: Fetch completed chart facts
    return await repo.getChart(chartId);
  }

  Future<void> _pollUntilComplete(
    ChartRepository repo,
    String chartId, {
    int maxAttempts = 20,
    Duration interval = const Duration(seconds: 2),
  }) async {
    for (int i = 0; i < maxAttempts; i++) {
      await Future.delayed(interval);
      final status = await repo.getChartStatus(chartId);
      if (status == 'complete') return;
      if (status == 'error') throw Exception('Chart calculation failed.');
    }
    throw Exception('Chart calculation timed out.');
  }

  Future<void> refresh(String profileId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadOrTrigger(profileId));
  }
}
