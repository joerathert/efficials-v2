class Sport {
  final String name;
  final String id;

  Sport({required this.name, required this.id});

  factory Sport.fromJson(Map<String, dynamic> json) {
    return Sport(
      name: json['name'] ?? '',
      id: json['id'] ?? '',
    );
  }
}

class SportRepository {
  Future<List<Sport>> getAllSports() async {
    // Mock implementation - return some common sports
    await Future.delayed(const Duration(milliseconds: 200));
    return [
      Sport(name: 'Football', id: '1'),
      Sport(name: 'Basketball', id: '2'),
      Sport(name: 'Baseball', id: '3'),
      Sport(name: 'Soccer', id: '4'),
      Sport(name: 'Volleyball', id: '5'),
      Sport(name: 'Tennis', id: '6'),
      Sport(name: 'Swimming', id: '7'),
      Sport(name: 'Track & Field', id: '8'),
    ];
  }
}
