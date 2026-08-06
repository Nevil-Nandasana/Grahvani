// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chart_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$chartNotifierHash() => r'f545cd698a4d05762551ab7e0f853fdcd7d681a9';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$ChartNotifier
    extends BuildlessAutoDisposeAsyncNotifier<BirthChartFacts?> {
  late final String profileId;

  FutureOr<BirthChartFacts?> build(
    String profileId,
  );
}

/// Fetches (or triggers) a chart for a given profile ID.
/// The profile ID is passed as argument to allow per-profile caching.
///
/// Copied from [ChartNotifier].
@ProviderFor(ChartNotifier)
const chartNotifierProvider = ChartNotifierFamily();

/// Fetches (or triggers) a chart for a given profile ID.
/// The profile ID is passed as argument to allow per-profile caching.
///
/// Copied from [ChartNotifier].
class ChartNotifierFamily extends Family<AsyncValue<BirthChartFacts?>> {
  /// Fetches (or triggers) a chart for a given profile ID.
  /// The profile ID is passed as argument to allow per-profile caching.
  ///
  /// Copied from [ChartNotifier].
  const ChartNotifierFamily();

  /// Fetches (or triggers) a chart for a given profile ID.
  /// The profile ID is passed as argument to allow per-profile caching.
  ///
  /// Copied from [ChartNotifier].
  ChartNotifierProvider call(
    String profileId,
  ) {
    return ChartNotifierProvider(
      profileId,
    );
  }

  @override
  ChartNotifierProvider getProviderOverride(
    covariant ChartNotifierProvider provider,
  ) {
    return call(
      provider.profileId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'chartNotifierProvider';
}

/// Fetches (or triggers) a chart for a given profile ID.
/// The profile ID is passed as argument to allow per-profile caching.
///
/// Copied from [ChartNotifier].
class ChartNotifierProvider extends AutoDisposeAsyncNotifierProviderImpl<
    ChartNotifier, BirthChartFacts?> {
  /// Fetches (or triggers) a chart for a given profile ID.
  /// The profile ID is passed as argument to allow per-profile caching.
  ///
  /// Copied from [ChartNotifier].
  ChartNotifierProvider(
    String profileId,
  ) : this._internal(
          () => ChartNotifier()..profileId = profileId,
          from: chartNotifierProvider,
          name: r'chartNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$chartNotifierHash,
          dependencies: ChartNotifierFamily._dependencies,
          allTransitiveDependencies:
              ChartNotifierFamily._allTransitiveDependencies,
          profileId: profileId,
        );

  ChartNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.profileId,
  }) : super.internal();

  final String profileId;

  @override
  FutureOr<BirthChartFacts?> runNotifierBuild(
    covariant ChartNotifier notifier,
  ) {
    return notifier.build(
      profileId,
    );
  }

  @override
  Override overrideWith(ChartNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: ChartNotifierProvider._internal(
        () => create()..profileId = profileId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        profileId: profileId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<ChartNotifier, BirthChartFacts?>
      createElement() {
    return _ChartNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChartNotifierProvider && other.profileId == profileId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, profileId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ChartNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<BirthChartFacts?> {
  /// The parameter `profileId` of this provider.
  String get profileId;
}

class _ChartNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<ChartNotifier,
        BirthChartFacts?> with ChartNotifierRef {
  _ChartNotifierProviderElement(super.provider);

  @override
  String get profileId => (origin as ChartNotifierProvider).profileId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
