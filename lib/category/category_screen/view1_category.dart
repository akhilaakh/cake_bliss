// import 'dart:developer';
// import 'dart:io';
// import 'package:cakebliss_admin/Screen/homepage.dart';
// import 'package:cakebliss_admin/category/category_screen/view2_category.dart';
// import 'package:cakebliss_admin/constants/appcolor.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';

// class CategoryViewPage extends StatefulWidget {
//   const CategoryViewPage({Key? key}) : super(key: key);

//   @override
//   _CategoryViewPageState createState() => _CategoryViewPageState();
// }

// class _CategoryViewPageState extends State<CategoryViewPage> {
//   void _showEditDialog(
//       BuildContext context, Map<String, dynamic> category, String docId) {
//     final TextEditingController nameController =
//         TextEditingController(text: category['name']);
//     File? selectedImage;
//     String currentImageUrl = category['image'] ?? '';
//     String? errorMessage;

//     showDialog(
//       context: context,
//       builder: (context) => StatefulBuilder(
//         builder: (context, setState) => AlertDialog(
//           title: const Text('Edit Category'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               GestureDetector(
//                 onTap: () async {
//                   final pickedFile = await ImagePicker()
//                       .pickImage(source: ImageSource.gallery);
//                   if (pickedFile != null) {
//                     setState(() {
//                       selectedImage = File(pickedFile.path);
//                     });
//                   }
//                 },
//                 child: selectedImage != null
//                     ? Image.file(selectedImage!,
//                         height: 100, width: 100, fit: BoxFit.cover)
//                     : Image.network(
//                         currentImageUrl,
//                         height: 100,
//                         width: 100,
//                         fit: BoxFit.cover,
//                         errorBuilder: (context, error, stackTrace) =>
//                             const Icon(Icons.image_not_supported),
//                       ),
//               ),
//               TextField(
//                 controller: nameController,
//                 decoration: InputDecoration(
//                   labelText: 'Category Name',
//                   errorText: errorMessage,
//                 ),
//                 onChanged: (value) {
//                   setState(() {
//                     errorMessage = null; // Clear error on input change
//                   });
//                 },
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () async {
//                 final newName = nameController.text.trim();
//                 final isNameChanged = newName != category['name'];
//                 final isImageChanged = selectedImage != null;

//                 // Only validate name if it's being changed
//                 if (isNameChanged) {
//                   final startsWithCapital = RegExp(r'^[A-Z]').hasMatch(newName);
//                   final onlyAlphabets =
//                       RegExp(r'^[A-Za-z]+$').hasMatch(newName);

//                   if (newName.isEmpty) {
//                     setState(() {
//                       errorMessage = 'Category name cannot be empty';
//                     });
//                     return;
//                   }
//                   if (!startsWithCapital) {
//                     setState(() {
//                       errorMessage =
//                           'Category name must begin with a capital letter.';
//                     });
//                     return;
//                   }
//                   if (!onlyAlphabets) {
//                     setState(() {
//                       errorMessage =
//                           'Category name can only contain alphabets.';
//                     });
//                     return;
//                   }

//                   // Check for duplicate name only if name is being changed
//                   try {
//                     final query = await FirebaseFirestore.instance
//                         .collection('categories')
//                         .where('name', isEqualTo: newName)
//                         .get();

//                     if (query.docs.isNotEmpty && query.docs.first.id != docId) {
//                       setState(() {
//                         errorMessage = 'The name already exists.';
//                       });
//                       return;
//                     }
//                   } catch (e) {
//                     log('Error checking duplicate name: $e');
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(
//                           content: Text('Error checking category name: $e')),
//                     );
//                     return;
//                   }
//                 }

//                 try {
//                   String imageUrl = currentImageUrl;
//                   Map<String, dynamic> updateData = {};

//                   // Upload new image if selected
//                   if (isImageChanged) {
//                     final storageRef = FirebaseStorage.instance
//                         .ref()
//                         .child('category_images')
//                         .child('$docId.jpg');

//                     await storageRef.putFile(selectedImage!);
//                     imageUrl = await storageRef.getDownloadURL();
//                     updateData['image'] = imageUrl;
//                   }

//                   // Add name to update data if it changed
//                   if (isNameChanged) {
//                     updateData['name'] = newName;
//                   }

//                   // Only update if there are changes
//                   if (updateData.isNotEmpty) {
//                     await FirebaseFirestore.instance
//                         .collection('categories')
//                         .doc(docId)
//                         .update(updateData);

//                     log('Category updated successfully!');
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(
//                         content: Text('Category updated successfully!'),
//                         backgroundColor: Colors.green,
//                       ),
//                     );
//                   }

//                   Navigator.pop(context);
//                 } catch (e) {
//                   log('Failed to update category: $e');
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: Text('Update failed: $e'),
//                       backgroundColor: Colors.red,
//                     ),
//                   );
//                 }
//               },
//               child: const Text('Save'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showDeleteConfirmation(BuildContext context, String docId) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Delete Category'),
//         content: const Text(
//             'Are you sure you want to delete this category? All associated subcategories will also be deleted.'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () async {
//               try {
//                 // Get a reference to Firestore
//                 final firestore = FirebaseFirestore.instance;

//                 // Get the category name before deletion
//                 final categoryDoc =
//                     await firestore.collection('categories').doc(docId).get();

//                 if (!categoryDoc.exists) {
//                   throw Exception('Category not found');
//                 }

//                 final categoryName = categoryDoc.data()?['name'];

//                 // Start a batch operation
//                 final batch = firestore.batch();

//                 // Delete all subcategories (types) associated with this category
//                 final typesSnapshot = await firestore
//                     .collection('types')
//                     .where('category', isEqualTo: categoryName)
//                     .get();

//                 // Add all subcategory deletions to batch
//                 for (var doc in typesSnapshot.docs) {
//                   batch.delete(doc.reference);
//                 }

//                 // Add category deletion to batch
//                 batch.delete(firestore.collection('categories').doc(docId));

//                 // Execute all deletions in a single atomic operation
//                 await batch.commit();

//                 // Delete the category image from storage if it exists
//                 try {
//                   final storageRef = FirebaseStorage.instance
//                       .ref()
//                       .child('category_images')
//                       .child('$docId.jpg');
//                   await storageRef.delete();
//                 } catch (e) {
//                   // Ignore storage deletion errors as the image might not exist
//                   print('Storage deletion error (non-critical): $e');
//                 }

//                 Navigator.pop(context);

//                 // Show success message
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(
//                     content: Text(
//                         'Category and associated items deleted successfully'),
//                     backgroundColor: Colors.green,
//                   ),
//                 );
//               } catch (e) {
//                 print('Error during deletion: $e');
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(
//                     content: Text('Deletion failed: $e'),
//                     backgroundColor: Colors.red,
//                   ),
//                 );
//               }
//             },
//             child: const Text('Delete'),
//             style: TextButton.styleFrom(
//               foregroundColor: Colors.red,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         body: Stack(children: [
//       ClipPath(
//           clipper: CustomAppBarClipper(),
//           child: Container(
//               height: 250,
//               decoration: BoxDecoration(
//                 color: AppColors().mainColor,
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.grey.withOpacity(0.5),
//                     spreadRadius: 5,
//                     blurRadius: 7,
//                     offset: const Offset(0, 3),
//                   ),
//                 ],
//               ),
//               child: Stack(
//                 children: [
//                   // Optional: Add a gradient overlay
//                   Container(
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         begin: Alignment.topCenter,
//                         end: Alignment.bottomCenter,
//                         colors: [
//                           Colors.transparent,
//                           AppColors().mainColor.withOpacity(0.3),
//                         ],
//                       ),
//                     ),
//                   ),
//                   Positioned(
//                     bottom: 40,
//                     left: 40,
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.end,
//                       children: [
//                         const Text(
//                           'Categories',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                             fontSize: 32,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   Positioned(
//                     top: 40,
//                     left: 20,
//                     child: IconButton(
//                         icon: Icon(
//                           Icons.arrow_back_ios,
//                           color: Colors.white,
//                           size: 28,
//                         ),
//                         onPressed: () {
//                           Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => Homepage(),
//                               ));
//                         }),
//                   ),
//                 ],
//               ))),
//       Padding(
//         padding: EdgeInsets.only(top: 250),
//         child: StreamBuilder(
//           stream: FirebaseFirestore.instance
//               .collection('categories')
//               .orderBy('createdAt', descending: true)
//               .snapshots(),
//           builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const Center(child: CircularProgressIndicator());
//             }

//             if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//               return const Center(child: Text('No categories found.'));
//             }

//             final categories = snapshot.data!.docs;

//             return GridView.builder(
//               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                 crossAxisCount: 2,
//                 crossAxisSpacing: 16,
//                 mainAxisSpacing: 16,
//                 childAspectRatio: 3 / 4,
//               ),
//               padding: const EdgeInsets.all(16),
//               itemCount: categories.length,
//               itemBuilder: (context, index) {
//                 final category =
//                     categories[index].data() as Map<String, dynamic>;
//                 final imageUrl = category['image'] ?? '';
//                 final categoryName = category['name'] ?? 'Unnamed Category';
//                 final docId = categories[index].id;

//                 return GestureDetector(
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                           builder: (context) => CategoryDetailspage(
//                                 categoryId: docId,
//                                 categoryName: categoryName,
//                                 docId: docId,
//                                 imageUrl: categoryName,
//                               )),
//                     );
//                   },
//                   child: Card(
//                     color: AppColors().mainColor,
//                     elevation: 4,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.stretch,
//                       children: [
//                         Expanded(
//                           child: imageUrl.isNotEmpty
//                               ? ClipRRect(
//                                   borderRadius: const BorderRadius.vertical(
//                                       top: Radius.circular(8)),
//                                   child: Image.network(
//                                     imageUrl,
//                                     fit: BoxFit.cover,
//                                     errorBuilder: (context, error, stackTrace) {
//                                       return const Icon(
//                                         Icons.error_outline,
//                                         color: Colors.red,
//                                         size: 30,
//                                       );
//                                     },
//                                     loadingBuilder:
//                                         (context, child, loadingProgress) {
//                                       if (loadingProgress == null) return child;
//                                       return const Center(
//                                         child: CircularProgressIndicator(),
//                                       );
//                                     },
//                                   ),
//                                 )
//                               : const Icon(
//                                   Icons.image_not_supported,
//                                   color: Colors.grey,
//                                   size: 50,
//                                 ),
//                         ),
//                         Padding(
//                           padding: const EdgeInsets.all(8.0),
//                           child: Text(
//                             categoryName,
//                             textAlign: TextAlign.center,
//                             style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16,
//                             ),
//                           ),
//                         ),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                           children: [
//                             IconButton(
//                               icon:
//                                   Icon(Icons.edit, color: AppColors().subcolor),
//                               onPressed: () =>
//                                   _showEditDialog(context, category, docId),
//                             ),
//                             IconButton(
//                               icon: Icon(Icons.delete,
//                                   color: AppColors().subcolor, size: 20),
//                               onPressed: () =>
//                                   _showDeleteConfirmation(context, docId),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             );
//           },
//         ),
//       )
//     ]));
//   }
// }

// class CustomAppBarClipper extends CustomClipper<Path> {
//   @override
//   Path getClip(Size size) {
//     Path path = Path();
//     path.lineTo(0, size.height - 50);

//     // Create a smooth curve at the bottom
//     path.quadraticBezierTo(
//       size.width / 4,
//       size.height,
//       size.width / 2,
//       size.height - 30,
//     );

//     path.quadraticBezierTo(
//       3 * size.width / 4,
//       size.height - 60,
//       size.width,
//       size.height - 20,
//     );

//     path.lineTo(size.width, 0);
//     path.close();

//     return path;
//   }

//   @override
//   bool shouldReclip(CustomClipper<Path> oldClipper) => false;
// }

import 'dart:developer';
import 'dart:io';
import 'package:cakebliss_admin/Screen/homepage.dart';
import 'package:cakebliss_admin/bloc/view1_category/state.dart';
import 'package:cakebliss_admin/category/category_screen/view2_category.dart';
import 'package:cakebliss_admin/constants/appcolor.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

// Import the BLoC files we created

class CategoryViewPage extends StatefulWidget {
  const CategoryViewPage({Key? key}) : super(key: key);

  @override
  _CategoryViewPageState createState() => _CategoryViewPageState();
}

class _CategoryViewPageState extends State<CategoryViewPage> {
  late CategoryBloc _categoryBloc;

  @override
  void initState() {
    super.initState();
    _categoryBloc = CategoryBloc();
    _categoryBloc.add(LoadCategories());
  }

  @override
  void dispose() {
    _categoryBloc.close();
    super.dispose();
  }

  void _showEditDialog(
      BuildContext context, Map<String, dynamic> category, String docId) {
    final TextEditingController nameController =
        TextEditingController(text: category['name']);
    File? selectedImage;
    String currentImageUrl = category['image'] ?? '';
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  final pickedFile = await ImagePicker()
                      .pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    setState(() {
                      selectedImage = File(pickedFile.path);
                    });
                  }
                },
                child: selectedImage != null
                    ? Image.file(selectedImage!,
                        height: 100, width: 100, fit: BoxFit.cover)
                    : Image.network(
                        currentImageUrl,
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.image_not_supported),
                      ),
              ),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Category Name',
                  errorText: errorMessage,
                ),
                onChanged: (value) {
                  setState(() {
                    errorMessage = null; // Clear error on input change
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                final isNameChanged = newName != category['name'];
                final isImageChanged = selectedImage != null;

                // Only validate name if it's being changed
                if (isNameChanged) {
                  final startsWithCapital = RegExp(r'^[A-Z]').hasMatch(newName);
                  final onlyAlphabets =
                      RegExp(r'^[A-Za-z]+$').hasMatch(newName);

                  if (newName.isEmpty) {
                    setState(() {
                      errorMessage = 'Category name cannot be empty';
                    });
                    return;
                  }
                  if (!startsWithCapital) {
                    setState(() {
                      errorMessage =
                          'Category name must begin with a capital letter.';
                    });
                    return;
                  }
                  if (!onlyAlphabets) {
                    setState(() {
                      errorMessage =
                          'Category name can only contain alphabets.';
                    });
                    return;
                  }
                }

                // If validation passes, update the category using BLoC
                Navigator.pop(context);
                _categoryBloc.add(
                  UpdateCategory(
                    id: docId,
                    name: newName,
                    image: selectedImage,
                    currentImageUrl: currentImageUrl,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: const Text(
            'Are you sure you want to delete this category? All associated subcategories will also be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _categoryBloc.add(DeleteCategory(docId));
            },
            child: const Text('Delete'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _categoryBloc,
      child: BlocListener<CategoryBloc, CategoryState>(
        listener: (context, state) {
          if (state is CategoryError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is CategoryOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        child: Scaffold(
          body: Stack(
            children: [
              ClipPath(
                clipper: CustomAppBarClipper(),
                child: Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: AppColors().mainColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors().mainColor.withOpacity(0.3),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 40,
                        left: 40,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Categories',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 32,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 40,
                        left: 20,
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Homepage(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 250),
                child: BlocBuilder<CategoryBloc, CategoryState>(
                  builder: (context, state) {
                    if (state is CategoryLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is CategoriesLoaded) {
                      final categories = state.categories;

                      if (categories.isEmpty) {
                        return const Center(
                            child: Text('No categories found.'));
                      }

                      return GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 3 / 4,
                        ),
                        padding: const EdgeInsets.all(16),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category =
                              categories[index].data() as Map<String, dynamic>;
                          final imageUrl = category['image'] ?? '';
                          final categoryName =
                              category['name'] ?? 'Unnamed Category';
                          final docId = categories[index].id;

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CategoryDetailsPage(
                                    categoryId: docId,
                                    categoryName: categoryName,
                                    docId: docId,
                                    imageUrl: categoryName,
                                  ),
                                ),
                              );
                            },
                            child: Card(
                              color: AppColors().mainColor,
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: imageUrl.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                    top: Radius.circular(8)),
                                            child: Image.network(
                                              imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return const Icon(
                                                  Icons.error_outline,
                                                  color: Colors.red,
                                                  size: 30,
                                                );
                                              },
                                              loadingBuilder: (context, child,
                                                  loadingProgress) {
                                                if (loadingProgress == null)
                                                  return child;
                                                return const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                );
                                              },
                                            ),
                                          )
                                        : const Icon(
                                            Icons.image_not_supported,
                                            color: Colors.grey,
                                            size: 50,
                                          ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      categoryName,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit,
                                            color: AppColors().subcolor),
                                        onPressed: () => _showEditDialog(
                                            context, category, docId),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete,
                                            color: AppColors().subcolor,
                                            size: 20),
                                        onPressed: () =>
                                            _showDeleteConfirmation(
                                                context, docId),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    } else if (state is CategoryError) {
                      return Center(child: Text(state.message));
                    } else {
                      return const Center(child: Text('Something went wrong'));
                    }
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddCategoryDialog(context),
            backgroundColor: AppColors().mainColor,
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    File? selectedImage;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  final pickedFile = await ImagePicker()
                      .pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    setState(() {
                      selectedImage = File(pickedFile.path);
                    });
                  }
                },
                child: Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: selectedImage != null
                      ? Image.file(selectedImage!, fit: BoxFit.cover)
                      : const Icon(Icons.add_a_photo, size: 40),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Category Name',
                  errorText: errorMessage,
                ),
                onChanged: (value) {
                  setState(() {
                    errorMessage = null; // Clear error on input change
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final name = nameController.text.trim();

                // Validate name
                if (name.isEmpty) {
                  setState(() {
                    errorMessage = 'Category name cannot be empty';
                  });
                  return;
                }

                final startsWithCapital = RegExp(r'^[A-Z]').hasMatch(name);
                if (!startsWithCapital) {
                  setState(() {
                    errorMessage =
                        'Category name must begin with a capital letter';
                  });
                  return;
                }

                final onlyAlphabets = RegExp(r'^[A-Za-z]+$').hasMatch(name);
                if (!onlyAlphabets) {
                  setState(() {
                    errorMessage = 'Category name can only contain alphabets';
                  });
                  return;
                }

                // Validate image
                if (selectedImage == null) {
                  setState(() {
                    errorMessage = 'Please select an image';
                  });
                  return;
                }

                //// Generate a unique ID for the new category
                final String categoryId = const Uuid().v4();

                // Close the dialog
                Navigator.pop(context);

                // Add the create category event to the bloc
                _categoryBloc.add(
                  CreateCategory(
                    id: categoryId,
                    name: name,
                    image: selectedImage!,
                  ),
                );
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomAppBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 50);

    // Create a smooth curve at the bottom
    path.quadraticBezierTo(
      size.width / 4,
      size.height,
      size.width / 2,
      size.height - 30,
    );

    path.quadraticBezierTo(
      3 * size.width / 4,
      size.height - 60,
      size.width,
      size.height - 20,
    );

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
