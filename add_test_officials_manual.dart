// Manual approach to add test officials - copy this data to Firebase Console
// NOTE: Using separated firstName/lastName fields to match UserModel structure
const testOfficialsData = [
  {
    'firstName': 'John',
    'lastName': 'Smith',
    'email': 'john.smith@email.com',
    'phone': '(555) 123-4567',
    'address': '123 Main Street',
    'cityState': 'Springfield, IL',
    'zipCode': '62701',
    'distance': 5.2, // Calculated distance from game location
    'yearsExperience': 8,
    'ihsaLevel': 'registered',
    'competitionLevels': ['Grade School', 'Middle School', 'JV', 'Varsity'],
    'sports': ['Football', 'Basketball'],
    'isActive': true,
    'createdAt': '2024-01-15T10:00:00.000Z',
    'updatedAt': '2024-01-15T10:00:00.000Z',
  },
  {
    'firstName': 'Sarah',
    'lastName': 'Johnson',
    'email': 'sarah.johnson@email.com',
    'phone': '(555) 234-5678',
    'address': '456 Oak Avenue',
    'cityState': 'Champaign, IL',
    'zipCode': '61820',
    'distance': 12.8, // Calculated distance from game location
    'yearsExperience': 5,
    'ihsaLevel': 'recognized',
    'competitionLevels': ['JV', 'Varsity', 'College'],
    'sports': ['Football', 'Soccer'],
    'isActive': true,
    'createdAt': '2024-01-15T10:00:00.000Z',
    'updatedAt': '2024-01-15T10:00:00.000Z',
  },
  {
    'firstName': 'Mike',
    'lastName': 'Davis',
    'email': 'mike.davis@email.com',
    'phone': '(555) 345-6789',
    'address': '789 Pine Road',
    'cityState': 'Decatur, IL',
    'zipCode': '62521',
    'distance': 25.1, // Calculated distance from game location
    'yearsExperience': 12,
    'ihsaLevel': 'certified',
    'competitionLevels': ['Varsity', 'College', 'Adult'],
    'sports': ['Football', 'Basketball', 'Baseball'],
    'isActive': true,
    'createdAt': '2024-01-15T10:00:00.000Z',
    'updatedAt': '2024-01-15T10:00:00.000Z',
  },
  {
    'firstName': 'Emily',
    'lastName': 'Wilson',
    'email': 'emily.wilson@email.com',
    'phone': '(555) 456-7890',
    'address': '321 Elm Street',
    'cityState': 'Bloomington, IL',
    'zipCode': '61701',
    'distance': 8.9, // Calculated distance from game location
    'yearsExperience': 6,
    'ihsaLevel': 'registered',
    'competitionLevels': ['Grade School', 'Middle School', 'Underclass'],
    'sports': ['Soccer', 'Volleyball'],
    'isActive': true,
    'createdAt': '2024-01-15T10:00:00.000Z',
    'updatedAt': '2024-01-15T10:00:00.000Z',
  },
  {
    'firstName': 'David',
    'lastName': 'Brown',
    'email': 'david.brown@email.com',
    'phone': '(555) 567-8901',
    'address': '654 Maple Drive',
    'cityState': 'Peoria, IL',
    'zipCode': '61602',
    'distance': 18.3, // Calculated distance from game location
    'yearsExperience': 10,
    'ihsaLevel': 'recognized',
    'competitionLevels': ['JV', 'Varsity', 'College'],
    'sports': ['Football', 'Wrestling', 'Track'],
    'isActive': true,
    'createdAt': '2024-01-15T10:00:00.000Z',
    'updatedAt': '2024-01-15T10:00:00.000Z',
  },
  {
    'firstName': 'Lisa',
    'lastName': 'Garcia',
    'email': 'lisa.garcia@email.com',
    'phone': '(555) 678-9012',
    'address': '987 Cedar Lane',
    'cityState': 'Normal, IL',
    'zipCode': '61761',
    'distance': 15.7, // Calculated distance from game location
    'yearsExperience': 7,
    'ihsaLevel': 'certified',
    'competitionLevels': ['Middle School', 'JV', 'Varsity'],
    'sports': ['Basketball', 'Soccer', 'Softball'],
    'isActive': true,
    'createdAt': '2024-01-15T10:00:00.000Z',
    'updatedAt': '2024-01-15T10:00:00.000Z',
  },
  {
    'firstName': 'Robert',
    'lastName': 'Taylor',
    'email': 'robert.taylor@email.com',
    'phone': '(555) 789-0123',
    'address': '147 Birch Court',
    'cityState': 'Urbana, IL',
    'zipCode': '61801',
    'distance': 22.4, // Calculated distance from game location
    'yearsExperience': 15,
    'ihsaLevel': 'certified',
    'competitionLevels': ['Varsity', 'College', 'Adult'],
    'sports': ['Football', 'Basketball', 'Baseball'],
    'isActive': true,
    'createdAt': '2024-01-15T10:00:00.000Z',
    'updatedAt': '2024-01-15T10:00:00.000Z',
  },
  {
    'firstName': 'Jennifer',
    'lastName': 'Martinez',
    'email': 'jennifer.martinez@email.com',
    'phone': '(555) 890-1234',
    'address': '258 Walnut Way',
    'cityState': 'Danville, IL',
    'zipCode': '61832',
    'distance': 35.2, // Calculated distance from game location
    'yearsExperience': 3,
    'ihsaLevel': 'registered',
    'competitionLevels': ['Grade School', 'Middle School'],
    'sports': ['Soccer', 'Volleyball'],
    'isActive': true,
    'createdAt': '2024-01-15T10:00:00.000Z',
    'updatedAt': '2024-01-15T10:00:00.000Z',
  },
];

