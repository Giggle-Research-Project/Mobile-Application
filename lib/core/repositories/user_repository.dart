import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/user_model.dart';

part 'user_repository.g.dart';

@Riverpod(keepAlive: true)
UserRepository userRepository(UserRepositoryRef ref) {
  return UserRepository(FirebaseFirestore.instance);
}

class UserRepository {
  final FirebaseFirestore _firestore;
  late final CollectionReference<Map<String, dynamic>> _usersCollection;

  UserRepository(this._firestore) {
    _usersCollection = _firestore.collection('users');
  }

  Future<void> createUser(AppUser user) async {
    await _usersCollection.doc(user.uid).set(user.toMap());
  }

  Future<AppUser?> getUser(String uid) async {
    final doc = await _usersCollection.doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc);
  }

  Stream<AppUser?> userStream(String uid) {
    return _usersCollection
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? AppUser.fromFirestore(doc) : null);
  }

  Future<void> updateUser(AppUser user) async {
    final userData = user.toMap();

    await _usersCollection.doc(user.uid).update(userData);
  }

  Future<void> deleteUser(String uid) async {
    await _usersCollection.doc(uid).delete();
  }

  Stream<List<AppUser>> getUsersByRole(String role) {
    return _usersCollection.where('userRole', isEqualTo: role).snapshots().map(
        (snapshot) =>
            snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList());
  }

  Stream<List<AppUser>> getActiveUsers() {
    final fiveMinutesAgo = DateTime.now()
        .subtract(const Duration(minutes: 5))
        .millisecondsSinceEpoch;

    return _usersCollection
        .where('lastSeen', isGreaterThan: fiveMinutesAgo)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList());
  }

  Future<void> batchUpdate({
    required List<String> userIds,
    required Map<String, dynamic> data,
  }) async {
    final batch = _firestore.batch();

    for (final uid in userIds) {
      final userRef = _usersCollection.doc(uid);
      batch.update(userRef, data);
    }

    await batch.commit();
  }

  Stream<List<AppUser>> searchUsers(String searchTerm) {
    return _usersCollection
        .where('displayName', isGreaterThanOrEqualTo: searchTerm)
        .where('displayName', isLessThanOrEqualTo: searchTerm + '\uf8ff')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList());
  }
}
