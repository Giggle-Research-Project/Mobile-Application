// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userStateHash() => r'44945038c55f36f774ebcc95f31d553213c3a05e';

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

abstract class _$UserState
    extends BuildlessAutoDisposeStreamNotifier<AppUser?> {
  late final String userId;

  Stream<AppUser?> build(
    String userId,
  );
}

/// See also [UserState].
@ProviderFor(UserState)
const userStateProvider = UserStateFamily();

/// See also [UserState].
class UserStateFamily extends Family<AsyncValue<AppUser?>> {
  /// See also [UserState].
  const UserStateFamily();

  /// See also [UserState].
  UserStateProvider call(
    String userId,
  ) {
    return UserStateProvider(
      userId,
    );
  }

  @override
  UserStateProvider getProviderOverride(
    covariant UserStateProvider provider,
  ) {
    return call(
      provider.userId,
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
  String? get name => r'userStateProvider';
}

/// See also [UserState].
class UserStateProvider
    extends AutoDisposeStreamNotifierProviderImpl<UserState, AppUser?> {
  /// See also [UserState].
  UserStateProvider(
    String userId,
  ) : this._internal(
          () => UserState()..userId = userId,
          from: userStateProvider,
          name: r'userStateProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$userStateHash,
          dependencies: UserStateFamily._dependencies,
          allTransitiveDependencies: UserStateFamily._allTransitiveDependencies,
          userId: userId,
        );

  UserStateProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  Stream<AppUser?> runNotifierBuild(
    covariant UserState notifier,
  ) {
    return notifier.build(
      userId,
    );
  }

  @override
  Override overrideWith(UserState Function() create) {
    return ProviderOverride(
      origin: this,
      override: UserStateProvider._internal(
        () => create()..userId = userId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeStreamNotifierProviderElement<UserState, AppUser?>
      createElement() {
    return _UserStateProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserStateProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin UserStateRef on AutoDisposeStreamNotifierProviderRef<AppUser?> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _UserStateProviderElement
    extends AutoDisposeStreamNotifierProviderElement<UserState, AppUser?>
    with UserStateRef {
  _UserStateProviderElement(super.provider);

  @override
  String get userId => (origin as UserStateProvider).userId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
