enum UserRole { manager, loader, pending }

class AppUser {
  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final String ppo;
  final String? telegramId;
  final String? photoUrl;

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.ppo = '33701',
    this.telegramId,
    this.photoUrl,
  });

  factory AppUser.fromMap(Map<String, dynamic> data, String id) {
    UserRole mappedRole;
    if (data['role'] == 'manager') {
      mappedRole = UserRole.manager;
    } else if (data['role'] == 'loader') {
      mappedRole = UserRole.loader;
    } else {
      mappedRole = UserRole.pending;
    }

    return AppUser(
      uid: id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: mappedRole,
      ppo: data['ppo'] ?? '33701',
      telegramId: data['telegramId'],
      photoUrl: data['photo_url'], // ✅ Map from Firestore
    );
  }
}
