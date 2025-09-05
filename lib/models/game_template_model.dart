import 'package:flutter/material.dart';

class GameTemplateModel {
  final String id;
  final String name;
  final String? sport;
  final bool includeSport;
  final String? description;
  final DateTime createdAt;

  // Basic game details
  final bool includeScheduleName;
  final String? scheduleName;
  final bool includeDate;
  final DateTime? date;
  final bool includeTime;
  final TimeOfDay? time;
  final bool includeLocation;
  final String? location;
  final bool includeOpponent;
  final String? opponent;
  final bool includeIsAwayGame;
  final bool isAwayGame;
  final bool includeLevelOfCompetition;
  final String? levelOfCompetition;
  final bool includeGender;
  final String? gender;
  final bool includeOfficialsRequired;
  final int? officialsRequired;
  final bool includeGameFee;
  final String? gameFee;
  final bool includeHireAutomatically;
  final bool? hireAutomatically;

  // Officials assignment
  final String? method; // 'standard', 'use_list', 'advanced', 'hire_crew'
  final bool includeSelectedOfficials;
  final bool includeOfficialsList;
  final String? officialsListName;
  final List<Map<String, dynamic>>? selectedOfficials;
  final List<Map<String, dynamic>>? selectedLists;
  final List<Map<String, dynamic>>? selectedCrews;
  final String? selectedCrewListName;

  GameTemplateModel({
    required this.id,
    required this.name,
    this.sport,
    this.includeSport = true,
    this.description,
    required this.createdAt,
    this.includeScheduleName = false,
    this.scheduleName,
    this.includeDate = false,
    this.date,
    this.includeTime = false,
    this.time,
    this.includeLocation = false,
    this.location,
    this.includeOpponent = false,
    this.opponent,
    this.includeIsAwayGame = false,
    this.isAwayGame = false,
    this.includeLevelOfCompetition = false,
    this.levelOfCompetition,
    this.includeGender = false,
    this.gender,
    this.includeOfficialsRequired = false,
    this.officialsRequired,
    this.includeGameFee = false,
    this.gameFee,
    this.includeHireAutomatically = false,
    this.hireAutomatically,
    this.method,
    this.includeSelectedOfficials = false,
    this.includeOfficialsList = false,
    this.officialsListName,
    this.selectedOfficials,
    this.selectedLists,
    this.selectedCrews,
    this.selectedCrewListName,
  });

