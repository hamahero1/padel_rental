import 'package:cloud_firestore/cloud_firestore.dart';

/// A user saved in the "users" collection.
/// role is either 'player' or 'owner' (facility owner).
class AppUser {
  final String uid;
  final String name;
  final String email;
  final String role;
  final DateTime? birthdate;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.birthdate,
  });

  bool get isOwner => role == 'owner';

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppUser(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'player',
      birthdate: (data['birthdate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'role': role,
        'birthdate': birthdate == null ? null : Timestamp.fromDate(birthdate!),
        'createdAt': FieldValue.serverTimestamp(),
      };
}
