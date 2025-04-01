import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch all categories
  Stream<List<Category>> fetchCategories() {
    return _firestore.collection('categories').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Category.fromDocument(doc);
      }).toList();
    });
  }

  listenToCustomizationNotifications() {}

  fetchAllItems() {}
}

// Category model
class Category {
  final String id;
  final String name;
  final String imageUrl;

  Category({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  // Factory constructor to create a Category from Firestore document
  factory Category.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Category(
      id: doc.id,
      name: data['name'] ?? '',
      imageUrl: data['image'] ?? '',
    );
  }

  static fromMap(Map<String, dynamic> data) {}
}
