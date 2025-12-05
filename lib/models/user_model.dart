import 'package:cloud_firestore/cloud_firestore.dart';

/// Base profile information for all users
class ProfileData {
  final String firstName;
  final String lastName;
  final String phone;
  final String? profileImageUrl;

  const ProfileData({
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.profileImageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
    };
  }

  factory ProfileData.fromMap(Map<String, dynamic> map) {
    return ProfileData(
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      phone: map['phone'] ?? '',
      profileImageUrl: map['profileImageUrl'],
    );
  }

  ProfileData copyWith({
    String? firstName,
    String? lastName,
    String? phone,
    String? profileImageUrl,
  }) {
    return ProfileData(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}

/// Address information for assigners
class AddressData {
  final String address;
  final String city;
  final String state;
  final String zipCode;

  const AddressData({
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
  });

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
    };
  }

  factory AddressData.fromMap(Map<String, dynamic> map) {
    return AddressData(
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      zipCode: map['zipCode'] ?? '',
    );
  }
}

/// Scheduler-specific profile information
class SchedulerProfile {
  final String type; // 'Athletic Director' | 'Coach' | 'Assigner'

  // Athletic Director fields
  final String? schoolName;
  final String? schoolAddress;

  // Team name field - used differently by each type:
  // Athletic Director: full team name (e.g., "Edwardsville Tigers")
  // Coach: team name (e.g., "JV Basketball")
  final String? teamName;

  // Coach fields
  final String? sport;
  final String? levelOfCompetition;
  final String? gender;
  final String? defaultLocationId;

  // Assigner fields
  final String? organizationName;
  final AddressData? homeAddress;

  const SchedulerProfile({
    required this.type,
    // Athletic Director fields
    this.schoolName,
    this.schoolAddress,
    // Team name field (shared)
    this.teamName,
    // Coach fields
    this.sport,
    this.levelOfCompetition,
    this.gender,
    this.defaultLocationId,
    // Assigner fields
    this.organizationName,
    this.homeAddress,
  });

  /// Factory constructor for Athletic Director
  factory SchedulerProfile.athleticDirector({
    required String schoolName,
    required String teamName,
    required String schoolAddress,
  }) {
    return SchedulerProfile(
      type: 'Athletic Director',
      schoolName: schoolName,
      teamName: teamName,
      schoolAddress: schoolAddress,
    );
  }

  /// Factory constructor for Coach
  factory SchedulerProfile.coach({
    required String teamName,
    required String sport,
    required String levelOfCompetition,
    required String gender,
    required String defaultLocationId,
  }) {
    return SchedulerProfile(
      type: 'Coach',
      teamName: teamName,
      sport: sport,
      levelOfCompetition: levelOfCompetition,
      gender: gender,
      defaultLocationId: defaultLocationId,
    );
  }

  /// Factory constructor for Assigner
  factory SchedulerProfile.assigner({
    required String organizationName,
    required String sport,
    required AddressData homeAddress,
  }) {
    return SchedulerProfile(
      type: 'Assigner',
      organizationName: organizationName,
      sport: sport,
      homeAddress: homeAddress,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'type': type,
    };

    // Athletic Director fields
    if (schoolName != null) map['schoolName'] = schoolName;
    if (schoolAddress != null) map['schoolAddress'] = schoolAddress;

    // Team name field (used by both Athletic Directors and Coaches)
    if (teamName != null) map['teamName'] = teamName;

    // Coach fields
    if (sport != null) map['sport'] = sport;
    if (levelOfCompetition != null)
      map['levelOfCompetition'] = levelOfCompetition;
    if (gender != null) map['gender'] = gender;
    if (defaultLocationId != null) map['defaultLocationId'] = defaultLocationId;

    // Assigner fields
    if (organizationName != null) map['organizationName'] = organizationName;
    if (homeAddress != null) map['homeAddress'] = homeAddress!.toMap();

    return map;
  }

