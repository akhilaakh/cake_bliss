import 'dart:core';
import 'dart:developer';
import 'dart:io';
import 'package:cakebliss_admin/model/usermodel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class DatabaseService {
  final _fire = FirebaseFirestore.instance;

  final FirebaseStorage _storage = FirebaseStorage.instance;

  create(AdminModel admin) {
    try {
      _fire.collection("admin").doc(admin.id).set({
        "name": admin.name,
        "address": admin.address,
        "email": admin.email,
        "password": admin.password,
        "phone": admin.phone,
        "image": admin.imageUrl
      });
    } catch (e) {
      log(e.toString());
    }
  }

  Future<AdminModel?> readUserProfile(String email) async {
    try {
      final querySnapshot = await _fire
          .collection("admin")
          .where("email", isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final adminData = querySnapshot.docs.first.data();
        return AdminModel(
          password: adminData['password'],
          id: adminData['id'] ??
              '', // Using password field as ID based on your create method
          name: adminData['name'] ?? '',
          email: adminData['email'] ?? '',
          phone: adminData['phone'] ?? '',
          address: adminData['address'] ?? '',
          imageUrl: adminData['image'],
        );
      }
      return null;
    } catch (e) {
      log("Error reading user profile: ${e.toString()}");
      return null;
    }
  }

  Future<void> updateUserProfile(AdminModel admin) async {
    try {
      final querySnapshot = await _fire
          .collection("admin")
          .where("email", isEqualTo: admin.email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final docId = querySnapshot.docs.first.id;
        await _fire.collection("admin").doc(docId).update({
          "name": admin.name,
          "address": admin.address,
          "phone": admin.phone,
        });
      }
    } catch (e) {
      log("Error updating user profile: ${e.toString()}");
      throw Exception("Failed to update profile");
    }
  }

  creategoogleprofile(AdminModel admin) {
    try {
      _fire.collection("admin").add({
        "name": admin.name,
        "address": admin.address,
        "phone": admin.phone,
        "image": admin.imageUrl
      });
    } catch (e) {
      log(e.toString());
    }
  }

  //----------------------------------------------------C A T E G O R Y---------------------------------------------------//

  Future<void> createCategoryy(String id, String name, File image) async {
    try {
      log('Starting category creation process...');

      // Check for duplicate category
      log('Checking for duplicate category...');
      final querySnapshot = await _fire
          .collection("categories")
          .where("name", isEqualTo: name)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        log('Duplicate category found!');
        throw Exception("Category name already exists");
      }

      log('No duplicate category found. Proceeding to upload image.');

      // Upload image to Firebase Storage
      final storageRef = _storage.ref().child('categories/$id.jpg');
      final uploadTask = await storageRef.putFile(image);

      if (uploadTask.state == TaskState.success) {
        log('Image uploaded successfully.');

        // Get the download URL
        final imageUrl = await storageRef.getDownloadURL();
        log('Image URL obtained: $imageUrl');

        // Add category to Firestore
        log('Adding category data to Firestore...');
        await _fire.collection("categories").doc(id).set({
          "id": id,
          "name": name,
          "image": imageUrl,
          "createdAt": FieldValue.serverTimestamp(),
        });

        log('Category created successfully in Firestore!');
      } else {
        throw Exception('Image upload failed');
      }
    } catch (e) {
      log("Error creating category: ${e.toString()}", error: e);
      throw Exception("Failed to create category: ${e.toString()}");
    }
  }

// Method to get categories
  Stream<QuerySnapshot> getCategories() {
    return _fire
        .collection("categories")
        .orderBy("createdAt", descending: true)
        .snapshots();
  }

// Method to delete category
  Future<void> deleteCategory(String id) async {
    try {
      log('Deleting category with ID: $id');

      // Delete image from storage
      await _storage.ref().child('categories/$id.jpg').delete();
      log('Image deleted successfully.');

      // Delete document from Firestore
      await _fire.collection("categories").doc(id).delete();
      log('Category deleted successfully.');
    } catch (e) {
      log("Error deleting category: ${e.toString()}", error: e);
      throw Exception("Failed to delete category: ${e.toString()}");
    }
  }
  // Add these methods to your DatabaseService class

  Future<String> uploadCategoryImage(File imageFile) async {
    try {
      final String fileName =
          'categories/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = _storage.ref().child(fileName);
      final UploadTask uploadTask = storageRef.putFile(imageFile);
      final TaskSnapshot taskSnapshot = await uploadTask;
      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      log("Error uploading category image: ${e.toString()}", error: e);
      throw Exception("Failed to upload image: ${e.toString()}");
    }
  }

  Future<void> deleteCategoryImage(String imageUrl) async {
    try {
      // Extract the path from the URL
      String filePath = Uri.decodeFull(imageUrl.split('/o/')[1].split('?')[0]);
      await _storage.ref().child(filePath).delete();
    } catch (e) {
      log("Error deleting category image: ${e.toString()}", error: e);
      throw Exception("Failed to delete image: ${e.toString()}");
    }
  }

