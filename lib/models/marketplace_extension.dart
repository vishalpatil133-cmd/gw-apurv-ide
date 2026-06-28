class MarketplaceExtension {
  final String id;
  final String name;
  final String description;
  final String version;
  final String publisher;
  final double rating;
  final int downloads;
  final String iconUrl;
  final String type; // e.g. "theme", "language", "tool"
  bool isInstalled;
  bool isInstalling;

  MarketplaceExtension({
    required this.id,
    required this.name,
    required this.description,
    required this.version,
    required this.publisher,
    required this.rating,
    required this.downloads,
    required this.iconUrl,
    required this.type,
    this.isInstalled = false,
    this.isInstalling = false,
  });

  factory MarketplaceExtension.fromJson(Map<String, dynamic> json) {
    return MarketplaceExtension(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      version: json['version'] as String,
      publisher: json['publisher'] as String,
      rating: (json['rating'] as num).toDouble(),
      downloads: json['downloads'] as int,
      iconUrl: json['iconUrl'] as String,
      type: json['type'] as String,
      isInstalled: json['isInstalled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'version': version,
      'publisher': publisher,
      'rating': rating,
      'downloads': downloads,
      'iconUrl': iconUrl,
      'type': type,
      'isInstalled': isInstalled,
    };
  }
}
