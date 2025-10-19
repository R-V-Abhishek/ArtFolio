import 'package:cloud_firestore/cloud_firestore.dart';

// Artist schema - extension of User
class Artist {

  Artist({
    required this.userId,
    required this.artForms,
    required this.portfolioUrls,
    required this.reels,
    required this.followers,
    required this.following,
  });

  factory Artist.fromMap(Map<String, dynamic> map) => Artist(
      userId: map['userId'] ?? '',
      artForms: List<String>.from(map['artForms'] ?? []),
      portfolioUrls: List<String>.from(map['portfolioUrls'] ?? []),
      reels: List<String>.from(map['reels'] ?? []),
      followers: List<String>.from(map['followers'] ?? []),
      following: List<String>.from(map['following'] ?? []),
    );

  factory Artist.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data()! as Map<String, dynamic>;
    return Artist.fromMap(data);
  }
  final String userId;
  final List<String> artForms;
  final List<String> portfolioUrls;
  final List<String> reels;
  final List<String> followers;
  final List<String> following;

  Map<String, dynamic> toMap() => {
      'userId': userId,
      'artForms': artForms,
      'portfolioUrls': portfolioUrls,
      'reels': reels,
      'followers': followers,
      'following': following,
    };
}

// Audience schema - extension of User
class Audience {

  Audience({
    required this.userId,
    required this.likedContent,
    required this.followingArtists,
    required this.sponsorApplications,
  });

  factory Audience.fromMap(Map<String, dynamic> map) => Audience(
      userId: map['userId'] ?? '',
      likedContent: List<String>.from(map['likedContent'] ?? []),
      followingArtists: List<String>.from(map['followingArtists'] ?? []),
      sponsorApplications: List<String>.from(map['sponsorApplications'] ?? []),
    );

  factory Audience.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data()! as Map<String, dynamic>;
    return Audience.fromMap(data);
  }
  final String userId;
  final List<String> likedContent;
  final List<String> followingArtists;
  final List<String> sponsorApplications;

  Map<String, dynamic> toMap() => {
      'userId': userId,
      'likedContent': likedContent,
      'followingArtists': followingArtists,
      'sponsorApplications': sponsorApplications,
    };
}

// Sponsor schema - extension of User
class Sponsor {

  Sponsor({
    required this.userId,
    required this.companyName,
    required this.budgetRange,
    required this.sponsoredPrograms,
    required this.openToApplications,
  });

  factory Sponsor.fromMap(Map<String, dynamic> map) => Sponsor(
      userId: map['userId'] ?? '',
      companyName: map['companyName'] ?? '',
      budgetRange: Map<String, double>.from(map['budgetRange'] ?? {}),
      sponsoredPrograms: List<String>.from(map['sponsoredPrograms'] ?? []),
      openToApplications: map['openToApplications'] ?? false,
    );

  factory Sponsor.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data()! as Map<String, dynamic>;
    return Sponsor.fromMap(data);
  }
  final String userId;
  final String companyName;
  final Map<String, double> budgetRange; // min, max
  final List<String> sponsoredPrograms;
  final bool openToApplications;

  Map<String, dynamic> toMap() => {
      'userId': userId,
      'companyName': companyName,
      'budgetRange': budgetRange,
      'sponsoredPrograms': sponsoredPrograms,
      'openToApplications': openToApplications,
    };
}

// Organisation schema - extension of User
class Organisation {

  Organisation({
    required this.userId,
    required this.orgName,
    required this.childOrganisations,
    required this.hostedPrograms,
    required this.sponsorPartners,
  });

  factory Organisation.fromMap(Map<String, dynamic> map) => Organisation(
      userId: map['userId'] ?? '',
      orgName: map['orgName'] ?? '',
      childOrganisations: List<String>.from(map['childOrganisations'] ?? []),
      hostedPrograms: List<String>.from(map['hostedPrograms'] ?? []),
      sponsorPartners: List<String>.from(map['sponsorPartners'] ?? []),
    );

  factory Organisation.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data()! as Map<String, dynamic>;
    return Organisation.fromMap(data);
  }
  final String userId;
  final String orgName;
  final List<String> childOrganisations;
  final List<String> hostedPrograms;
  final List<String> sponsorPartners;

  Map<String, dynamic> toMap() => {
      'userId': userId,
      'orgName': orgName,
      'childOrganisations': childOrganisations,
      'hostedPrograms': hostedPrograms,
      'sponsorPartners': sponsorPartners,
    };
}
