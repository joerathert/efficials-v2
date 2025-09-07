// Excel data converted to proper UserModel format with sport-specific attributes
const testOfficialsFromExcel = [
  {
    'id': 'official_derek_greenfield',
    'email': 'derek.greenfield@efficials.com',
    'role': 'official',
    'isActive': true,
    'createdAt': '2024-01-15T10:00:00.000Z',
    'updatedAt': '2024-01-15T10:00:00.000Z',
    'profile': {
      'firstName': 'Derek',
      'lastName': 'Greenfield',
      'phone': '(555) 123-4567',
    },
    'officialProfile': {
      'city': 'Swansea',
      'state': 'IL',
      'zipCode': '62226',
      'address': '204 Wild Cherry Ln.',
      'distance': 8.5,
      'sportsData': {
        'Football': {
          'experienceYears': 12,
          'certificationLevel': 'certified',
          'competitionLevels': ['Underclass', 'JV', 'Varsity']
        }
      },
      'sports': ['Football'],
      'availabilityStatus': 'available',
      'followThroughRate': 100.0,
      'totalAcceptedGames': 0,
      'totalBackedOutGames': 0,
    },
  },
  {
    'id': 'official_beaux_greenfield',
    'email': 'beaux.greenfield@efficials.com',
    'role': 'official',
    'isActive': true,
    'createdAt': '2024-01-15T10:00:00.000Z',
    'updatedAt': '2024-01-15T10:00:00.000Z',
    'profile': {
      'firstName': 'Beaux',
      'lastName': 'Greenfield',
      'phone': '(555) 234-5678',
    },
    'officialProfile': {
      'city': 'Millstadt',
      'state': 'IL',
      'zipCode': '62260',
      'address': '9 Josiah Ln.',
      'distance': 12.3,
      'sportsData': {
        'Football': {
          'experienceYears': 12,
          'certificationLevel': 'certified',
          'competitionLevels': ['Underclass', 'JV', 'Varsity']
        }
      },
      'sports': ['Football'],
      'availabilityStatus': 'available',
      'followThroughRate': 100.0,
      'totalAcceptedGames': 0,
      'totalBackedOutGames': 0,
    },
  },
  {
    'id': 'official_brian_jackson',
    'email': 'brian.jackson@efficials.com',
    'role': 'official',
    'isActive': true,
    'createdAt': '2024-01-15T10:00:00.000Z',
    'updatedAt': '2024-01-15T10:00:00.000Z',
    'profile': {
      'firstName': 'Brian',
      'lastName': 'Jackson',
      'phone': '(555) 345-6789',
    },
    'officialProfile': {
      'city': 'Shiloh',
      'state': 'IL',
      'zipCode': '62269',
      'address': '1137 Hampshire Lane',
      'distance': 6.8,
      'sportsData': {
        'Football': {
          'experienceYears': 11,
          'certificationLevel': 'certified',
          'competitionLevels': ['Underclass', 'JV', 'Varsity']
        }
      },
      'sports': ['Football'],
      'availabilityStatus': 'available',
      'followThroughRate': 100.0,
      'totalAcceptedGames': 0,
      'totalBackedOutGames': 0,
    },
  },
  {
    'id': 'official_chris_walters',
    'email': 'chris.walters@efficials.com',
    'role': 'official',
    'isActive': true,
    'createdAt': '2024-01-15T10:00:00.000Z',
    'updatedAt': '2024-01-15T10:00:00.000Z',
    'profile': {
      'firstName': 'Chris',
      'lastName': 'Walters',
      'phone': '(555) 456-7890',
    },
    'officialProfile': {
      'city': 'Belleville',
      'state': 'IL',
      'zipCode': '62223',
      'address': '7920 West A Street',
      'distance': 4.2,
      'sportsData': {
        'Football': {
          'experienceYears': 14,
          'certificationLevel': 'certified',
          'competitionLevels': ['Underclass', 'JV', 'Varsity']
        }
      },
      'sports': ['Football'],
      'availabilityStatus': 'available',
      'followThroughRate': 100.0,
      'totalAcceptedGames': 0,
      'totalBackedOutGames': 0,
    },
  },
  {
    'id': 'official_joe_rathert',
    'email': 'joe.rathert@efficials.com',
    'role': 'official',
    'isActive': true,
    'createdAt': '2024-01-15T10:00:00.000Z',
    'updatedAt': '2024-01-15T10:00:00.000Z',
    'profile': {
      'firstName': 'Joe',
      'lastName': 'Rathert',
      'phone': '(555) 567-8901',
    },
    'officialProfile': {
      'city': 'Belleville',
      'state': 'IL',
      'zipCode': '62223',
      'address': '2 Madonna Ct',
      'distance': 4.2,
      'sportsData': {
        'Football': {
          'experienceYears': 23,
          'certificationLevel': 'certified',
          'competitionLevels': ['Underclass', 'JV', 'Varsity']
        }
      },
      'sports': ['Football'],
      'availabilityStatus': 'available',
      'followThroughRate': 100.0,
      'totalAcceptedGames': 0,
      'totalBackedOutGames': 0,
    },
  },
  {
    'id': 'official_chuck_rathert',
    'email': 'chuck.rathert@efficials.com',
    'role': 'official',
    'isActive': true,
    'createdAt': '2024-01-15T10:00:00.000Z',
    'updatedAt': '2024-01-15T10:00:00.000Z',
    'profile': {
      'firstName': 'Chuck',
      'lastName': 'Rathert',
      'phone': '(555) 678-9012',
    },
    'officialProfile': {
      'city': 'Belleville',
      'state': 'IL',
      'zipCode': '62223',
      'address': '50 Cheshire Dr',
      'distance': 4.2,
      'sportsData': {
        'Football': {
          'experienceYears': 17,
          'certificationLevel': 'certified',
          'competitionLevels': ['Underclass', 'JV', 'Varsity']
        }
      },
      'sports': ['Football'],
      'availabilityStatus': 'available',
      'followThroughRate': 100.0,
      'totalAcceptedGames': 0,
      'totalBackedOutGames': 0,
    },
  },
  {
    'id': 'official_mike_modarelli',
    'email': 'mike.modarelli@efficials.com',
    'role': 'official',
    'isActive': true,
    'createdAt': '2024-01-15T10:00:00.000Z',
    'updatedAt': '2024-01-15T10:00:00.000Z',
    'profile': {
      'firstName': 'Mike',
      'lastName': 'Modarelli',
      'phone': '(555) 789-0123',
    },
    'officialProfile': {
      'city': 'Edwardsville',
      'state': 'IL',
      'zipCode': '62025',
      'address': '3138 Bluff Rd',
      'distance': 15.7,
      'sportsData': {
        'Football': {
          'experienceYears': 21,
          'certificationLevel': 'certified',
          'competitionLevels': ['Underclass', 'JV', 'Varsity']
        }
      },
      'sports': ['Football'],
      'availabilityStatus': 'available',
      'followThroughRate': 100.0,
      'totalAcceptedGames': 0,
      'totalBackedOutGames': 0,
    },
  },
  {
    'id': 'official_ben_trotter',
    'email': 'ben.trotter@efficials.com',
    'role': 'official',
    'isActive': true,
    'createdAt': '2024-01-15T10:00:00.000Z',
    'updatedAt': '2024-01-15T10:00:00.000Z',
    'profile': {
      'firstName': 'Ben',
      'lastName': 'Trotter',
      'phone': '(555) 890-1234',
    },
    'officialProfile': {
      'city': 'Edwardsville',
      'state': 'IL',
      'zipCode': '62025',
      'address': '3120 Bluff Road',
      'distance': 15.7,
      'sportsData': {
        'Football': {
          'experienceYears': 13,
          'certificationLevel': 'registered',
          'competitionLevels': ['Underclass', 'JV', 'Varsity']
        }
      },
      'sports': ['Football'],
      'availabilityStatus': 'available',
      'followThroughRate': 100.0,
      'totalAcceptedGames': 0,
      'totalBackedOutGames': 0,
    },
  },
  {
    'id': 'official_mike_raney',
    'email': 'mike.raney@efficials.com',
    'role': 'official',
    'isActive': true,
    'createdAt': '2024-01-15T10:00:00.000Z',
    'updatedAt': '2024-01-15T10:00:00.000Z',
    'profile': {
      'firstName': 'Mike',
      'lastName': 'Raney',
      'phone': '(555) 858-3215',
    },
    'officialProfile': {
      'city': "O'Fallon",
      'state': 'IL',
      'zipCode': '62269',
      'address': '1228 Conrad Ln',
      'distance': 0.0,
      'sportsData': {
        'Football': {
          'experienceYears': 21,
          'certificationLevel': 'recognized',
          'competitionLevels': ['Underclass', 'JV', 'Varsity']
        }
      },
      'sports': ['Football'],
      'availabilityStatus': 'available',
      'followThroughRate': 100.0,
      'totalAcceptedGames': 0,
      'totalBackedOutGames': 0,
    },
  },
  {
    'id': 'official_johnny_murray',
    'email': 'johnny.murray@efficials.com',
    'role': 'official',
    'isActive': true,
    'createdAt': '2024-01-15T10:00:00.000Z',
    'updatedAt': '2024-01-15T10:00:00.000Z',
    'profile': {
      'firstName': 'Johnny',
      'lastName': 'Murray',
      'phone': '(555)584-3135',
    },
    'officialProfile': {
      'city': "O'Fallon",
      'state': 'IL',
      'zipCode': '62269',
      'address': '1211 Marshal Ct',
      'distance': 0.0,
      'sportsData': {
        'Football': {
          'experienceYears': 11,
          'certificationLevel': 'certified',
          'competitionLevels': ['Underclass', 'JV', 'Varsity']
        }
      },
      'sports': ['Football'],
      'availabilityStatus': 'available',
      'followThroughRate': 100.0,
      'totalAcceptedGames': 0,
      'totalBackedOutGames': 0,
    },
  },
];