//--------------------------------------------------T Y P E----------------------------------------------------------------------//

  // Type Collection CRUD Operations

  // Create Type
  Future<void> createType({
    required String name,
    required File image,
    required double weight,
    required double rate,
    required String description,
  }) async {
    try {
      // Upload image to Firebase Storage
      final imageRef = _storage
          .ref()
          .child('type_images')
          .child('${DateTime.now().millisecondsSinceEpoch}');
      final uploadTask = imageRef.putFile(image);
      final imageUrl = await (await uploadTask).ref.getDownloadURL();

      // Add type data to Firestore
      await _fire.collection("types").add({
        "name": name,
        "image": imageUrl,
        "weight": weight,
        "rate": rate,
        "description": description,
        "createdAt": FieldValue.serverTimestamp(),
      });

      log("Type added successfully");
    } catch (e) {
      log("Error adding type: ${e.toString()}");
      throw e;
    }
  }

  // Read All Types
  Future<List<Map<String, dynamic>>> getTypes() async {
    try {
      final querySnapshot = await _fire.collection("types").get();
      return querySnapshot.docs.map((doc) {
        return {
          "id": doc.id,
          "name": doc["name"],
          "image": doc["image"],
          "weight": doc["weight"],
          "rate": doc["rate"],
          "description": doc["description"],
        };
      }).toList();
    } catch (e) {
      log("Error reading types: ${e.toString()}");
      return [];
    }
  }

  // Read Single Type
  Future<Map<String, dynamic>?> getType(String typeId) async {
    try {
      final docSnapshot = await _fire.collection("types").doc(typeId).get();
      if (docSnapshot.exists) {
        return {
          "id": docSnapshot.id,
          "name": docSnapshot["name"],
          "image": docSnapshot["image"],
          "weight": docSnapshot["weight"],
          "rate": docSnapshot["rate"],
          "description": docSnapshot["description"],
        };
      }
      return null;
    } catch (e) {
      log("Error reading type: ${e.toString()}");
      return null;
    }
  }

  // Update Type
  Future<void> updateType({
    required String typeId,
    String? name,
    File? image,
    double? weight,
    double? rate,
    String? description,
  }) async {
    try {
      final Map<String, dynamic> updates = {};

      if (image != null) {
        final imageRef = _storage
            .ref()
            .child('type_images')
            .child('${DateTime.now().millisecondsSinceEpoch}');
        final uploadTask = imageRef.putFile(image);
        final imageUrl = await (await uploadTask).ref.getDownloadURL();
        updates["image"] = imageUrl;
        log("Image URL uploaded: $imageUrl");
      }

      if (name != null) updates["name"] = name;
      if (weight != null) updates["weight"] = weight;
      if (rate != null) updates["rate"] = rate;
      if (description != null) updates["description"] = description;

      updates["updatedAt"] = FieldValue.serverTimestamp();

      log("Updating type with data: $updates");

      await _fire.collection("types").doc(typeId).update(updates);

      log("Type updated successfully");
    } catch (e) {
      log("Error updating type: ${e.toString()}");
      throw e;
    }
  }

  // Delete Type
  Future<void> deleteType(String typeId) async {
    try {
      final typeDoc = await _fire.collection("types").doc(typeId).get();
      final imageUrl = typeDoc.data()?["image"] as String?;

      await _fire.collection("types").doc(typeId).delete();

      if (imageUrl != null) {
        try {
          final imageRef = _storage.refFromURL(imageUrl);
          await imageRef.delete();
        } catch (e) {
          log("Error deleting image: ${e.toString()}");
        }
      }

      log("Type deleted successfully");
    } catch (e) {
      log("Error deleting type: ${e.toString()}");
      throw e;
    }
  }

  getAdminById(String uid) {}
}
