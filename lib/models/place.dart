class Place {
  final int id;
  final String name;
  final String description;
  String? imageUrl;
  final int categoryId;
  final double latitude;
  final double longitude;

  Place({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    required this.categoryId,
    required this.latitude,
    required this.longitude,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return Place(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'],
      categoryId: json['categoryId'] ?? 0,
      latitude: toDouble(json['latitude']),
      longitude: toDouble(json['longitude']),
    );
  }
}