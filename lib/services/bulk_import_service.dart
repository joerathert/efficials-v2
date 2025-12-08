import 'dart:io';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_service.dart';
import 'auth_service.dart';
import 'location_service.dart';
import 'official_list_service.dart';
import 'game_service.dart';
import '../constants/firebase_constants.dart';

/// Configuration for bulk import wizard
class BulkImportConfig {
  final int numberOfSchedules;
  final String sport;
  final Map<String, bool> globalSettings;
  final Map<String, dynamic> globalValues;
  final List<ScheduleConfig> scheduleConfigs;

  BulkImportConfig({
    required this.numberOfSchedules,
    required this.sport,
    required this.globalSettings,
    required this.globalValues,
    required this.scheduleConfigs,
  });

  Map<String, dynamic> toJson() => {
        'numberOfSchedules': numberOfSchedules,
        'sport': sport,
        'globalSettings': globalSettings,
        'globalValues': globalValues,
        'scheduleConfigs': scheduleConfigs.map((s) => s.toJson()).toList(),
      };

  factory BulkImportConfig.fromJson(Map<String, dynamic> json) {
    return BulkImportConfig(
      numberOfSchedules: json['numberOfSchedules'] as int,
      sport: json['sport'] as String,
      globalSettings: Map<String, bool>.from(json['globalSettings'] as Map),
      globalValues: Map<String, dynamic>.from(json['globalValues'] as Map),
      scheduleConfigs: (json['scheduleConfigs'] as List)
          .map((s) => ScheduleConfig.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Configuration for each schedule in bulk import
class ScheduleConfig {
  String scheduleName;
  String teamName;
  int numberOfGames;
  Map<String, dynamic> settings;

  ScheduleConfig({
    required this.scheduleName,
    required this.teamName,
    required this.numberOfGames,
    Map<String, dynamic>? settings,
  }) : settings = settings ?? {};

  Map<String, dynamic> toJson() => {
        'scheduleName': scheduleName,
        'teamName': teamName,
        'numberOfGames': numberOfGames,
        'settings': settings,
      };

  factory ScheduleConfig.fromJson(Map<String, dynamic> json) {
    return ScheduleConfig(
      scheduleName: json['scheduleName'] as String,
      teamName: json['teamName'] as String,
      numberOfGames: json['numberOfGames'] as int,
      settings: Map<String, dynamic>.from(json['settings'] as Map? ?? {}),
    );
  }
}

/// Parsed game data from Excel
class ParsedGame {
  final String scheduleName;
  final String teamName;
  final DateTime? date;
  final TimeOfDay? time;
  final String? opponent;
  final String? location;
  final bool isAway;
  final String? gender;
  final String? competitionLevel;
  final int? officialsRequired;
  final String? gameFee;
  final String? method;
  final bool? hireAutomatically;
  final String? linkGroup;
  final String? sport;

  // Method-specific fields
  final String? officialsList;
  final List<Map<String, dynamic>>? multipleLists;
  final String? crewList;
  final String? specificCrewName;

  // Validation
  final List<String> errors;
  final int rowNumber;
  final String sheetName;

  ParsedGame({
    required this.scheduleName,
    required this.teamName,
    this.date,
    this.time,
    this.opponent,
    this.location,
    this.isAway = false,
    this.gender,
    this.competitionLevel,
    this.officialsRequired,
    this.gameFee,
    this.method,
    this.hireAutomatically,
    this.linkGroup,
    this.sport,
    this.officialsList,
    this.multipleLists,
    this.crewList,
    this.specificCrewName,
    this.errors = const [],
    required this.rowNumber,
    required this.sheetName,
  });

  bool get isValid => errors.isEmpty;

  /// Convert to game data map for creating in Firestore
  Map<String, dynamic> toGameData(String schedulerId, String? scheduleId) {
    return {
      'scheduleName': scheduleName,
      'homeTeam': teamName,
      'date': date?.toIso8601String(),
      'time': time != null
          ? '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}'
          : null,
      'opponent': opponent,
      'location': location,
      'isAway': isAway,
      'gender': gender,
      'levelOfCompetition': competitionLevel,
      'officialsRequired': officialsRequired ?? 2,
      'officialsHired': 0,
      'gameFee': gameFee,
      'method': _mapMethodToInternal(method),
      'hireAutomatically': hireAutomatically ?? false,
      'linkGroup': linkGroup,
      'sport': sport,
      'status': 'Unpublished',
      'schedulerId': schedulerId,
      'scheduleId': scheduleId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      // Method-specific
      if (method == 'Single List' && officialsList != null)
        'selectedListName': officialsList,
      if (method == 'Multiple Lists' && multipleLists != null)
        'selectedLists': multipleLists,
      if (method == 'Hire a Crew') ...{
        if (crewList != null) 'selectedCrewListName': crewList,
        if (specificCrewName != null) 'selectedCrewName': specificCrewName,
      },
    };
  }

  String? _mapMethodToInternal(String? method) {
    switch (method) {
      case 'Single List':
        return 'use_list';
      case 'Multiple Lists':
        return 'advanced';
      case 'Hire a Crew':
        return 'hire_crew';
      default:
        return 'standard';
    }
  }
}

/// Service for bulk importing games via Excel
class BulkImportService extends BaseService {
  // Singleton pattern
  static final BulkImportService _instance = BulkImportService._internal();
  BulkImportService._internal();
  factory BulkImportService() => _instance;

  final LocationService _locationService = LocationService();
  final OfficialListService _officialListService = OfficialListService();
  final GameService _gameService = GameService();
  final AuthService _authService = AuthService();

  // Valid options for dropdowns
  static const List<String> genderOptions = [
    'Boys',
    'Girls',
    'Co-ed',
    'Men',
    'Women'
  ];

  static const List<String> competitionLevels = [
    '6U',
    '7U',
    '8U',
    '9U',
    '10U',
    '11U',
    '12U',
    '13U',
    '14U',
    '15U',
    '16U',
    '17U',
    '18U',
    'Grade School',
    'Middle School',
    'Underclass',
    'JV',
    'Varsity',
    'College',
    'Adult',
  ];

  static const List<String> methodOptions = [
    'Single List',
    'Multiple Lists',
    'Hire a Crew',
  ];

  static const List<String> yesNoOptions = ['Yes', 'No'];

  /// Check if prerequisites are met for bulk import
  Future<Map<String, dynamic>> checkPrerequisites() async {
    try {
      final locations = await _locationService.getLocations();
      final officialLists = await _officialListService.fetchOfficialLists();
      // TODO: Add crew list check when crew service is implemented
      final crewLists = <Map<String, dynamic>>[];

      return {
        'locationsReady': locations.isNotEmpty,
        'locationCount': locations.length,
        'locations': locations,
        'officialsListsReady': officialLists.isNotEmpty,
        'officialsListCount': officialLists.length,
        'officialsLists': officialLists,
        'crewListsReady': crewLists.isNotEmpty,
        'crewListCount': crewLists.length,
        'crewLists': crewLists,
        'canProceed':
            locations.isNotEmpty && (officialLists.isNotEmpty || crewLists.isNotEmpty),
      };
    } catch (e) {
      debugPrint('❌ BulkImportService: Error checking prerequisites: $e');
      return {
        'locationsReady': false,
        'locationCount': 0,
        'locations': <Map<String, dynamic>>[],
        'officialsListsReady': false,
        'officialsListCount': 0,
        'officialsLists': <Map<String, dynamic>>[],
        'crewListsReady': false,
        'crewListCount': 0,
        'crewLists': <Map<String, dynamic>>[],
        'canProceed': false,
        'error': e.toString(),
      };
    }
  }

  /// Generate Excel template based on configuration
  Future<String?> generateExcelTemplate(BulkImportConfig config) async {
    try {
      final excel = Excel.createExcel();

      // Get reference data
      final locations = await _locationService.getLocations();
      final officialLists = await _officialListService.fetchOfficialLists();
      // TODO: Add crew lists when implemented
      final crewLists = <Map<String, dynamic>>[];

      // Create Instructions sheet
      _createInstructionsSheet(excel);

      // Create Reference sheet with valid values
      _createReferenceSheet(excel, locations, officialLists, crewLists);

      // Create a sheet for each schedule
      for (int i = 0; i < config.scheduleConfigs.length; i++) {
        final scheduleConfig = config.scheduleConfigs[i];
        _createScheduleSheet(excel, scheduleConfig, config, i + 1);
      }

      // Remove default Sheet1
      if (excel.tables.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // Save file
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'BulkGameImport_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);

      final bytes = excel.encode();
      if (bytes != null) {
        await file.writeAsBytes(bytes);
        debugPrint('✅ BulkImportService: Excel file saved to $filePath');
        return filePath;
      }

      return null;
    } catch (e) {
      debugPrint('❌ BulkImportService: Error generating Excel: $e');
      return null;
    }
  }

  void _createInstructionsSheet(Excel excel) {
    final sheet = excel['Instructions'];

    int row = 0;

    // Title
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value =
        TextCellValue('BULK GAME IMPORT - INSTRUCTIONS');
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .cellStyle = CellStyle(bold: true, fontSize: 16);
    row += 2;

    final instructions = [
      '1. Each tab represents one schedule (team). Fill in the game details for each schedule.',
      '2. Required fields: Date and Opponent. Other fields may be pre-filled based on your wizard settings.',
      '3. Date format: Use MM/DD/YYYY format (e.g., 12/25/2024).',
      '4. Time format: Use HH:MM AM/PM format (e.g., 7:00 PM).',
      '5. For valid values, check the Reference sheet - copy/paste to avoid typos.',
      '6. Link Group: Use the same value (A, B, C, etc.) for games that should be linked together.',
      '   - Linked games will be offered/claimed together as a package.',
      '   - Officials hired for linked games work ALL games in the group.',
      '   - Maximum 5 games can be linked together.',
      '7. Away Game: Set to "Yes" for away games (location will show as "Away Game").',
      '8. Once complete, save the file and upload it back to the app.',
      '',
      'NOTE: Excel dropdowns are not supported. Please manually enter valid values from the Reference sheet.',
    ];

    for (final instruction in instructions) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value =
          TextCellValue(instruction);
      row++;
    }
  }

  void _createReferenceSheet(
    Excel excel,
    List<Map<String, dynamic>> locations,
    List<Map<String, dynamic>> officialLists,
    List<Map<String, dynamic>> crewLists,
  ) {
    final sheet = excel['Reference'];

    int col = 0;

    // Locations
    _writeReferenceColumn(
        sheet, col, 'VALID LOCATIONS', locations.map((l) => l['name'] as String).toList());
    col += 2;

    // Gender options
    _writeReferenceColumn(sheet, col, 'GENDER OPTIONS', genderOptions);
    col += 2;

    // Competition levels
    _writeReferenceColumn(sheet, col, 'COMPETITION LEVELS', competitionLevels);
    col += 2;

    // Officials methods
    _writeReferenceColumn(sheet, col, 'OFFICIALS METHODS', methodOptions);
    col += 2;

    // Yes/No
    _writeReferenceColumn(sheet, col, 'YES/NO OPTIONS', yesNoOptions);
    col += 2;

    // Officials lists
    _writeReferenceColumn(sheet, col, 'OFFICIALS LISTS',
        officialLists.map((l) => l['name'] as String).toList());
    col += 2;

    // Crew lists
    if (crewLists.isNotEmpty) {
      _writeReferenceColumn(sheet, col, 'CREW LISTS',
          crewLists.map((l) => l['name'] as String).toList());
      col += 2;
    }

    // Link group examples
    _writeReferenceColumn(
        sheet, col, 'LINK GROUP EXAMPLES', ['A', 'B', 'C', 'D', 'E', '(leave blank for no linking)']);
  }

  void _writeReferenceColumn(Sheet sheet, int col, String header, List<String> values) {
    int row = 0;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row)).value =
        TextCellValue(header);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row)).cellStyle =
        CellStyle(bold: true);
    row++;

    for (final value in values) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row)).value =
          TextCellValue(value);
      row++;
    }
  }

  void _createScheduleSheet(
    Excel excel,
    ScheduleConfig scheduleConfig,
    BulkImportConfig config,
    int scheduleNumber,
  ) {
    // Use schedule name for sheet, truncate if too long
    String sheetName = scheduleConfig.scheduleName;
    if (sheetName.length > 30) {
      sheetName = sheetName.substring(0, 30);
    }
    // Remove invalid characters
    sheetName = sheetName.replaceAll(RegExp(r'[:\\/?*\[\]]'), '_');
    if (sheetName.isEmpty) {
      sheetName = 'Schedule $scheduleNumber';
    }

    final sheet = excel[sheetName];

    int row = 0;

    // Schedule header info
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value =
        TextCellValue('Schedule: ${scheduleConfig.scheduleName}');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).cellStyle =
        CellStyle(bold: true, fontSize: 14);
    row++;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value =
        TextCellValue('Team: ${scheduleConfig.teamName}');
    row++;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value =
        TextCellValue('Sport: ${config.sport}');
    row += 2;

    // Table headers
    final headers = _getTableHeaders(config);
    for (int col = 0; col < headers.length; col++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row)).value =
          TextCellValue(headers[col]);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row)).cellStyle =
          CellStyle(bold: true);
    }
    row++;

    // Pre-fill game rows
    final headerRow = row - 1;
    for (int gameRow = 0; gameRow < scheduleConfig.numberOfGames; gameRow++) {
      _createPreFilledGameRow(
          sheet, headers, row + gameRow, headerRow, config, scheduleConfig);
    }

    // Add instructions at the bottom
    row += scheduleConfig.numberOfGames + 1;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value =
        TextCellValue('👆 Fill in Date and Opponent for each game above.');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).cellStyle =
        CellStyle(fontSize: 10);
  }

  List<String> _getTableHeaders(BulkImportConfig config) {
    final headers = <String>['Date', 'Opponent'];

    // Add columns for settings that are NOT set globally
    if (!(config.globalSettings['time'] ?? false)) {
      headers.add('Time');
    }
    if (!(config.globalSettings['location'] ?? false)) {
      headers.add('Location');
    }

    headers.add('Away Game');
    headers.add('Link Group');

    if (!(config.globalSettings['gender'] ?? false)) {
      headers.add('Gender');
    }
    if (!(config.globalSettings['competitionLevel'] ?? false)) {
      headers.add('Competition Level');
    }
    if (!(config.globalSettings['officialsRequired'] ?? false)) {
      headers.add('Officials Required');
    }
    if (!(config.globalSettings['gameFee'] ?? false)) {
      headers.add('Game Fee');
    }
    if (!(config.globalSettings['method'] ?? false)) {
      headers.add('Officials Method');
      // Add method-specific columns
      headers.add('Officials List');
      headers.add('List 1');
      headers.add('List 1 Min');
      headers.add('List 1 Max');
      headers.add('List 2');
      headers.add('List 2 Min');
      headers.add('List 2 Max');
      headers.add('List 3');
      headers.add('List 3 Min');
      headers.add('List 3 Max');
      headers.add('Crew List');
      headers.add('Crew Name');
    }
    if (!(config.globalSettings['hireAutomatically'] ?? false)) {
      headers.add('Hire Automatically');
    }

    return headers;
  }

  void _createPreFilledGameRow(
    Sheet sheet,
    List<String> headers,
    int rowIndex,
    int headerRow,
    BulkImportConfig config,
    ScheduleConfig scheduleConfig,
  ) {
    for (int col = 0; col < headers.length; col++) {
      final header = headers[col];
      final cell =
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex));

      // Get value from global or schedule settings
      dynamic value;

      switch (header) {
        case 'Date':
        case 'Opponent':
        case 'Link Group':
          // Leave empty for user to fill
          break;
        case 'Time':
          if (config.globalSettings['time'] == true) {
            value = config.globalValues['time'];
          } else if (scheduleConfig.settings['time'] != null) {
            value = scheduleConfig.settings['time'];
          }
          break;
        case 'Location':
          if (config.globalSettings['location'] == true) {
            value = config.globalValues['location'];
          } else if (scheduleConfig.settings['location'] != null) {
            value = scheduleConfig.settings['location'];
          }
          break;
        case 'Away Game':
          value = 'No'; // Default to home games
          break;
        case 'Gender':
          if (config.globalSettings['gender'] == true) {
            value = config.globalValues['gender'];
          } else if (scheduleConfig.settings['gender'] != null) {
            value = scheduleConfig.settings['gender'];
          }
          break;
        case 'Competition Level':
          if (config.globalSettings['competitionLevel'] == true) {
            value = config.globalValues['competitionLevel'];
          } else if (scheduleConfig.settings['competitionLevel'] != null) {
            value = scheduleConfig.settings['competitionLevel'];
          }
          break;
        case 'Officials Required':
          if (config.globalSettings['officialsRequired'] == true) {
            value = config.globalValues['officialsRequired']?.toString();
          } else if (scheduleConfig.settings['officialsRequired'] != null) {
            value = scheduleConfig.settings['officialsRequired'].toString();
          }
          break;
        case 'Game Fee':
          if (config.globalSettings['gameFee'] == true) {
            value = config.globalValues['gameFee'];
          } else if (scheduleConfig.settings['gameFee'] != null) {
            value = scheduleConfig.settings['gameFee'];
          }
          break;
        case 'Officials Method':
          if (config.globalSettings['method'] == true) {
            value = config.globalValues['method'];
          } else if (scheduleConfig.settings['method'] != null) {
            value = scheduleConfig.settings['method'];
          }
          break;
        case 'Hire Automatically':
          if (config.globalSettings['hireAutomatically'] == true) {
            final hire = config.globalValues['hireAutomatically'] as bool? ?? false;
            value = hire ? 'Yes' : 'No';
          } else if (scheduleConfig.settings['hireAutomatically'] != null) {
            value = scheduleConfig.settings['hireAutomatically'] ? 'Yes' : 'No';
          }
          break;
        case 'Officials List':
          if (config.globalSettings['method'] == true &&
              config.globalValues['method'] == 'Single List') {
            value = config.globalValues['selectedList'];
          }
          break;
        // Multiple lists columns
        case 'List 1':
        case 'List 1 Min':
        case 'List 1 Max':
        case 'List 2':
        case 'List 2 Min':
        case 'List 2 Max':
        case 'List 3':
        case 'List 3 Min':
        case 'List 3 Max':
          // Pre-fill from global config if Multiple Lists is selected
          if (config.globalSettings['method'] == true &&
              config.globalValues['method'] == 'Multiple Lists') {
            final lists =
                config.globalValues['selectedMultipleLists'] as List<Map<String, dynamic>>?;
            if (lists != null) {
              final listIndex = header.contains('1')
                  ? 0
                  : header.contains('2')
                      ? 1
                      : 2;
              if (listIndex < lists.length) {
                if (header.startsWith('List ') && !header.contains('Min') && !header.contains('Max')) {
                  value = lists[listIndex]['list'];
                } else if (header.contains('Min')) {
                  value = lists[listIndex]['min']?.toString();
                } else if (header.contains('Max')) {
                  value = lists[listIndex]['max']?.toString();
                }
              }
            }
          }
          break;
        case 'Crew List':
          if (config.globalSettings['method'] == true &&
              config.globalValues['method'] == 'Hire a Crew') {
            value = config.globalValues['selectedCrewList'];
          }
          break;
        case 'Crew Name':
          // Leave empty - optional
          break;
      }

      if (value != null && value.toString().isNotEmpty) {
        cell.value = TextCellValue(value.toString());
      }
    }
  }

  /// Parse uploaded Excel file and return parsed games
  Future<List<ParsedGame>> parseExcelFile(String filePath, BulkImportConfig config) async {
    final parsedGames = <ParsedGame>[];

    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      // Get reference data for validation
      final locations = await _locationService.getLocations();
      final locationNames = locations.map((l) => l['name'] as String).toList();

      // Parse each schedule sheet
      for (final sheetName in excel.tables.keys) {
        if (sheetName == 'Instructions' || sheetName == 'Reference') continue;

        final sheet = excel.tables[sheetName];
        if (sheet == null) continue;

        // Find header row (starts with "Date")
        int headerRow = -1;
        List<String> headers = [];

        for (int row = 0; row < sheet.maxRows; row++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
          if (cell.value?.toString() == 'Date') {
            headerRow = row;
            // Get all headers
            for (int col = 0; col < sheet.maxColumns; col++) {
              final headerCell =
                  sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
              final headerValue = headerCell.value?.toString() ?? '';
              if (headerValue.isNotEmpty) {
                headers.add(headerValue);
              }
            }
            break;
          }
        }

        if (headerRow == -1) continue;

        // Extract schedule name and team name from sheet header
        String scheduleName = sheetName;
        String teamName = '';

        for (int row = 0; row < headerRow; row++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
          final cellValue = cell.value?.toString() ?? '';
          if (cellValue.startsWith('Schedule: ')) {
            scheduleName = cellValue.substring('Schedule: '.length);
          } else if (cellValue.startsWith('Team: ')) {
            teamName = cellValue.substring('Team: '.length);
          }
        }

        // Parse game rows
        for (int row = headerRow + 1; row < sheet.maxRows; row++) {
          final dateCell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
          final dateValue = dateCell.value?.toString().trim() ?? '';

          // Skip empty rows
          if (dateValue.isEmpty) continue;

          // Skip instruction rows
          if (dateValue.startsWith('👆') || dateValue.contains('Fill in')) continue;

          // Parse the row
          final gameData = <String, String>{};
          for (int col = 0; col < headers.length; col++) {
            final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
            gameData[headers[col]] = cell.value?.toString().trim() ?? '';
          }

          // Create ParsedGame
          final errors = <String>[];

          // Parse and validate date
          final date = _parseDate(gameData['Date'] ?? '');
          if (date == null && (gameData['Date']?.isNotEmpty ?? false)) {
            errors.add('Invalid date format');
          }

          // Parse time
          final timeStr = gameData['Time'] ?? '';
          debugPrint('⏰ BULK IMPORT: Parsing time for ${gameData['Opponent']}: "$timeStr"');
          final time = _parseTime(timeStr);
          debugPrint('⏰ BULK IMPORT: Parsed time result: $time');

          // Validate opponent
          final opponent = gameData['Opponent'];
          if (opponent == null || opponent.isEmpty) {
            errors.add('Opponent is required');
          }

          // Validate location
          final isAway =
              gameData['Away Game']?.toLowerCase() == 'yes' || gameData['Away Game'] == '1';
          String? location = gameData['Location'];
          if (!isAway && location != null && location.isNotEmpty) {
            if (!locationNames.contains(location)) {
              errors.add('Invalid location: "$location"');
            }
          }

          // Parse officials required
          int? officialsRequired;
          if (gameData['Officials Required']?.isNotEmpty ?? false) {
            officialsRequired = int.tryParse(gameData['Officials Required']!);
            if (officialsRequired == null || officialsRequired < 1 || officialsRequired > 9) {
              errors.add('Officials required must be 1-9');
            }
          }

          // Validate gender
          final gender = gameData['Gender'];
          if (gender != null && gender.isNotEmpty && !genderOptions.contains(gender)) {
            errors.add('Invalid gender: "$gender"');
          }

          // Validate competition level
          final level = gameData['Competition Level'];
          if (level != null && level.isNotEmpty && !competitionLevels.contains(level)) {
            errors.add('Invalid competition level: "$level"');
          }

          // Validate method
          final method = gameData['Officials Method'];
          if (method != null && method.isNotEmpty && !methodOptions.contains(method)) {
            errors.add('Invalid officials method: "$method"');
          }

          // Parse multiple lists if applicable
          List<Map<String, dynamic>>? multipleLists;
          if (method == 'Multiple Lists') {
            multipleLists = [];
            for (int i = 1; i <= 3; i++) {
              final listName = gameData['List $i'];
              if (listName != null && listName.isNotEmpty) {
                multipleLists.add({
                  'list': listName,
                  'min': int.tryParse(gameData['List $i Min'] ?? '0') ?? 0,
                  'max': int.tryParse(gameData['List $i Max'] ?? '1') ?? 1,
                });
              }
            }
          }

          // Use global values for missing fields
          final parsedGame = ParsedGame(
            scheduleName: scheduleName,
            teamName: teamName.isNotEmpty ? teamName : scheduleName,
            date: date,
            time: time ?? _parseTime(config.globalValues['time']?.toString() ?? ''),
            opponent: opponent,
            location: isAway ? 'Away Game' : (location ?? config.globalValues['location']?.toString()),
            isAway: isAway,
            gender: gender ?? config.globalValues['gender']?.toString(),
            competitionLevel: level ?? config.globalValues['competitionLevel']?.toString(),
            officialsRequired:
                officialsRequired ?? (config.globalValues['officialsRequired'] as int?),
            gameFee: gameData['Game Fee'] ?? config.globalValues['gameFee']?.toString(),
            method: method ?? config.globalValues['method']?.toString(),
            hireAutomatically: gameData['Hire Automatically']?.toLowerCase() == 'yes' ||
                (config.globalValues['hireAutomatically'] as bool? ?? false),
            linkGroup: gameData['Link Group'],
            sport: config.sport,
            officialsList: gameData['Officials List'] ?? config.globalValues['selectedList']?.toString(),
            multipleLists: multipleLists,
            crewList: gameData['Crew List'] ?? config.globalValues['selectedCrewList']?.toString(),
            specificCrewName: gameData['Crew Name'],
            errors: errors,
            rowNumber: row + 1,
            sheetName: sheetName,
          );

          parsedGames.add(parsedGame);
        }
      }

      return parsedGames;
    } catch (e) {
      debugPrint('❌ BulkImportService: Error parsing Excel: $e');
      return [];
    }
  }

  DateTime? _parseDate(String dateStr) {
    try {
      final clean = dateStr.trim();
      if (clean.isEmpty) return null;

      // Check for Excel serial date number
      final numericValue = double.tryParse(clean);
      if (numericValue != null) {
        final baseDate = DateTime(1900, 1, 1);
        final daysToAdd = numericValue.round() - 2;
        return baseDate.add(Duration(days: daysToAdd));
      }

      // Try MM/DD/YYYY
      if (RegExp(r'^\d{1,2}/\d{1,2}/\d{4}$').hasMatch(clean)) {
        final parts = clean.split('/');
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
      }

      // Try YYYY-MM-DD
      if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(clean)) {
        return DateTime.parse(clean.substring(0, 10));
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  TimeOfDay? _parseTime(String timeStr) {
    try {
      final clean = timeStr.trim().toLowerCase();
      if (clean.isEmpty) return null;

      // Handle "7:00 PM" format
      final amPmMatch = RegExp(r'^(\d{1,2}):(\d{2})\s*(am|pm)$').firstMatch(clean);
      if (amPmMatch != null) {
        int hour = int.parse(amPmMatch.group(1)!);
        final minute = int.parse(amPmMatch.group(2)!);
        final isPm = amPmMatch.group(3) == 'pm';

        if (isPm && hour != 12) hour += 12;
        if (!isPm && hour == 12) hour = 0;

        return TimeOfDay(hour: hour, minute: minute);
      }

      // Handle "19:00" or "19:00:00" format
      final hourMinMatch = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2})?$').firstMatch(clean);
      if (hourMinMatch != null) {
        return TimeOfDay(
          hour: int.parse(hourMinMatch.group(1)!),
          minute: int.parse(hourMinMatch.group(2)!),
        );
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Import parsed games to Firestore
  Future<Map<String, dynamic>> importGames(
    List<ParsedGame> games,
    BulkImportConfig config,
  ) async {
    int successCount = 0;
    int errorCount = 0;
    final errors = <String>[];

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        return {
          'success': false,
          'error': 'Not authenticated',
          'successCount': 0,
          'errorCount': games.length,
        };
      }

      // Group games by schedule
      final gamesBySchedule = <String, List<ParsedGame>>{};
      for (final game in games) {
        gamesBySchedule.putIfAbsent(game.scheduleName, () => []).add(game);
      }

      // Process each schedule
      for (final entry in gamesBySchedule.entries) {
        final scheduleName = entry.key;
        final scheduleGames = entry.value;

        // Get or create schedule
        String? scheduleId;
        late final String validatedScheduleId;
        try {
          // Check if schedule exists
          final existingSchedules = await _gameService.getSchedules();
          final existingSchedule = existingSchedules.firstWhere(
            (s) => s['name'] == scheduleName,
            orElse: () => <String, dynamic>{},
          );

          if (existingSchedule.isNotEmpty) {
            scheduleId = existingSchedule['id'] as String;
          } else {
            // Create new schedule
            final teamName = scheduleGames.first.teamName;
            final newSchedule = await _gameService.createSchedule(
              scheduleName,
              config.sport,
              homeTeamName: teamName,
            );
            scheduleId = newSchedule['id'] as String;
          }
        } catch (e) {
          debugPrint('❌ Error with schedule $scheduleName: $e');
          for (final game in scheduleGames) {
            errors.add('${game.sheetName} Row ${game.rowNumber}: Failed to create schedule');
            errorCount++;
          }
          continue;
        }

        // Group games by link group
        debugPrint('🔗 BULK IMPORT: Processing ${scheduleGames.length} games in schedule "${scheduleName}" for linking');
        final linkGroups = <String, List<ParsedGame>>{};
        final unlinkedGames = <ParsedGame>[];

        for (final game in scheduleGames) {
          debugPrint('🔗 BULK IMPORT: Game ${game.opponent} has linkGroup: "${game.linkGroup}"');
          if (game.linkGroup != null && game.linkGroup!.isNotEmpty) {
            linkGroups.putIfAbsent(game.linkGroup!, () => []).add(game);
          } else {
            unlinkedGames.add(game);
          }
        }
        debugPrint('🔗 BULK IMPORT: Found ${linkGroups.length} link groups: ${linkGroups.keys.toList()}');

        // Validate link groups (max 5 games)
        for (final entry in linkGroups.entries) {
          if (entry.value.length > 5) {
            for (final game in entry.value) {
              errors.add(
                  '${game.sheetName} Row ${game.rowNumber}: Link group "${entry.key}" has more than 5 games');
            }
          }
        }

        // Validate scheduleId before creating games
        if (scheduleId == null || scheduleId.isEmpty) {
          debugPrint('❌ BULK IMPORT: No valid scheduleId for schedule "$scheduleName"');
          for (final game in scheduleGames) {
            errors.add('${game.sheetName} Row ${game.rowNumber}: Failed to create schedule - no scheduleId');
            errorCount++;
          }
          continue;
        }

        // At this point scheduleId is guaranteed to be non-null and non-empty
        assert(scheduleId != null && scheduleId.isNotEmpty);
        validatedScheduleId = scheduleId;

        // Create games using batch write
        final batch = firestore.batch();

        debugPrint('🔗 BULK IMPORT: About to create ${scheduleGames.length} games');
        for (final game in scheduleGames) {
          debugPrint('🔗 BULK IMPORT: Creating game ${game.opponent}: time=${game.time}, linkGroup=${game.linkGroup}');
        }

        // Create unlinked games
        for (final game in unlinkedGames) {
          if (!game.isValid) {
            for (final error in game.errors) {
              errors.add('${game.sheetName} Row ${game.rowNumber}: $error');
            }
            errorCount++;
            continue;
          }

          try {
            final gameData = game.toGameData(currentUser.uid, validatedScheduleId);
            debugPrint('🔗 BULK IMPORT: Saving game ${game.opponent}: time=${gameData['time']}, linkGroupId=${gameData['linkGroupId']}');
            final gameRef = firestore.collection(FirebaseCollections.games).doc();
            batch.set(gameRef, gameData);
            successCount++;
          } catch (e) {
            errors.add('${game.sheetName} Row ${game.rowNumber}: $e');
            errorCount++;
          }
        }

        // Create linked games
        for (final linkEntry in linkGroups.entries) {
          final linkGroup = linkEntry.key;
          final linkedGames = linkEntry.value;

          // Validate all games in link group
          final invalidGames = linkedGames.where((g) => !g.isValid).toList();
          if (invalidGames.isNotEmpty) {
            for (final game in invalidGames) {
              for (final error in game.errors) {
                errors.add('${game.sheetName} Row ${game.rowNumber}: $error');
              }
              errorCount++;
            }
            continue;
          }

          // Generate a link group ID based only on link group to allow cross-schedule linking
          final linkGroupId = linkGroup;

          for (final game in linkedGames) {
            try {
              final gameRef = firestore.collection(FirebaseCollections.games).doc();
              final gameData = game.toGameData(currentUser.uid, validatedScheduleId);
              gameData['linkGroupId'] = linkGroupId;
              gameData['linkedGameCount'] = linkedGames.length;
              batch.set(gameRef, gameData);
              successCount++;
            } catch (e) {
              errors.add('${game.sheetName} Row ${game.rowNumber}: $e');
              errorCount++;
            }
          }
        }

        // Commit batch
        await batch.commit();
      }

      return {
        'success': errorCount == 0,
        'successCount': successCount,
        'errorCount': errorCount,
        'errors': errors,
      };
    } catch (e) {
      debugPrint('❌ BulkImportService: Error importing games: $e');
      return {
        'success': false,
        'error': e.toString(),
        'successCount': successCount,
        'errorCount': errorCount + (games.length - successCount - errorCount),
        'errors': errors,
      };
    }
  }
}

