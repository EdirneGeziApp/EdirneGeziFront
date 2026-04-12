class Category {
  final int id;
  final String name;
  final String? iconUrl;

  Category({required this.id, required this.name, this.iconUrl});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0,
      // Hem 'name' hem 'Name' kontrolü yapıyoruz ki boş gelmesin
      name: json['name'] ?? json['Name'] ?? 'Bilinmeyen',
      iconUrl: json['iconUrl'],
    );
  }
}
