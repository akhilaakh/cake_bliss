import 'dart:developer';

import 'package:cake_bliss/customization/model/model.dart';
import 'package:cake_bliss/model/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final _fire = FirebaseFirestore.instance;

  Future<void> create(UserModel user) async {
    try {
      print("Creating user with image URL: ${user.imageUrl}");
      await _fire.collection("users").doc(user.id).set({
        "name": user.name,
        "address": user.address,
        "email": user.email,
        "password": user.password,
        "phone": user.phone,
        "imageUrl": user.imageUrl ?? '' // Ensure imageUrl is never null
      });
      print("User created successfully with image URL: ${user.imageUrl}");
    } catch (e) {
      print("Error creating user: ${e.toString()}");
      log(e.toString());
      throw e; // Rethrow to handle in UI
    }
  }

  Future<UserModel?> readUserProfile(String email) async {
    try {
      final querySnapshot = await _fire
          .collection("users")
          .where("email", isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data();
        return UserModel(
          password: userData['password'],
          id: querySnapshot.docs.first
              .id, // Using password field as ID based on your create method
          name: userData['name'] ?? '',
          email: userData['email'] ?? '',
          phone: userData['phone'] ?? '',
          address: userData['address'] ?? '',
          imageUrl: userData['imageUrl'] ?? '',
        );
      }
      return null;
    } catch (e) {
      log("Error reading user profile: ${e.toString()}");
      return null;
    }
  }

  Future<void> updateUserProfile(UserModel user) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.id).update({
        'name': user.name,
        'address': user.address,
        'phone': user.phone,
        'imageUrl': user.imageUrl, // Make sure this field is updated
      });
    } catch (e) {
      print('Error updating profile: $e');
      throw e;
    }
  }

  creategoogleprofile(UserModel user) {
    try {
      _fire.collection("users").add({
        "name": user.name,
        "address": user.address,
        "phone": user.phone,
        "imageUrl": user.imageUrl
      });
    } catch (e) {
      log(e.toString());
    }
  }

  getItems() {}

  getUserProfile(String uid) {}
}

//-------------------------------------------------------C U S T A M I Z A T I O N-----------------------------------------------------------------------------//

class CustomizationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create new customization
  Future<void> createCustomization(CustomizationModel customization) async {
    try {
      await _firestore.collection('customizations').add({
        'userId': customization.userId,
        'imageUrl': customization.imageUrl,
        'weight': customization.weight,
        'flavor': customization.flavor,
        'description': customization.description,
        // 'budget': customization.budget,
        'status': customization.status,
        'createdAt': FieldValue.serverTimestamp(),
      });
      log('Customization added successfully');
    } catch (e) {
      log('Error creating customization: ${e.toString()}');
      throw Exception('Failed to create customization');
    }
  }

  // Get all customizations for a user
  Stream<List<CustomizationModel>> getUserCustomizations(String userId) {
    return _firestore
        .collection('customizations')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CustomizationModel.fromMap(
                  doc.data(),
                  doc.id,
                ))
            .toList());
  }

  // Get single customization by ID
  Future<CustomizationModel?> getCustomizationById(String id) async {
    try {
      final doc = await _firestore.collection('customizations').doc(id).get();
      if (doc.exists) {
        return CustomizationModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      log('Error getting customization: ${e.toString()}');
      return null;
    }
  }

  // Delete customization
  Future<void> deleteCustomization(String id) async {
    try {
      await _firestore.collection('customizations').doc(id).delete();
    } catch (e) {
      log('Error deleting customization: ${e.toString()}');
      throw Exception('Failed to delete customization');
    }
  }
}