  factory GameTemplateModel.fromJson(Map<String, dynamic> json) {
    return GameTemplateModel(
      id: json['id'] as String,
      name: json['name'] as String,
      sport: json['sport'] as String?,
      includeSport: json['includeSport'] as bool? ?? true,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      includeScheduleName: json['includeScheduleName'] as bool? ?? false,
      scheduleName: json['scheduleName'] as String?,
      includeDate: json['includeDate'] as bool? ?? false,
      date:
          json['date'] != null ? DateTime.parse(json['date'] as String) : null,
      includeTime: json['includeTime'] as bool? ?? false,
      time: json['time'] != null
          ? TimeOfDay(
              hour: json['time']['hour'] as int,
              minute: json['time']['minute'] as int,
            )
          : null,
      includeLocation: json['includeLocation'] as bool? ?? false,
      location: json['location'] as String?,
      includeOpponent: json['includeOpponent'] as bool? ?? false,
      opponent: json['opponent'] as String?,
      includeIsAwayGame: json['includeIsAwayGame'] as bool? ?? false,
      isAwayGame: json['isAwayGame'] as bool? ?? false,
      includeLevelOfCompetition:
          json['includeLevelOfCompetition'] as bool? ?? false,
      levelOfCompetition: json['levelOfCompetition'] as String?,
      includeGender: json['includeGender'] as bool? ?? false,
      gender: json['gender'] as String?,
      includeOfficialsRequired:
          json['includeOfficialsRequired'] as bool? ?? false,
      officialsRequired: json['officialsRequired'] as int?,
      includeGameFee: json['includeGameFee'] as bool? ?? false,
      gameFee: json['gameFee'] as String?,
      includeHireAutomatically:
          json['includeHireAutomatically'] as bool? ?? false,
      hireAutomatically: json['hireAutomatically'] as bool?,
      method: json['method'] as String?,
      includeSelectedOfficials:
          json['includeSelectedOfficials'] as bool? ?? false,
      includeOfficialsList: json['includeOfficialsList'] as bool? ?? false,
      officialsListName: json['officialsListName'] as String?,
      selectedOfficials: json['selectedOfficials'] != null
          ? List<Map<String, dynamic>>.from(json['selectedOfficials'] as List)
          : null,
      selectedLists: json['selectedLists'] != null
          ? List<Map<String, dynamic>>.from(json['selectedLists'] as List)
          : null,
      selectedCrews: json['selectedCrews'] != null
          ? List<Map<String, dynamic>>.from(json['selectedCrews'] as List)
          : null,
      selectedCrewListName: json['selectedCrewListName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sport': sport,
      'includeSport': includeSport,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'includeScheduleName': includeScheduleName,
      'scheduleName': scheduleName,
      'includeDate': includeDate,
      'date': date?.toIso8601String(),
      'includeTime': includeTime,
      'time':
          time != null ? {'hour': time!.hour, 'minute': time!.minute} : null,
      'includeLocation': includeLocation,
      'location': location,
      'includeOpponent': includeOpponent,
      'opponent': opponent,
      'includeIsAwayGame': includeIsAwayGame,
      'isAwayGame': isAwayGame,
      'includeLevelOfCompetition': includeLevelOfCompetition,
      'levelOfCompetition': levelOfCompetition,
      'includeGender': includeGender,
      'gender': gender,
      'includeOfficialsRequired': includeOfficialsRequired,
      'officialsRequired': officialsRequired,
      'includeGameFee': includeGameFee,
      'gameFee': gameFee,
      'includeHireAutomatically': includeHireAutomatically,
      'hireAutomatically': hireAutomatically,
      'method': method,
      'includeSelectedOfficials': includeSelectedOfficials,
      'includeOfficialsList': includeOfficialsList,
      'officialsListName': officialsListName,
      'selectedOfficials': selectedOfficials,
      'selectedLists': selectedLists,
      'selectedCrews': selectedCrews,
      'selectedCrewListName': selectedCrewListName,
    };
  }

  GameTemplateModel copyWith({
    String? id,
    String? name,
    String? sport,
    bool? includeSport,
    String? description,
    DateTime? createdAt,
    bool? includeScheduleName,
    String? scheduleName,
    bool? includeDate,
    DateTime? date,
    bool? includeTime,
    TimeOfDay? time,
    bool? includeLocation,
    String? location,
    bool? includeOpponent,
    String? opponent,
    bool? includeIsAwayGame,
    bool? isAwayGame,
    bool? includeLevelOfCompetition,
    String? levelOfCompetition,
    bool? includeGender,
    String? gender,
    bool? includeOfficialsRequired,
    int? officialsRequired,
    bool? includeGameFee,
    String? gameFee,
    bool? includeHireAutomatically,
    bool? hireAutomatically,
    String? method,
    bool? includeSelectedOfficials,
    bool? includeOfficialsList,
    String? officialsListName,
    List<Map<String, dynamic>>? selectedOfficials,
    List<Map<String, dynamic>>? selectedLists,
    List<Map<String, dynamic>>? selectedCrews,
    String? selectedCrewListName,
  }) {
    return GameTemplateModel(
      id: id ?? this.id,
      name: name ?? this.name,
      sport: sport ?? this.sport,
      includeSport: includeSport ?? this.includeSport,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      includeScheduleName: includeScheduleName ?? this.includeScheduleName,
      scheduleName: scheduleName ?? this.scheduleName,
      includeDate: includeDate ?? this.includeDate,
      date: date ?? this.date,
      includeTime: includeTime ?? this.includeTime,
      time: time ?? this.time,
      includeLocation: includeLocation ?? this.includeLocation,
      location: location ?? this.location,
      includeOpponent: includeOpponent ?? this.includeOpponent,
      opponent: opponent ?? this.opponent,
      includeIsAwayGame: includeIsAwayGame ?? this.includeIsAwayGame,
      isAwayGame: isAwayGame ?? this.isAwayGame,
      includeLevelOfCompetition:
          includeLevelOfCompetition ?? this.includeLevelOfCompetition,
      levelOfCompetition: levelOfCompetition ?? this.levelOfCompetition,
      includeGender: includeGender ?? this.includeGender,
      gender: gender ?? this.gender,
      includeOfficialsRequired:
          includeOfficialsRequired ?? this.includeOfficialsRequired,
      officialsRequired: officialsRequired ?? this.officialsRequired,
      includeGameFee: includeGameFee ?? this.includeGameFee,
      gameFee: gameFee ?? this.gameFee,
      includeHireAutomatically:
          includeHireAutomatically ?? this.includeHireAutomatically,
      hireAutomatically: hireAutomatically ?? this.hireAutomatically,
      method: method ?? this.method,
      includeSelectedOfficials:
          includeSelectedOfficials ?? this.includeSelectedOfficials,
      includeOfficialsList: includeOfficialsList ?? this.includeOfficialsList,
      officialsListName: officialsListName ?? this.officialsListName,
      selectedOfficials: selectedOfficials ?? this.selectedOfficials,
      selectedLists: selectedLists ?? this.selectedLists,
      selectedCrews: selectedCrews ?? this.selectedCrews,
      selectedCrewListName: selectedCrewListName ?? this.selectedCrewListName,
    );
  }
}
