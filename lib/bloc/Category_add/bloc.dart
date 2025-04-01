// import 'dart:io';
// import 'package:cakebliss_admin/bloc/Category_add/event.dart';
// import 'package:cakebliss_admin/bloc/Category_add/state.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

// import 'package:cakebliss_admin/databaseservices/database.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:image_picker/image_picker.dart';

// class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
//   final DatabaseService databaseService;
//   final FirebaseFirestore firestore;
//   final ImagePicker _imagePicker = ImagePicker();

//   CategoryBloc(this.databaseService, {required this.firestore})
//       : super(CategoryInitial()) {
//     on<PickImageEvent>(_onPickImage);
//     on<SaveCategoryEvent>(_onSaveCategory);
//     on<DeleteCategoryEvent>(_onDeleteCategory);
//     on<FetchCategoriesEvent>(_onFetchCategories);
//   }

//   Future<void> _onPickImage(
//       PickImageEvent event, Emitter<CategoryState> emit) async {
//     try {
//       final pickedFile =
//           await _imagePicker.pickImage(source: ImageSource.gallery);
//       if (pickedFile != null) {
//         emit(CategoryImagePicked(imageFile: File(pickedFile.path)));
//       }
//     } catch (e) {
//       emit(CategoryError(error: 'Failed to pick image: $e'));
//     }
//   }

//   Future<void> _onSaveCategory(
//       SaveCategoryEvent event, Emitter<CategoryState> emit) async {
//     emit(CategorySaving());
//     try {
//       // Upload image and get URL
//       final imageUrl =
//           await databaseService.uploadCategoryImage(event.imageFile);

//       // Save category to Firestore
//       await firestore.collection('categories').add({
//         'name': event.categoryName,
//         'imageUrl': imageUrl,
//         'createdAt': FieldValue.serverTimestamp(),
//       });

//       emit(CategorySaved(message: 'Category saved successfully!'));
//     } catch (e) {
//       emit(CategoryError(error: 'Failed to save category: $e'));
//     }
//   }

//   Future<void> _onDeleteCategory(
//       DeleteCategoryEvent event, Emitter<CategoryState> emit) async {
//     emit(CategoryDeleting());
//     try {
//       // Delete the category image from storage if needed
//       if (event.imageUrl != null && event.imageUrl!.isNotEmpty) {
//         await databaseService.deleteCategoryImage(event.imageUrl!);
//       }

//       // Delete the category from Firestore
//       await firestore.collection('categories').doc(event.categoryId).delete();

//       emit(CategoryDeleted(message: 'Category deleted successfully!'));
//     } catch (e) {
//       emit(CategoryError(error: 'Failed to delete category: $e'));
//     }
//   }

//   Future<void> _onFetchCategories(
//       FetchCategoriesEvent event, Emitter<CategoryState> emit) async {
//     emit(CategoriesLoading());
//     try {
//       final snapshot =
//           await firestore.collection('categories').orderBy('name').get();
//       final categories = snapshot.docs
//           .map((doc) => {
//                 'id': doc.id,
//                 ...doc.data(),
//               })
//           .toList();

//       emit(CategoriesLoaded(categories: categories));
//     } catch (e) {
//       emit(CategoryError(error: 'Failed to load categories: $e'));
//     }
//   }
// }
import 'dart:io';
import 'package:cakebliss_admin/bloc/Category_add/event.dart';
import 'package:cakebliss_admin/bloc/Category_add/state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cakebliss_admin/databaseservices/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final DatabaseService databaseService;
  final FirebaseFirestore firestore;
  final ImagePicker _imagePicker = ImagePicker();

  CategoryBloc(this.databaseService, {required this.firestore})
      : super(CategoryInitial()) {
    on<PickImageEvent>(_onPickImage);
    on<SaveCategoryEvent>(_onSaveCategory);
    on<DeleteCategoryEvent>(_onDeleteCategory);
    on<FetchCategoriesEvent>(_onFetchCategories);
  }

  Future<void> _onPickImage(
      PickImageEvent event, Emitter<CategoryState> emit) async {
    try {
      final pickedFile =
          await _imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        emit(CategoryImagePicked(imageFile: File(pickedFile.path)));
      }
    } catch (e) {
      emit(CategoryError(error: 'Failed to pick image: $e'));
    }
  }

  Future<void> _onSaveCategory(
      SaveCategoryEvent event, Emitter<CategoryState> emit) async {
    emit(CategorySaving());
    try {
      // Generate a unique ID for the category
      final categoryId = const Uuid().v4();

      // Use the existing createCategoryy method from DatabaseService
      await databaseService.createCategoryy(
          categoryId, event.categoryName, event.imageFile);

      emit(CategorySaved(message: 'Category saved successfully!'));
    } catch (e) {
      emit(CategoryError(error: 'Failed to save category: $e'));
    }
  }

  Future<void> _onDeleteCategory(
      DeleteCategoryEvent event, Emitter<CategoryState> emit) async {
    emit(CategoryDeleting());
    try {
      // Use the existing deleteCategory method from DatabaseService
      await databaseService.deleteCategory(event.categoryId);

      emit(CategoryDeleted(message: 'Category deleted successfully!'));
    } catch (e) {
      emit(CategoryError(error: 'Failed to delete category: $e'));
    }
  }

  Future<void> _onFetchCategories(
      FetchCategoriesEvent event, Emitter<CategoryState> emit) async {
    emit(CategoriesLoading());
    try {
      // Get a stream of categories
      final categoriesStream = databaseService.getCategories();

      // Listen to the stream once to get the initial data
      await categoriesStream.first.then((snapshot) {
        final categories = snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                })
            .toList();

        emit(CategoriesLoaded(categories: categories));
      });
    } catch (e) {
      emit(CategoryError(error: 'Failed to load categories: $e'));
    }
  }
}
