import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import '../models/post.dart';
import '../models/user.dart';
import '../models/role_models.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  CollectionReference get _usersCollection => _db.collection('users');
  CollectionReference get _artistsCollection => _db.collection('artists');
  CollectionReference get _audiencesCollection => _db.collection('audiences');
  CollectionReference get _sponsorsCollection => _db.collection('sponsors');
  CollectionReference get _organisationsCollection => _db.collection('organisations');
  CollectionReference get _postsCollection => _db.collection('posts');

  // ===== USER MANAGEMENT =====
  
  // Create base user profile
  Future<void> createUser(User user) async {
    try {
      await _usersCollection.doc(user.id).set(user.toMap());
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  // Get user by ID
  Future<User?> getUser(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      return doc.exists ? User.fromSnapshot(doc) : null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  // Update user profile
  Future<void> updateUser(User user) async {
    try {
      await _usersCollection.doc(user.id).update(
        user.copyWith(updatedAt: DateTime.now()).toMap(),
      );
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  // ===== ROLE-SPECIFIC DATA MANAGEMENT =====

  // Create artist profile
  Future<void> createArtist(Artist artist) async {
    try {
      await _artistsCollection.doc(artist.userId).set(artist.toMap());
    } catch (e) {
      throw Exception('Failed to create artist profile: $e');
    }
  }

  // Get artist profile
  Future<Artist?> getArtist(String userId) async {
    try {
      final doc = await _artistsCollection.doc(userId).get();
      return doc.exists ? Artist.fromSnapshot(doc) : null;
    } catch (e) {
      throw Exception('Failed to get artist profile: $e');
    }
  }

  // Create audience profile
  Future<void> createAudience(Audience audience) async {
    try {
      await _audiencesCollection.doc(audience.userId).set(audience.toMap());
    } catch (e) {
      throw Exception('Failed to create audience profile: $e');
    }
  }

  // Get audience profile
  Future<Audience?> getAudience(String userId) async {
    try {
      final doc = await _audiencesCollection.doc(userId).get();
      return doc.exists ? Audience.fromSnapshot(doc) : null;
    } catch (e) {
      throw Exception('Failed to get audience profile: $e');
    }
  }

  // Create sponsor profile
  Future<void> createSponsor(Sponsor sponsor) async {
    try {
      await _sponsorsCollection.doc(sponsor.userId).set(sponsor.toMap());
    } catch (e) {
      throw Exception('Failed to create sponsor profile: $e');
    }
  }

  // Get sponsor profile
  Future<Sponsor?> getSponsor(String userId) async {
    try {
      final doc = await _sponsorsCollection.doc(userId).get();
      return doc.exists ? Sponsor.fromSnapshot(doc) : null;
    } catch (e) {
      throw Exception('Failed to get sponsor profile: $e');
    }
  }

  // Create organisation profile
  Future<void> createOrganisation(Organisation organisation) async {
    try {
      await _organisationsCollection.doc(organisation.userId).set(organisation.toMap());
    } catch (e) {
      throw Exception('Failed to create organisation profile: $e');
    }
  }

  // Get organisation profile
  Future<Organisation?> getOrganisation(String userId) async {
    try {
      final doc = await _organisationsCollection.doc(userId).get();
      return doc.exists ? Organisation.fromSnapshot(doc) : null;
    } catch (e) {
      throw Exception('Failed to get organisation profile: $e');
    }
  }

  // ===== COMBINED USER DATA =====

  // Get complete user data (base + role-specific)
  Future<Map<String, dynamic>?> getCompleteUserData(String userId) async {
    try {
      final user = await getUser(userId);
      if (user == null) return null;

      Map<String, dynamic> userData = {
        'user': user.toMap(),
      };

      // Get role-specific data based on user role
      switch (user.role) {
        case UserRole.artist:
          final artist = await getArtist(userId);
          if (artist != null) userData['artist'] = artist.toMap();
          break;
        case UserRole.audience:
          final audience = await getAudience(userId);
          if (audience != null) userData['audience'] = audience.toMap();
          break;
        case UserRole.sponsor:
          final sponsor = await getSponsor(userId);
          if (sponsor != null) userData['sponsor'] = sponsor.toMap();
          break;
        case UserRole.organisation:
          final organisation = await getOrganisation(userId);
          if (organisation != null) userData['organisation'] = organisation.toMap();
          break;
      }

      return userData;
    } catch (e) {
      throw Exception('Failed to get complete user data: $e');
    }
  }

  // Create a new post
  Future<void> createPost(Post post) async {
    try {
      await _postsCollection.add(post.toMap());
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

  // Get posts by user ID
  Future<List<Post>> getUserPosts(String userId) async {
    try {
      final querySnapshot = await _postsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Post.fromSnapshot(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user posts: $e');
    }
  }

  // Get all posts
  Future<List<Post>> getAllPosts() async {
    try {
      final querySnapshot = await _postsCollection
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Post.fromSnapshot(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get posts: $e');
    }
  }

  // ===== ENHANCED POST OPERATIONS =====

  // Get posts by type
  Future<List<Post>> getPostsByType(PostType type) async {
    try {
      final querySnapshot = await _postsCollection
          .where('type', isEqualTo: type.name)
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Post.fromSnapshot(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get posts by type: $e');
    }
  }

  // Get trending posts (by engagement)
  Future<List<Post>> getTrendingPosts({int limit = 20}) async {
    try {
      final querySnapshot = await _postsCollection
          .where('likesCount', isGreaterThan: 10)
          .orderBy('likesCount', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => Post.fromSnapshot(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get trending posts: $e');
    }
  }

  // Get posts by skill tags
  Future<List<Post>> getPostsBySkill(String skill) async {
    try {
      final querySnapshot = await _postsCollection
          .where('skills', arrayContains: skill)
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Post.fromSnapshot(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get posts by skill: $e');
    }
  }

  // Like/unlike a post
  Future<void> togglePostLike(String postId, String userId) async {
    try {
      final postRef = _postsCollection.doc(postId);
      final postSnapshot = await postRef.get();
      
      if (!postSnapshot.exists) {
        throw Exception('Post not found');
      }

      final postData = postSnapshot.data() as Map<String, dynamic>;
      final likedBy = List<String>.from(postData['likedBy'] ?? []);
      final currentLikes = postData['likesCount'] ?? 0;

      if (likedBy.contains(userId)) {
        // Unlike the post
        likedBy.remove(userId);
        await postRef.update({
          'likedBy': likedBy,
          'likesCount': currentLikes - 1,
          'lastEngagement': FieldValue.serverTimestamp(),
        });
      } else {
        // Like the post
        likedBy.add(userId);
        await postRef.update({
          'likedBy': likedBy,
          'likesCount': currentLikes + 1,
          'lastEngagement': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Failed to toggle post like: $e');
    }
  }

  // Increment post views
  Future<void> incrementPostViews(String postId) async {
    try {
      final postRef = _postsCollection.doc(postId);
      await postRef.update({
        'viewsCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to increment post views: $e');
    }
  }

  // Get posts for feed (mixed content, optimized for engagement)
  Future<List<Post>> getFeedPosts({int limit = 20, String? lastPostId}) async {
    try {
      Query query = _postsCollection
          .where('visibility', isEqualTo: 'public')
          .orderBy('timestamp', descending: true);

      if (lastPostId != null) {
        final lastDoc = await _postsCollection.doc(lastPostId).get();
        query = query.startAfterDocument(lastDoc);
      }

      final querySnapshot = await query.limit(limit).get();

      return querySnapshot.docs
          .map((doc) => Post.fromSnapshot(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get feed posts: $e');
    }
  }

  // Search posts by caption/description
  Future<List<Post>> searchPosts(String searchTerm) async {
    try {
      // Note: For production, consider using Algolia or similar for better search
      final querySnapshot = await _postsCollection
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Post.fromSnapshot(doc))
          .where((post) => 
            post.caption.toLowerCase().contains(searchTerm.toLowerCase()) ||
            (post.description?.toLowerCase().contains(searchTerm.toLowerCase()) ?? false) ||
            post.skills.any((skill) => skill.toLowerCase().contains(searchTerm.toLowerCase())) ||
            post.tags.any((tag) => tag.toLowerCase().contains(searchTerm.toLowerCase()))
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to search posts: $e');
    }
  }

  // ===== END ENHANCED POST OPERATIONS =====

  // Seed mock data
  Future<void> seedMockData() async {
    try {
      // Check if data already exists
      final existingPosts = await _postsCollection.limit(1).get();
      if (existingPosts.docs.isNotEmpty) {
        return;
      }

      // Create mock users
      await _createMockUsers();
      
      // Create mock posts
      await _createMockPosts();
      
    } catch (e) {
      throw Exception('Failed to seed mock data: $e');
    }
  }

  // Private method to create mock users with new schema
  Future<void> _createMockUsers() async {
    final now = DateTime.now();
    
    // Create Artist user
    final artistUser = User(
      id: 'artist1',
      username: 'alice_painter',
      email: 'alice@example.com',
      fullName: 'Alice Painter',
      profilePictureUrl: 'https://placekitten.com/200/200',
      bio: 'Exploring textures and colors on canvas.',
      role: UserRole.artist,
      createdAt: DateTime.parse('2025-09-18T12:00:00Z'),
      updatedAt: now,
    );
    
    final artistProfile = Artist(
      userId: 'artist1',
      artForms: ['OilPainting', 'Sketching'],
      portfolioUrls: [],
      reels: [],
      followers: [],
      following: [],
    );

    await createUser(artistUser);
    await createArtist(artistProfile);

    // Create Audience user
    final audienceUser = User(
      id: 'audience1',
      username: 'bob_viewer',
      email: 'bob@example.com',
      fullName: 'Bob Viewer',
      profilePictureUrl: 'https://placekitten.com/201/201',
      bio: 'Loves attending creative festivals and exhibitions.',
      role: UserRole.audience,
      createdAt: DateTime.parse('2025-09-18T12:10:00Z'),
      updatedAt: now,
    );

    final audienceProfile = Audience(
      userId: 'audience1',
      likedContent: [],
      followingArtists: [],
      sponsorApplications: [],
    );

    await createUser(audienceUser);
    await createAudience(audienceProfile);

    // Create Sponsor user
    final sponsorUser = User(
      id: 'sponsor1',
      username: 'clara_sponsor',
      email: 'clara@example.com',
      fullName: 'Clara Sponsor',
      profilePictureUrl: 'https://placekitten.com/202/202',
      bio: 'Supporting local talent and creative initiatives.',
      role: UserRole.sponsor,
      createdAt: DateTime.parse('2025-09-18T12:20:00Z'),
      updatedAt: now,
    );

    final sponsorProfile = Sponsor(
      userId: 'sponsor1',
      companyName: 'CreativeFunds Inc.',
      budgetRange: {'min': 50000.0, 'max': 200000.0},
      sponsoredPrograms: [],
      openToApplications: true,
    );

    await createUser(sponsorUser);
    await createSponsor(sponsorProfile);
  }

  // Private method to create enhanced mock posts
  Future<void> _createMockPosts() async {
    final now = DateTime.now();
    
    final mockPosts = [
      // Image post with high engagement
      Post(
        id: '',
        userId: 'artist1',
        type: PostType.image,
        mediaUrl: 'https://placekitten.com/400/600',
        caption: 'Latest oil painting - exploring textures and light. Really excited about how this landscape turned out! 🎨✨',
        description: 'This piece took me 3 weeks to complete. I wanted to capture the golden hour light hitting the mountains. Used traditional oil painting techniques with modern color theory.',
        skills: ['OilPainting', 'Landscape', 'ColorTheory'],
        tags: ['#OilPainting', '#Landscape', '#Art', '#GoldenHour', '#Mountains'],
        timestamp: now.subtract(const Duration(hours: 2)),
        visibility: PostVisibility.public,
        likesCount: 47,
        commentsCount: 12,
        sharesCount: 8,
        viewsCount: 156,
        likedBy: ['audience1', 'sponsor1'],
        location: PostLocation(
          city: 'Mumbai',
          state: 'Maharashtra',
          country: 'India',
          latitude: 19.0760,
          longitude: 72.8777,
        ),
        aspectRatio: 0.67, // 400/600
        allowComments: true,
        allowSharing: true,
        lastEngagement: now.subtract(const Duration(minutes: 15)),
      ),
      
      // Reel with collaboration
      Post(
        id: '',
        userId: 'artist1',
        type: PostType.reel,
        mediaUrl: 'https://sample-videos.com/zip/10/mp4/480p/mp4-file_sample.mp4',
        thumbnailUrl: 'https://placekitten.com/600/400',
        caption: 'Quick sketch from life drawing session today. Love capturing the essence of a moment with just a few lines. ✏️',
        description: 'Collaborated with @local_art_studio for this live sketching session. Amazing energy and fellow artists!',
        skills: ['Sketching', 'LifeDrawing', 'QuickStudy'],
        tags: ['#Sketching', '#LifeDrawing', '#Art', '#LiveSession', '#Collaboration'],
        timestamp: now.subtract(const Duration(days: 1)),
        visibility: PostVisibility.public,
        likesCount: 32,
        commentsCount: 8,
        sharesCount: 5,
        viewsCount: 89,
        likedBy: ['audience1'],
        duration: 45, // 45 seconds
        aspectRatio: 1.5, // 600/400
        collaboration: CollaborationInfo(
          collaboratorIds: ['studio123'],
          isSponsored: false,
        ),
        allowComments: true,
        allowSharing: true,
        lastEngagement: now.subtract(const Duration(hours: 3)),
      ),
      
      // Sponsored gallery post
      Post(
        id: '',
        userId: 'artist1',
        type: PostType.gallery,
        mediaUrls: [
          'https://placekitten.com/500/500',
          'https://placekitten.com/500/501',
          'https://placekitten.com/500/502',
        ],
        caption: 'Portrait study series in oils. Been practicing capturing personality and emotion through brushwork. 🎭',
        description: 'This series represents my exploration of human emotion through traditional oil painting. Each portrait tells a different story. Thanks to @CreativeFunds for supporting this project!',
        skills: ['OilPainting', 'Portrait', 'EmotionalExpression'],
        tags: ['#OilPainting', '#Portrait', '#Study', '#Sponsored', '#ArtSeries'],
        timestamp: now.subtract(const Duration(days: 3)),
        visibility: PostVisibility.public,
        likesCount: 78,
        commentsCount: 24,
        sharesCount: 15,
        viewsCount: 234,
        likedBy: ['audience1', 'sponsor1', 'artist2', 'artist3'],
        collaboration: CollaborationInfo(
          collaboratorIds: [],
          sponsorId: 'sponsor1',
          isSponsored: true,
          sponsorshipDetails: 'Art supplies sponsored by CreativeFunds Inc.',
        ),
        aspectRatio: 1.0, // Square images
        allowComments: true,
        allowSharing: true,
        isPinned: true, // Artist pinned this post
        demographics: {
          'artists': 45,
          'audience': 35,
          'sponsors': 20,
        },
        lastEngagement: now.subtract(const Duration(minutes: 45)),
      ),
      
      // Idea post (text-heavy)
      Post(
        id: '',
        userId: 'artist1',
        type: PostType.idea,
        caption: '💡 Idea: What if we created a community art space where artists can showcase work AND teach workshops?',
        description: 'I\'ve been thinking about how we can make art more accessible to everyone. Imagine a space where:\n\n• Artists display their work\n• Conduct workshops for all skill levels\n• Collaborate on community projects\n• Host art therapy sessions\n\nWould love to hear your thoughts! Who would be interested in something like this?',
        skills: ['CommunityBuilding', 'ArtEducation', 'SocialImpact'],
        tags: ['#ArtCommunity', '#Ideas', '#Collaboration', '#ArtEducation', '#SocialImpact'],
        timestamp: now.subtract(const Duration(hours: 18)),
        visibility: PostVisibility.public,
        likesCount: 62,
        commentsCount: 35,
        sharesCount: 18,
        viewsCount: 189,
        likedBy: ['audience1', 'sponsor1', 'artist4', 'artist5'],
        allowComments: true,
        allowSharing: true,
        lastEngagement: now.subtract(const Duration(hours: 2)),
      ),
      
      // Video tutorial
      Post(
        id: '',
        userId: 'artist1',
        type: PostType.video,
        mediaUrl: 'https://sample-videos.com/zip/10/mp4/720p/mp4-file_sample.mp4',
        thumbnailUrl: 'https://placekitten.com/640/360',
        caption: '🎨 Oil Painting Tutorial: Creating depth with layering techniques',
        description: 'In this 10-minute tutorial, I show you my favorite layering technique for creating depth in oil paintings. Perfect for intermediate artists looking to improve their landscape work.',
        skills: ['OilPainting', 'Teaching', 'Tutorials', 'Layering'],
        tags: ['#Tutorial', '#OilPainting', '#ArtEducation', '#Techniques', '#LearnArt'],
        timestamp: now.subtract(const Duration(days: 5)),
        visibility: PostVisibility.public,
        likesCount: 156,
        commentsCount: 43,
        sharesCount: 67,
        viewsCount: 892,
        likedBy: ['audience1', 'sponsor1', 'artist6', 'artist7', 'student1'],
        duration: 600, // 10 minutes
        aspectRatio: 1.78, // 16:9
        allowComments: true,
        allowSharing: true,
        demographics: {
          'beginners': 60,
          'intermediate': 30,
          'advanced': 10,
        },
        lastEngagement: now.subtract(const Duration(minutes: 30)),
      ),
    ];

    for (final post in mockPosts) {
      await _postsCollection.add(post.toMap());
    }
  }

  // Helper method to get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // Check if current user has a profile
  Future<bool> hasUserProfile() async {
    final userId = getCurrentUserId();
    if (userId == null) return false;
    
    final profile = await getUser(userId);
    return profile != null;
  }
}