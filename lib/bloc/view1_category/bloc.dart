import 'dart:developer';

import 'package:cakebliss_admin/bloc/view1_category/event.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class CategoryState extends Equatable {
  const CategoryState();

  @override
  List<Object?> get props => [];
}

class CategoryInitial extends CategoryState {}

class CategoryLoading extends CategoryState {}

class CategoriesLoaded extends CategoryState {
  final List<QueryDocumentSnapshot> categories;

  const CategoriesLoaded(this.categories);

  @override
  List<Object> get props => [categories];
}

class CategoryOperationSuccess extends CategoryState {
  final String message;

  const CategoryOperationSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class CategoryError extends CategoryState {
  final String message;

  const CategoryError(this.message);

  @override
  List<Object> get props => [message];
}

// category_event.dart

// category_bloc.dart

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CategoryBloc({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        super(CategoryInitial()) {
    on<LoadCategories>(_onLoadCategories);
    on<CreateCategory>(_onCreateCategory);
    on<UpdateCategory>(_onUpdateCategory);
    on<DeleteCategory>(_onDeleteCategory);
  }

  Future<void> _onLoadCategories(
      LoadCategories event, Emitter<CategoryState> emit) async {
    try {
      emit(CategoryLoading());

      // Listen to the categories stream and emit new state when data changes
      await emit.forEach(
          _firestore
              .collection("categories")
              .orderBy("createdAt", descending: true)
              .snapshots(), onData: (QuerySnapshot snapshot) {
        return CategoriesLoaded(snapshot.docs);
      }, onError: (error, stackTrace) {
        log("Error loading categories: $error", error: error);
        return CategoryError("Failed to load categories: $error");
      });
    } catch (e) {
      log("Error in load categories event: ${e.toString()}", error: e);
      emit(CategoryError("Failed to load categories: ${e.toString()}"));
    }
  }

  Future<void> _onCreateCategory(
      CreateCategory event, Emitter<CategoryState> emit) async {
    try {
      emit(CategoryLoading());
      log('Starting category creation process...');

      // Check for duplicate category
      log('Checking for duplicate category...');
      final querySnapshot = await _firestore
          .collection("categories")
          .where("name", isEqualTo: event.name)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        log('Duplicate category found!');
        emit(CategoryError("Category name already exists"));
        return;
      }

      log('No duplicate category found. Proceeding to upload image.');

      // Upload image to Firebase Storage
      final storageRef = _storage.ref().child('categories/${event.id}.jpg');
      final uploadTask = await storageRef.putFile(event.image);

      if (uploadTask.state == TaskState.success) {
        log('Image uploaded successfully.');

        // Get the download URL
        final imageUrl = await storageRef.getDownloadURL();
        log('Image URL obtained: $imageUrl');

        // Add category to Firestore
        log('Adding category data to Firestore...');
        await _firestore.collection("categories").doc(event.id).set({
          "id": event.id,
          "name": event.name,
          "image": imageUrl,
          "createdAt": FieldValue.serverTimestamp(),
        });

        log('Category created successfully in Firestore!');
        emit(CategoryOperationSuccess("Category created successfully"));

        // Refresh categories list
        add(LoadCategories());
      } else {
        throw Exception('Image upload failed');
      }
    } catch (e) {
      log("Error creating category: ${e.toString()}", error: e);
      emit(CategoryError("Failed to create category: ${e.toString()}"));
    }
  }

  Future<void> _onUpdateCategory(
      UpdateCategory event, Emitter<CategoryState> emit) async {
    try {
      emit(CategoryLoading());

      // Check for name validation only if it's being changed
      // Get current category data
      final categoryDoc =
          await _firestore.collection("categories").doc(event.id).get();
      final currentData = categoryDoc.data();

      if (currentData == null) {
        emit(CategoryError("Category not found"));
        return;
      }

      // Check for duplicate name if name is being changed
      if (event.name != currentData['name']) {
        final querySnapshot = await _firestore
            .collection("categories")
            .where("name", isEqualTo: event.name)
            .get();

        if (querySnapshot.docs.isNotEmpty &&
            querySnapshot.docs.first.id != event.id) {
          emit(CategoryError("Category name already exists"));
          return;
        }
      }

      // Prepare update data
      Map<String, dynamic> updateData = {
        "name": event.name,
      };

      // Upload new image if provided
      if (event.image != null) {
        final storageRef = _storage.ref().child('categories/${event.id}.jpg');
        await storageRef.putFile(event.image!);
        final imageUrl = await storageRef.getDownloadURL();
        updateData["image"] = imageUrl;
      }

      // Update document in Firestore
      await _firestore
          .collection("categories")
          .doc(event.id)
          .update(updateData);

      emit(CategoryOperationSuccess("Category updated successfully"));

      // Refresh categories list
      add(LoadCategories());
    } catch (e) {
      log("Error updating category: ${e.toString()}", error: e);
      emit(CategoryError("Failed to update category: ${e.toString()}"));
    }
  }

  Future<void> _onDeleteCategory(
      DeleteCategory event, Emitter<CategoryState> emit) async {
    try {
      emit(CategoryLoading());

      // Get the category name before deletion
      final categoryDoc =
          await _firestore.collection("categories").doc(event.id).get();

      if (!categoryDoc.exists) {
        throw Exception('Category not found');
      }

      final categoryName = categoryDoc.data()?['name'];

      // Start a batch operation
      final batch = _firestore.batch();

      // Delete all subcategories (types) associated with this category
      final typesSnapshot = await _firestore
          .collection('types')
          .where('category', isEqualTo: categoryName)
          .get();

      // Add all subcategory deletions to batch
      for (var doc in typesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Add category deletion to batch
      batch.delete(_firestore.collection('categories').doc(event.id));

      // Execute all deletions in a single atomic operation
      await batch.commit();

      // Delete the category image from storage if it exists
      try {
        final storageRef = _storage.ref().child('categories/${event.id}.jpg');
        await storageRef.delete();
      } catch (e) {
        // Ignore storage deletion errors as the image might not exist
        print('Storage deletion error (non-critical): $e');
      }

      emit(CategoryOperationSuccess(
          "Category and associated items deleted successfully"));

      // Refresh categories list
      add(LoadCategories());
    } catch (e) {
      log("Error deleting category: ${e.toString()}", error: e);
      emit(CategoryError("Failed to delete category: ${e.toString()}"));
    }
  }
}