// =============================================
// PRODUCTION STRUCTURE: Sport-Specific Everything!
// =============================================
// IHSA certification and competition levels are both sport-specific

const productionOfficialsData = [
  {
    'firstName': 'John',
    'lastName': 'Smith',
    'email': 'john.smith@email.com',
    'phone': '(555) 123-4567',
    'address': '123 Main Street',
    'cityState': 'Springfield, IL',
    'zipCode': '62701',
    'distance': 5.2, // Will be calculated using Google Maps API
    'sportsData': {
      'Football': {
        'ihsaLevel': 'certified',
        'competitionLevels': ['JV', 'Varsity'],
        'yearsExperience': 8
      },
      'Basketball': {
        'ihsaLevel': 'recognized',
        'competitionLevels': ['Varsity'],
        'yearsExperience': 3
      }
    },
    'isActive': true,
    'createdAt': '2024-01-15T10:00:00.000Z',
    'updatedAt': '2024-01-15T10:00:00.000Z',
  },
  {
    'firstName': 'Sarah',
    'lastName': 'Johnson',
    'email': 'sarah.johnson@email.com',
    'phone': '(555) 234-5678',
    'address': '456 Oak Avenue',
    'cityState': 'Champaign, IL',
    'zipCode': '61820',
    'distance': 12.8, // Will be calculated using Google Maps API
    'sportsData': {
      'Football': {
        'ihsaLevel': 'registered',
        'competitionLevels': ['JV', 'Varsity'],
        'yearsExperience': 5
      },
      'Soccer': {
        'ihsaLevel': 'recognized',
        'competitionLevels': ['Varsity', 'College'],
        'yearsExperience': 7
      }
    },
    'isActive': true,
    'createdAt': '2024-01-15T10:00:00.000Z',
    'updatedAt': '2024-01-15T10:00:00.000Z',
  },
  {
    'firstName': 'Mike',
    'lastName': 'Davis',
    'email': 'mike.davis@email.com',
    'phone': '(555) 345-6789',
    'address': '789 Pine Road',
    'cityState': 'Decatur, IL',
    'zipCode': '62521',
    'distance': 25.1, // Will be calculated using Google Maps API
    'sportsData': {
      'Football': {
        'ihsaLevel': 'certified',
        'competitionLevels': ['Varsity', 'College'],
        'yearsExperience': 12
      },
      'Basketball': {
        'ihsaLevel': 'certified',
        'competitionLevels': ['Varsity'],
        'yearsExperience': 10
      },
      'Baseball': {
        'ihsaLevel': 'recognized',
        'competitionLevels': ['JV', 'Varsity'],
        'yearsExperience': 6
      }
    },
    'isActive': true,
    'createdAt': '2024-01-15T10:00:00.000Z',
    'updatedAt': '2024-01-15T10:00:00.000Z',
  },
];
