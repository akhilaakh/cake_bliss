import 'package:cloud_firestore/cloud_firestore.dart';

class CustomizationModel {
  final String id;
  final String userId;
  final String imageUrl;
  final double weight;
  final String flavor;
  final String description;
  // final double budget;
  final String status;
  final DateTime createdAt;

  CustomizationModel({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.weight,
    required this.flavor,
    required this.description,
    // required this.budget,
    this.status = 'pending',
    DateTime? createdAt,
  }) : this.createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'imageUrl': imageUrl,
      'weight': weight,
      'flavor': flavor,
      'description': description,
      // 'budget': budget,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory CustomizationModel.fromMap(
      Map<String, dynamic> map, String documentId) {
    return CustomizationModel(
      id: documentId,
      userId: map['userId'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      weight: (map['weight'] ?? 0).toDouble(),
      flavor: map['flavor'] ?? '',
      description: map['description'] ?? '',
      // budget: (map['budget'] ?? 0).toDouble(),
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
