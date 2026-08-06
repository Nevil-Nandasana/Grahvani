/// Profile Domain — Riverpod AsyncNotifier for profile list
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/profile_repository.dart';
import 'profile_model.dart';

part 'profile_provider.g.dart';

@riverpod
class ProfilesNotifier extends _$ProfilesNotifier {
  @override
  Future<List<BirthProfile>> build() async {
    return ref.read(profileRepositoryProvider).listProfiles();
  }

  Future<void> createProfile({
    required String name,
    required String dateOfBirth,
    required String timeOfBirth,
    required String placeName,
    required double latitude,
    required double longitude,
    required String timezone,
  }) async {
    final newProfile = await ref.read(profileRepositoryProvider).createProfile(
          name: name,
          dateOfBirth: dateOfBirth,
          timeOfBirth: timeOfBirth,
          placeName: placeName,
          latitude: latitude,
          longitude: longitude,
          timezone: timezone,
        );

    final current = state.valueOrNull ?? [];
    state = AsyncData([newProfile, ...current]);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(profileRepositoryProvider).listProfiles(),
    );
  }
}
