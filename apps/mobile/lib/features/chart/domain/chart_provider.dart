/// Chart Domain — Riverpod provider for chart calculation and polling
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/chart_repository.dart';
import 'chart_model.dart';

class ChartNotifier extends FamilyAsyncNotifier<BirthChartFacts?, String> {
  @override
  Future<BirthChartFacts?> build(String arg) async {
    return await _loadOrTrigger(arg);
  }

  Future<BirthChartFacts?> _loadOrTrigger(String profileId) async {
    final repo = ref.read(chartRepositoryProvider);

    // Step 0: Try loading cached chart facts for instant offline rendering
    final cached = await repo.getCachedChartForProfile(profileId);

    try {
      // Step 1: Trigger calculation (returns immediately with chart_id)
      final chartId = await repo.triggerCalculation(profileId);

      // Step 2: Poll until complete
      await _pollUntilComplete(repo, chartId);

      // Step 3: Fetch completed chart facts & cache locally
      return await repo.getChart(chartId, profileId: profileId);
    } catch (_) {
      // If network is offline or request fails, return cached chart facts
      if (cached != null) return cached;
      rethrow;
    }
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

final chartNotifierProvider =
    AsyncNotifierProvider.family<ChartNotifier, BirthChartFacts?, String>(
  ChartNotifier.new,
);
