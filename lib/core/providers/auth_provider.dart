import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
Stream<firebase.User?> authStateChanges(AuthStateChangesRef ref) {
  return FirebaseAuth.instance.authStateChanges();
}

@riverpod
class Auth extends _$Auth {
  late final AuthRepository _authRepository;
  late final UserRepository _userRepository;

  @override
  Future<AppUser?> build() async {
    _authRepository = ref.watch(authRepositoryProvider);
    _userRepository = ref.watch(userRepositoryProvider);

    ref.listen(authStateChangesProvider, (previous, next) {
      _handleAuthStateChange(next.value);
    });

    return _getCurrentUser();
  }

  Future<AppUser?> signInWithGoogle() async {
    state = const AsyncValue.loading();

    try {
      final firebaseUser = await _authRepository.signInWithGoogle();
      if (firebaseUser == null) {
        state = const AsyncValue.data(null);
        return null;
      }

      final userDoc = await _userRepository.getUser(firebaseUser.uid);
      AppUser user;

      if (userDoc == null) {
        user = AppUser.fromFirebaseUser(firebaseUser);
        await _userRepository.createUser(user);
      } else {
        user = userDoc;
      }

      state = AsyncValue.data(user);
      return user;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<AppUser?> _getCurrentUser() async {
    final firebaseUser = _authRepository.getCurrentUser();
    if (firebaseUser == null) return null;

    try {
      final userDoc = await _userRepository.getUser(firebaseUser.uid);

      if (userDoc != null) {
        return userDoc;
      } else {
        final user = AppUser.fromFirebaseUser(firebaseUser);
        await _userRepository.createUser(user);
        return user;
      }
    } catch (error) {
      rethrow;
    }
  }

  void _handleAuthStateChange(firebase.User? firebaseUser) async {
    if (firebaseUser == null) {
      state = const AsyncValue.data(null);
      return;
    }

    state = const AsyncValue.loading();

    try {
      final user = await _getCurrentUser();
      state = AsyncValue.data(user);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();

    try {
      await _authRepository.signInWithEmailAndPassword(email, password);
      final user = await _getCurrentUser();
      state = AsyncValue.data(user);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> signUp(
    String email,
    String password, {
    required String displayName,
  }) async {
    state = const AsyncValue.loading();

    try {
      final firebaseUser = await _authRepository.createUserWithEmailAndPassword(
        email,
        password,
      );

      final user = AppUser.fromFirebaseUser(firebaseUser).copyWith(
        displayName: displayName,
      );
      await _userRepository.createUser(user);

      state = AsyncValue.data(user);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
    state = const AsyncValue.data(null);
  }
}
