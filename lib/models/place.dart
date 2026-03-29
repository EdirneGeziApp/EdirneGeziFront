class Place {
  final int id;
  final String name;
  final String description;
  final String? imageUrl;
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
    return Place(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      categoryId: json['categoryId'],
      // Backend'den gelen koordinat verisine göre burayı düzenledik
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
    );
  }
}