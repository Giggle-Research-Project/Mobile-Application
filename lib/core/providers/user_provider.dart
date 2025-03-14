import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';

part 'user_provider.g.dart';

@riverpod
class UserState extends _$UserState {
  late final UserRepository _userRepository;

  @override
  Stream<AppUser?> build(String userId) {
    _userRepository = ref.watch(userRepositoryProvider);
    return _userRepository.userStream(userId);
  }

  Future<void> updateLastSeen() async {
    if (state.value == null) return;

    try {
      final updatedUser = state.value!.copyWithUpdatedLastSeen();
      await _userRepository.updateUser(updatedUser);
    } catch (error) {
      print('Error updating last seen: $error');
    }
  }

  Future<void> updateDisplayName(String displayName) async {
    if (state.value == null) return;

    try {
      final updatedUser = state.value!.copyWith(displayName: displayName);
      await _userRepository.updateUser(updatedUser);
    } catch (error) {
      print('Error updating display name: $error');
    }
  }

  Future<void> updatePhotoURL(String photoURL) async {
    if (state.value == null) return;

    try {
      final updatedUser = state.value!.copyWith(photoURL: photoURL);
      await _userRepository.updateUser(updatedUser);
    } catch (error) {
      print('Error updating photo URL: $error');
    }
  }
}
