import '../models/game_template_model.dart';

class GameService {
  // Mock data for development - replace with actual Firebase/database calls

  Future<List<GameTemplateModel>> getTemplates() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      GameTemplateModel(
        id: '1',
        name: 'Varsity Basketball Game',
        sport: 'Basketball',
        includeSport: true,
        description:
            'Standard varsity basketball game template with 3 officials',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        includeScheduleName: true,
        includeDate: true,
        includeTime: true,
        includeLocation: true,
        includeOpponent: true,
        includeOfficialsRequired: true,
        officialsRequired: 3,
        includeGameFee: true,
        gameFee: '150.00',
      ),
      GameTemplateModel(
        id: '2',
        name: 'JV Soccer Match',
        sport: 'Soccer',
        includeSport: true,
        description: 'Junior varsity soccer game template with 2 officials',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        includeScheduleName: true,
        includeDate: true,
        includeTime: true,
        includeLocation: true,
        includeOpponent: true,
        includeOfficialsRequired: true,
        officialsRequired: 2,
        includeGameFee: true,
        gameFee: '100.00',
      ),
      GameTemplateModel(
        id: '3',
        name: 'Football Championship',
        sport: 'Football',
        includeSport: true,
        description: 'Championship football game template with 7 officials',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        includeScheduleName: true,
        includeDate: true,
        includeTime: true,
        includeLocation: true,
        includeOpponent: true,
        includeLevelOfCompetition: true,
        levelOfCompetition: 'Championship',
        includeOfficialsRequired: true,
        officialsRequired: 7,
        includeGameFee: true,
        gameFee: '300.00',
      ),
    ];
  }

  Future<bool> deleteTemplate(String templateId) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 300));

    // In a real implementation, this would make an API call to delete the template
    // For now, just return success
    return true;
  }

  Future<List<Map<String, dynamic>>> getSchedules() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      {
        'name': 'Varsity Basketball Schedule',
        'id': 1,
        'sport': 'Basketball',
      },
      {
        'name': 'JV Basketball Schedule',
        'id': 2,
        'sport': 'Basketball',
      },
      {
        'name': 'Varsity Soccer Schedule',
        'id': 3,
        'sport': 'Soccer',
      },
      {
        'name': 'Football Schedule',
        'id': 4,
        'sport': 'Football',
      },
    ];
  }

  Future<List<Map<String, dynamic>>> getGames() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      {
        'id': '1',
        'scheduleName': 'Varsity Basketball',
        'sport': 'Basketball',
        'date': DateTime.now().add(const Duration(days: 7)),
        'time': '7:00 PM',
        'opponent': 'Lincoln High',
        'location': 'Home Gym',
        'officialsRequired': 3,
        'officialsHired': 2,
        'isAway': false,
      },
      {
        'id': '2',
        'scheduleName': 'JV Soccer',
        'sport': 'Soccer',
        'date': DateTime.now().add(const Duration(days: 3)),
        'time': '4:30 PM',
        'opponent': 'Washington Prep',
        'location': 'Away Field',
        'officialsRequired': 2,
        'officialsHired': 0,
        'isAway': true,
      },
    ];
  }
}
