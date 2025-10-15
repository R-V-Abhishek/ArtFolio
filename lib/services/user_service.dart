import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/role_models.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create user document in Firestore
  static Future<void> createUser({
    required String uid,
    required String email,
    required String fullName,
    required UserRole role,
    String? profilePictureUrl,
  }) async {
    // Derive a robust username and fallback full name so profile doesn't look empty
    String username = _generateUsername(fullName);
    final emailLocal = email.contains('@') ? email.split('@').first : '';
    if (username.trim().isEmpty) {
      username = emailLocal.isNotEmpty ? emailLocal : 'user${uid.substring(0, 6)}';
    }
    final resolvedFullName = fullName.trim().isNotEmpty
        ? fullName
        : (emailLocal.isNotEmpty ? emailLocal : username);

    final user = User(
      id: uid,
      username: username,
      email: email,
      fullName: resolvedFullName,
      profilePictureUrl: profilePictureUrl ?? '',
      bio: '',
      role: role,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Create user document
    await _firestore.collection('users').doc(uid).set(user.toMap());

    // Create role-specific document
    await _createRoleSpecificDocument(uid, role);
  }

  static Future<void> _createRoleSpecificDocument(
    String uid,
    UserRole role,
  ) async {
    switch (role) {
      case UserRole.artist:
        final artist = Artist(
          userId: uid,
          artForms: [],
          portfolioUrls: [],
          reels: [],
          followers: [],
          following: [],
        );
        await _firestore.collection('artists').doc(uid).set(artist.toMap());
        break;
      case UserRole.audience:
        final audience = Audience(
          userId: uid,
          likedContent: [],
          followingArtists: [],
          sponsorApplications: [],
        );
        await _firestore.collection('audiences').doc(uid).set(audience.toMap());
        break;
      case UserRole.sponsor:
        final sponsor = Sponsor(
          userId: uid,
          companyName: '',
          budgetRange: {},
          sponsoredPrograms: [],
          openToApplications: false,
        );
        await _firestore.collection('sponsors').doc(uid).set(sponsor.toMap());
        break;
      case UserRole.organisation:
        final organisation = Organisation(
          userId: uid,
          orgName: '',
          childOrganisations: [],
          hostedPrograms: [],
          sponsorPartners: [],
        );
        await _firestore
            .collection('organisations')
            .doc(uid)
            .set(organisation.toMap());
        break;
    }
  }

  static String _generateUsername(String fullName) {
    return fullName.toLowerCase().replaceAll(' ', '_');
  }

  static Future<User?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return User.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
