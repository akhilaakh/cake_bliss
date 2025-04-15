class TypeModel {
  String? id;
  String name;
  String description;
  String imageUrl;
  double weight;
  double rate;

  TypeModel({
    this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.weight,
    required this.rate,
    required List<String> weights,
    required List<String> images,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'weight': weight,
      'rate': rate,
    };
  }

  factory TypeModel.fromMap(Map<String, dynamic> map, String id) {
    return TypeModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      weight: map['weight']?.toDouble() ?? 0.0,
      rate: map['rate']?.toDouble() ?? 0.0,
      weights: [],
      images: [],
    );
  }

  copyWith({required List<String> images}) {}
}
