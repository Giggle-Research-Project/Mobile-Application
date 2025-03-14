import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final bool isEmailVerified;
  final int createdAt;
  final int lastSeen;

  const AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    required this.isEmailVerified,
    required this.createdAt,
    required this.lastSeen,
  });

  factory AppUser.fromFirebaseUser(firebase.User firebaseUser) {
    return AppUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email,
      displayName: firebaseUser.displayName,
      photoURL: firebaseUser.photoURL,
      isEmailVerified: firebaseUser.emailVerified,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      lastSeen: DateTime.now().millisecondsSinceEpoch,
    );
  }

  // In AppUser.fromFirestore
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    print('DEBUG: Raw Firestore data: $data');

    final user = AppUser(
      uid: doc.id,
      email: data['email'],
      displayName: data['displayName'],
      photoURL: data['photoURL'],
      isEmailVerified: data['isEmailVerified'] ?? false,
      createdAt: data['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      lastSeen: data['lastSeen'] ?? DateTime.now().millisecondsSinceEpoch,
    );
    return user;
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'isEmailVerified': isEmailVerified,
      'createdAt': createdAt,
      'lastSeen': lastSeen,
    };
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    bool? isEmailVerified,
    int? createdAt,
    int? lastSeen,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  AppUser copyWithUpdatedLastSeen() {
    return copyWith(
      lastSeen: DateTime.now().millisecondsSinceEpoch,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          email == other.email &&
          displayName == other.displayName &&
          photoURL == other.photoURL &&
          isEmailVerified == other.isEmailVerified &&
          createdAt == other.createdAt &&
          lastSeen == other.lastSeen;

  @override
  int get hashCode =>
      uid.hashCode ^
      email.hashCode ^
      displayName.hashCode ^
      photoURL.hashCode ^
      isEmailVerified.hashCode ^
      createdAt.hashCode ^
      lastSeen.hashCode;
}
