// import 'package:cakebliss_admin/category/category_screen/details_category.dart';
// import 'package:cakebliss_admin/constants/appcolor.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';

// class CategoryDetailspage extends StatelessWidget {
//   final String categoryName;

//   const CategoryDetailspage(
//       {Key? key,
//       required this.categoryName,
//       required String categoryId,
//       required imageUrl,
//       required String docId})
//       : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//     return Scaffold(
//       backgroundColor: AppColors().mainColor,
//       body: SafeArea(
//         child: Column(
//           children: [
//             // AppBar
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Row(
//                 children: [
//                   IconButton(
//                     icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
//                     onPressed: () => Navigator.pop(context),
//                   ),
//                   const SizedBox(width: 8),
//                   Padding(
//                     padding: const EdgeInsets.all(8.0),
//                     child: Text(
//                       categoryName,
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 24,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(
//               height: 80,
//             ),
//             // Curved Body Content
//             Expanded(
//               child: Container(
//                 width: double.infinity,
//                 decoration: const BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.only(
//                     topLeft: Radius.circular(60),
//                     topRight: Radius.circular(60),
//                   ),
//                 ),
//                 child: ClipRRect(
//                   borderRadius: const BorderRadius.only(
//                     topLeft: Radius.circular(70),
//                     topRight: Radius.circular(70),
//                   ),
//                   child: FutureBuilder<QuerySnapshot>(
//                     future: _firestore
//                         .collection('types')
//                         .where('category', isEqualTo: categoryName)
//                         .get(),
//                     builder: (context, snapshot) {
//                       if (snapshot.connectionState == ConnectionState.waiting) {
//                         return const Center(child: CircularProgressIndicator());
//                       }

//                       if (snapshot.hasError) {
//                         return Center(child: Text('Error: ${snapshot.error}'));
//                       }

//                       if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                         return const Center(
//                             child:
//                                 Text('No types available in this category.'));
//                       }

//                       final types = snapshot.data!.docs;

//                       return ListView.builder(
//                         padding: const EdgeInsets.only(top: 20),
//                         itemCount: types.length,
//                         itemBuilder: (context, index) {
//                           var type =
//                               types[index].data() as Map<String, dynamic>;

//                           return Padding(
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 16, vertical: 8),
//                             child: Card(
//                               elevation: 4,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(15),
//                               ),
//                               child: InkWell(
//                                 borderRadius: BorderRadius.circular(15),
//                                 onTap: () {
//                                   Navigator.push(
//                                     context,
//                                     MaterialPageRoute(
//                                       builder: (context) => TypeDetailsPage(
//                                         typeId: types[index].id,
//                                         typeData: type,
//                                         categoryName: 'name',
//                                       ),
//                                     ),
//                                   );
//                                 },
//                                 child: Padding(
//                                   padding: const EdgeInsets.all(12.0),
//                                   child: Row(
//                                     children: [
//                                       ClipRRect(
//                                         borderRadius: BorderRadius.circular(10),
//                                         child: SizedBox(
//                                           width: 80,
//                                           height: 80,
//                                           child: Image.network(
//                                             type['image'],
//                                             fit: BoxFit.cover,
//                                             errorBuilder:
//                                                 (context, error, stackTrace) =>
//                                                     const Icon(
//                                               Icons.image_not_supported,
//                                               size: 40,
//                                             ),
//                                             loadingBuilder: (context, child,
//                                                 loadingProgress) {
//                                               if (loadingProgress == null) {
//                                                 return child;
//                                               }
//                                               return const Center(
//                                                 child:
//                                                     CircularProgressIndicator(),
//                                               );
//                                             },
//                                           ),
//                                         ),
//                                       ),
//                                       const SizedBox(width: 16),
//                                       Expanded(
//                                         child: Column(
//                                           crossAxisAlignment:
//                                               CrossAxisAlignment.start,
//                                           children: [
//                                             Text(
//                                               type['name'],
//                                               style: const TextStyle(
//                                                 fontSize: 18,
//                                                 fontWeight: FontWeight.bold,
//                                               ),
//                                             ),
//                                             const SizedBox(height: 4),
//                                             Text(
//                                               '₹${type['rate']}',
//                                               style: TextStyle(
//                                                 fontSize: 16,
//                                                 color: AppColors().mainColor,
//                                                 fontWeight: FontWeight.w500,
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                       Icon(
//                                         Icons.arrow_forward_ios,
//                                         color: AppColors().mainColor,
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           );
//                         },
//                       );
//                     },
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'dart:developer';
import 'dart:io';

import 'package:cakebliss_admin/bloc/view2_category/bloc.dart';
import 'package:cakebliss_admin/bloc/view2_category/event.dart';
import 'package:cakebliss_admin/bloc/view2_category/state.dart';

import 'package:cakebliss_admin/category/category_screen/details_category.dart';
import 'package:cakebliss_admin/constants/appcolor.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoryDetailsPage extends StatelessWidget {
  final String categoryName;
  final String categoryId;
  final String imageUrl;
  final String docId;

  const CategoryDetailsPage({
    Key? key,
    required this.categoryName,
    required this.categoryId,
    required this.imageUrl,
    required this.docId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CategoryTypesBloc()
        ..add(FetchCategoryTypes(categoryName: categoryName)),
      child: Scaffold(
        backgroundColor: AppColors().mainColor,
        body: SafeArea(
          child: Column(
            children: [
              // AppBar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon:
                          const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        categoryName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 80,
              ),
              // Curved Body Content
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(60),
                      topRight: Radius.circular(60),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(70),
                      topRight: Radius.circular(70),
                    ),
                    child: BlocBuilder<CategoryTypesBloc, CategoryTypesState>(
                      builder: (context, state) {
                        if (state is CategoryTypesLoading) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (state is CategoryTypesError) {
                          return Center(child: Text('Error: ${state.message}'));
                        }

                        if (state is CategoryTypesLoaded) {
                          final types = state.types;

                          if (types.isEmpty) {
                            return const Center(
                              child:
                                  Text('No types available in this category.'),
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.only(top: 20),
                            itemCount: types.length,
                            itemBuilder: (context, index) {
                              var type =
                                  types[index].data() as Map<String, dynamic>;

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(15),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => TypeDetailsPage(
                                            typeId: types[index].id,
                                            typeData: type,
                                            categoryName: categoryName,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: SizedBox(
                                              width: 80,
                                              height: 80,
                                              child: Image.network(
                                                type['image'],
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                        stackTrace) =>
                                                    const Icon(
                                                  Icons.image_not_supported,
                                                  size: 40,
                                                ),
                                                loadingBuilder: (context, child,
                                                    loadingProgress) {
                                                  if (loadingProgress == null) {
                                                    return child;
                                                  }
                                                  return const Center(
                                                    child:
                                                        CircularProgressIndicator(),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  type['name'],
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '₹${type['rate']}',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color:
                                                        AppColors().mainColor,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            color: AppColors().mainColor,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }

                        return const Center(child: Text('No data available'));
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 5. Let's create a repository to handle all the database operations
// lib/category/repository/category_repository.dart

class CategoryRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CategoryRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  // Method to create a new category
  Future<void> createCategory(String id, String name, File image) async {
    try {
      log('Starting category creation process...');

      // Check for duplicate category
      log('Checking for duplicate category...');
      final querySnapshot = await _firestore
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
        await _firestore.collection("categories").doc(id).set({
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
    return _firestore
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
      await _firestore.collection("categories").doc(id).delete();
      log('Category deleted successfully.');
    } catch (e) {
      log("Error deleting category: ${e.toString()}", error: e);
      throw Exception("Failed to delete category: ${e.toString()}");
    }
  }

  // Method to upload category image
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

  // Method to delete category image
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

  // Method to fetch types by category name
  Future<QuerySnapshot> getTypesByCategory(String categoryName) async {
    try {
      return await _firestore
          .collection('types')
          .where('category', isEqualTo: categoryName)
          .get();
    } catch (e) {
      log("Error fetching types by category: ${e.toString()}", error: e);
      throw Exception("Failed to fetch types: ${e.toString()}");
    }
  }
}