  factory SchedulerProfile.fromMap(Map<String, dynamic> map) {
    final type = map['type'] ?? '';

    return SchedulerProfile(
      type: type,
      // Athletic Director fields
      schoolName: map['schoolName'],
      schoolAddress: map['schoolAddress'],
      // Team name (both Athletic Directors and Coaches)
      teamName: map['teamName'],
      // Coach fields
      sport: map['sport'],
      levelOfCompetition: map['levelOfCompetition'],
      gender: map['gender'],
      defaultLocationId: map['defaultLocationId'],
      // Assigner fields
      organizationName: map['organizationName'],
      homeAddress: map['homeAddress'] != null
          ? AddressData.fromMap(map['homeAddress'])
          : null,
    );
  }

  /// Get home team name for game creation
  String? getHomeTeamName() {
    switch (type) {
      case 'Athletic Director':
        return teamName; // Athletic Directors enter full team name
      case 'Coach':
        return teamName;
      case 'Assigner':
        return null; // Assigners select home team per game
    }
    return null;
  }

  /// Get pre-filled sport for game creation (Coach and Assigner only)
  String? getPrefilledSport() {
    return sport;
  }

  /// Get pre-filled level for game creation (Coach only)
  String? getPrefilledLevel() {
    return type == 'Coach' ? levelOfCompetition : null;
  }

  /// Get pre-filled gender for game creation (Coach only)
  String? getPrefilledGender() {
    return type == 'Coach' ? gender : null;
  }
}

/// Official-specific profile information
class OfficialProfile {
  final String? address;
  final String city;
  final String state;
  final int? experienceYears;
  final String? certificationLevel;
  final String availabilityStatus; // 'available' | 'busy' | 'unavailable'
  final double followThroughRate; // 0.0-100.0
  final int totalAcceptedGames;
  final int totalBackedOutGames;
  final String? bio;
  final Map<String, Map<String, dynamic>>?
      sportsData; // Detailed sports data with experience, certification, competition levels
  final double? ratePerGame; // Minimum rate per game in dollars
  final int? maxTravelDistance; // Maximum travel distance in miles
  final int schedulerEndorsements; // Number of endorsements from schedulers
  final int officialEndorsements; // Number of endorsements from other officials
  final bool showCareerStats; // Whether to show career stats to other users

  const OfficialProfile({
    this.address,
    required this.city,
    required this.state,
    this.experienceYears,
    this.certificationLevel,
    this.availabilityStatus = 'available',
    this.followThroughRate = 100.0,
    this.totalAcceptedGames = 0,
    this.totalBackedOutGames = 0,
    this.bio,
    this.sportsData,
    this.ratePerGame,
    this.maxTravelDistance,
    this.schedulerEndorsements = 0,
    this.officialEndorsements = 0,
    this.showCareerStats = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'city': city,
      'state': state,
      'experienceYears': experienceYears,
      'certificationLevel': certificationLevel,
      'availabilityStatus': availabilityStatus,
      'followThroughRate': followThroughRate,
      'totalAcceptedGames': totalAcceptedGames,
      'totalBackedOutGames': totalBackedOutGames,
      'bio': bio,
      'sportsData': sportsData,
      'ratePerGame': ratePerGame,
      'maxTravelDistance': maxTravelDistance,
      'schedulerEndorsements': schedulerEndorsements,
      'officialEndorsements': officialEndorsements,
      'showCareerStats': showCareerStats,
    };
  }

  factory OfficialProfile.fromMap(Map<String, dynamic> map) {
    return OfficialProfile(
      address: map['address'],
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      experienceYears: map['experienceYears']?.toInt(),
      certificationLevel: map['certificationLevel'],
      availabilityStatus: map['availabilityStatus'] ?? 'available',
      followThroughRate: (map['followThroughRate'] ?? 100.0).toDouble(),
      totalAcceptedGames: (map['totalAcceptedGames'] ?? 0).toInt(),
      totalBackedOutGames: (map['totalBackedOutGames'] ?? 0).toInt(),
      bio: map['bio'],
      sportsData: map['sportsData'] != null
          ? Map<String, Map<String, dynamic>>.from(map['sportsData'])
          : null,
      ratePerGame: map['ratePerGame']?.toDouble(),
      maxTravelDistance: map['maxTravelDistance']?.toInt(),
      schedulerEndorsements: (map['schedulerEndorsements'] ?? 0).toInt(),
      officialEndorsements: (map['officialEndorsements'] ?? 0).toInt(),
      showCareerStats: map['showCareerStats'] ?? true,
    );
  }
}

