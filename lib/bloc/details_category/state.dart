import 'package:cloud_firestore/cloud_firestore.dart';

class TypeDetailsRepository {
  final FirebaseFirestore _firestore;

  TypeDetailsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getTypeDetails(String typeId) async {
    try {
      final doc = await _firestore.collection('types').doc(typeId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch type details: $e');
    }
  }

  Future<void> deleteType(String typeId) async {
    try {
      await _firestore.collection('types').doc(typeId).delete();
    } catch (e) {
      throw Exception('Failed to delete type: $e');
    }
  }
}
