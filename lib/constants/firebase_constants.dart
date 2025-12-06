/// Firebase collection names and constants
/// Centralizes all Firebase-related constants to avoid duplication and typos

class FirebaseCollections {
  static const String users = 'users';
  static const String games = 'games';
  static const String locations = 'locations';
  static const String officialLists = 'official_lists';
  static const String schedules = 'schedules';
  static const String gameTemplates = 'game_templates';
}

/// Common field names used across collections
class FirebaseFields {
  // User fields
  static const String userId = 'id';
  static const String email = 'email';
  static const String role = 'role';
  static const String profile = 'profile';
  static const String schedulerProfile = 'schedulerProfile';
  static const String officialProfile = 'officialProfile';

  // Game fields
  static const String gameId = 'id';
  static const String scheduleId = 'scheduleId';
  static const String scheduleName = 'scheduleName';
  static const String sport = 'sport';
  static const String date = 'date';
  static const String time = 'time';
  static const String location = 'location';
  static const String opponent = 'opponent';
  static const String officialsRequired = 'officialsRequired';
  static const String gameFee = 'gameFee';
  static const String gender = 'gender';
  static const String levelOfCompetition = 'levelOfCompetition';
  static const String hireAutomatically = 'hireAutomatically';
  static const String method = 'method';
  static const String selectedOfficials = 'selectedOfficials';
  static const String selectedCrews = 'selectedCrews';
  static const String selectedCrew = 'selectedCrew';
  static const String selectedListName = 'selectedListName';
  static const String selectedLists = 'selectedLists';
  static const String officialsHired = 'officialsHired';
  static const String status = 'status';
  static const String createdAt = 'createdAt';
  static const String isAway = 'isAway';
  static const String homeTeam = 'homeTeam';
  static const String awayTeam = 'awayTeam';

  // Location fields
  static const String address = 'address';
  static const String city = 'city';
  static const String state = 'state';
  static const String zipCode = 'zipCode';
  static const String createdBy = 'createdBy';
  static const String homeTeamName = 'homeTeamName';

  // Official list fields
  static const String name = 'name';
  static const String officials = 'officials';
  static const String officialCount = 'official_count';
  static const String updatedAt = 'updatedAt';
}

/// Common values and enums
class FirebaseValues {
  static const String statusPublished = 'Published';
  static const String statusUnpublished = 'Unpublished';

  static const String roleScheduler = 'scheduler';
  static const String roleOfficial = 'official';

  static const String schedulerTypeAthleticDirector = 'Athletic Director';
  static const String schedulerTypeCoach = 'Coach';
  static const String schedulerTypeAssigner = 'Assigner';
}

/// Navigation route constants
class AppRoutes {
  static const String home = '/';
  static const String roleSelection = '/role-selection';
  static const String basicProfile = '/basic-profile';
  static const String schedulerType = '/scheduler-type';
  static const String athleticDirectorProfile = '/athletic-director-profile';
  static const String athleticDirectorHome = '/athletic-director-home';
  static const String adHome = '/ad-home';
  static const String coachHome = '/coach-home';
  static const String coachProfile = '/coach-profile';
  static const String assignerProfile = '/assigner-profile';
  static const String assignerHome = '/assigner-home';
  static const String officialProfile = '/official-profile';
  static const String officialStep2 = '/official-step2';
  static const String officialStep3 = '/official-step3';
  static const String officialStep4 = '/official-step4';
  static const String gameTemplates = '/game-templates';
  static const String selectSchedule = '/select-schedule';
  static const String selectSport = '/select-sport';
  static const String nameSchedule = '/name-schedule';
  static const String dateTime = '/date-time';
  static const String chooseLocation = '/choose-location';
  static const String addNewLocation = '/add-new-location';
  static const String additionalGameInfo = '/additional-game-info';
  static const String additionalGameInfoCondensed =
      '/additional-game-info-condensed';
  static const String selectOfficials = '/select-officials';
  static const String listsOfOfficials = '/lists-of-officials';
  static const String nameList = '/name-list';
  static const String populateRoster = '/populate-roster';
  static const String filterSettings = '/filter-settings';
  static const String settings = '/settings';
  static const String reviewList = '/review-list';
  static const String reviewGameInfo = '/review-game-info';
}
