import 'dart:io';
import 'package:cakebliss_admin/bloc/Category_add/bloc.dart';
import 'package:cakebliss_admin/bloc/Category_add/event.dart';
import 'package:cakebliss_admin/bloc/Category_add/state.dart';
import 'package:cakebliss_admin/category/category_screen/view1_category.dart';
import 'package:cakebliss_admin/constants/appcolor.dart';
import 'package:cakebliss_admin/databaseservices/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddCategoryScreen extends StatelessWidget {
  final TextEditingController _categoryNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider(
        create: (context) => CategoryBloc(DatabaseService(),
            firestore: FirebaseFirestore.instance),
        child: BlocConsumer<CategoryBloc, CategoryState>(
          listener: (context, state) {
            if (state is CategorySaved) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors().mainColor,
                ),
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CategoryViewPage(),
                ),
              );
            } else if (state is CategoryError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            File? imageFile;
            if (state is CategoryImagePicked) {
              imageFile = state.imageFile;
            }
            return Stack(
              children: [
                // Background Image
                Positioned.fill(
                  child: Image.asset(
                    'assets/Lemon Lavender Cupcakes _ The Cake Blog.jpeg',
                    fit: BoxFit.cover,
                    opacity: const AlwaysStoppedAnimation(0.9),
                  ),
                ),

                // Title Section
                Positioned(
                  top: MediaQuery.of(context).padding.top + 20,
                  left: 0,
                  right: 0,
                  child: const Center(
                    child: Text(
                      'Add Category',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                ),

                // Main Content with Curve
                Positioned.fill(
                  top: MediaQuery.of(context).size.height * 0.5,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors().mainColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(60),
                        topRight: Radius.circular(60),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 45),
                          GestureDetector(
                            onTap: () => context
                                .read<CategoryBloc>()
                                .add(PickImageEvent()),
                            child: Container(
                              height: 100,
                              width: 100,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                border: Border.all(color: Colors.white),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: imageFile != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(imageFile,
                                          fit: BoxFit.cover),
                                    )
                                  : const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_a_photo,
                                            size: 30, color: Colors.white),
                                        SizedBox(height: 4),
                                        Text(
                                          'Add Image',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 45),
                          TextField(
                            controller: _categoryNameController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.transparent,
                              labelText: 'Category Name',
                              labelStyle: const TextStyle(color: Colors.white),
                              floatingLabelStyle:
                                  const TextStyle(color: Colors.black),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: AppColors().subcolor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    const BorderSide(color: Colors.white),
                              ),
                            ),
                            style: const TextStyle(color: Colors.black),
                          ),
                          const SizedBox(height: 45),
                          SizedBox(
                            width: 100,
                            height: 45,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors().mainColor,
                              ),
                              onPressed: state is CategorySaving
                                  ? null
                                  : () async {
                                      final categoryName =
                                          _categoryNameController.text.trim();

                                      // Basic validation for empty field
                                      if (categoryName.isEmpty) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Please provide a category name!'),
                                          ),
                                        );
                                        return;
                                      }

                                      if (!RegExp(r'^[A-Z]')
                                          .hasMatch(categoryName)) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Category name must start with a capital letter!'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }

                                      // Validate image
                                      if (imageFile == null) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content:
                                                Text('Please add an image!'),
                                          ),
                                        );
                                        return;
                                      }

                                      // Check for duplicate category
                                      try {
                                        final querySnapshot =
                                            await FirebaseFirestore.instance
                                                .collection("categories")
                                                .where("name",
                                                    isEqualTo: categoryName)
                                                .get();

                                        if (querySnapshot.docs.isNotEmpty) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Category name already exists!'),
                                            ),
                                          );
                                          return;
                                        }

                                        // Save category if all validations pass
                                        context.read<CategoryBloc>().add(
                                              SaveCategoryEvent(
                                                categoryName: categoryName,
                                                imageFile: imageFile,
                                              ),
                                            );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Error checking category: $e'),
                                          ),
                                        );
                                      }
                                    },
                              child: state is CategorySaving
                                  ? const CircularProgressIndicator()
                                  : const Text('Save',
                                      style: TextStyle(fontSize: 16)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Back Button
                Positioned(
                  top: MediaQuery.of(context).padding.top + 20,
                  left: 20,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios,
                        color: AppColors().mainColor),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