/// Main User model for Firestore
class UserModel {
  final String id; // Firebase Auth UID
  final String email;
  final String role; // 'scheduler' | 'official'
  final bool isAdmin; // Admin privileges for app management
  final ProfileData profile;
  final SchedulerProfile? schedulerProfile;
  final OfficialProfile? officialProfile;
  final List<String> fcmTokens;
  final List<String> dismissedGameIds; // Games dismissed by officials
  final List<String> pendingGameIds; // Games officials have expressed interest in
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.role,
    this.isAdmin = false,
    required this.profile,
    this.schedulerProfile,
    this.officialProfile,
    this.fcmTokens = const [],
    this.dismissedGameIds = const [],
    this.pendingGameIds = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory constructor for Scheduler
  factory UserModel.scheduler({
    required String id,
    required String email,
    required ProfileData profile,
    required SchedulerProfile schedulerProfile,
    bool isAdmin = false,
    List<String> fcmTokens = const [],
    List<String> dismissedGameIds = const [],
    List<String> pendingGameIds = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return UserModel(
      id: id,
      email: email,
      role: 'scheduler',
      isAdmin: isAdmin,
      profile: profile,
      schedulerProfile: schedulerProfile,
      fcmTokens: fcmTokens,
      dismissedGameIds: dismissedGameIds,
      pendingGameIds: pendingGameIds,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }

  /// Factory constructor for Official
  factory UserModel.official({
    required String id,
    required String email,
    required ProfileData profile,
    required OfficialProfile officialProfile,
    bool isAdmin = false,
    List<String> fcmTokens = const [],
    List<String> dismissedGameIds = const [],
    List<String> pendingGameIds = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return UserModel(
      id: id,
      email: email,
      role: 'official',
      isAdmin: isAdmin,
      profile: profile,
      officialProfile: officialProfile,
      fcmTokens: fcmTokens,
      dismissedGameIds: dismissedGameIds,
      pendingGameIds: pendingGameIds,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'email': email,
      'role': role,
      'isAdmin': isAdmin,
      'profile': profile.toMap(),
      'fcmTokens': fcmTokens,
      'dismissedGameIds': dismissedGameIds,
      'pendingGameIds': pendingGameIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };

    if (schedulerProfile != null) {
      map['schedulerProfile'] = schedulerProfile!.toMap();
    }

    if (officialProfile != null) {
      map['officialProfile'] = officialProfile!.toMap();
    }

    return map;
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? '',
      isAdmin: map['isAdmin'] ?? false,
      profile: ProfileData.fromMap(map['profile'] ?? {}),
      schedulerProfile: map['schedulerProfile'] != null
          ? SchedulerProfile.fromMap(map['schedulerProfile'])
          : null,
      officialProfile: map['officialProfile'] != null
          ? OfficialProfile.fromMap(map['officialProfile'])
          : null,
      fcmTokens: List<String>.from(map['fcmTokens'] ?? []),
      dismissedGameIds: List<String>.from(map['dismissedGameIds'] ?? []),
      pendingGameIds: List<String>.from(map['pendingGameIds'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Factory constructor from Firestore DocumentSnapshot
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap(data);
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? role,
    bool? isAdmin,
    ProfileData? profile,
    SchedulerProfile? schedulerProfile,
    OfficialProfile? officialProfile,
    List<String>? fcmTokens,
    List<String>? dismissedGameIds,
    List<String>? pendingGameIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      isAdmin: isAdmin ?? this.isAdmin,
      profile: profile ?? this.profile,
      schedulerProfile: schedulerProfile ?? this.schedulerProfile,
      officialProfile: officialProfile ?? this.officialProfile,
      fcmTokens: fcmTokens ?? this.fcmTokens,
      dismissedGameIds: dismissedGameIds ?? this.dismissedGameIds,
      pendingGameIds: pendingGameIds ?? this.pendingGameIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Get full name for display
  String get fullName => '${profile.firstName} ${profile.lastName}';

  /// Check if user is a scheduler
  bool get isScheduler => role == 'scheduler';

  /// Check if user is an official
  bool get isOfficial => role == 'official';

  /// Get scheduler type (AD, Coach, Assigner) or null
  String? get schedulerType => schedulerProfile?.type;
}
