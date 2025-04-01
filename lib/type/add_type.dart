import 'dart:developer';
import 'dart:io';
import 'package:cakebliss_admin/constants/appcolor.dart';
import 'package:cakebliss_admin/type/view_type.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddTypePage extends StatefulWidget {
  const AddTypePage({Key? key}) : super(key: key);

  @override
  _AddTypePageState createState() => _AddTypePageState();
}

class _AddTypePageState extends State<AddTypePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  // Form fields
  List<File> _images = [];
  List<String> _imageUrls = [];
  String _name = '';
  List<String> _selectedWeights = [];
  List<String> _selectedQuantities = [];
  double _rate = 0.0;
  String _description = '';
  bool _isQuantityVisible = false;
  bool _isLoading = false;
  String? _selectedCategory;
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  final List<String> weightOptions = [
    "1kg",
    "1.5kg",
    "2kg",
    "2.5kg",
    "3kg",
    "3.5kg",
    "4kg",
    "4.5kg"
  ];

  final List<String> quantityOptions = [
    "kg",
    "g",
  ];

  Future<void> _fetchCategories() async {
    try {
      final querySnapshot = await _firestore
          .collection('categories')
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _categories = querySnapshot.docs.map((doc) {
          return {'id': doc.id, 'name': doc['name'], 'image': doc['image']};
        }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching categories: $e")),
      );
    }
  }

  void _showCategorySelection() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return ListView.builder(
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final category = _categories[index];
            return ListTile(
              title: Text(category['name']),
              onTap: () {
                setState(() {
                  _selectedCategory = category['name'];
                });
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  // Pick multiple images from gallery
  Future<void> _pickImages() async {
    try {
      final List<XFile>? pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        setState(() {
          _images = pickedFiles.map((file) => File(file.path)).toList();
        });
        await _uploadImages();
      }
    } catch (e) {
      log("Error picking images: $e");
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking images: $e")),
      );
    }
  }

  // Upload images to Firebase Storage
  Future<void> _uploadImages() async {
    if (_images.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      _imageUrls = [];
      for (var img in _images) {
        String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        Reference ref = _storage.ref().child("types_images/$fileName");
        UploadTask uploadTask = ref.putFile(img);
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();
        _imageUrls.add(downloadUrl);
      }
    } catch (e) {
      log("Error uploading images: $e");
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error uploading images: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Save type data to Firestore
  Future<void> _saveType() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate category selection
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a category")),
      );
      return;
    }

    if (_images.isEmpty || _imageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one image")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _firestore.collection("types").add({
        "name": _name,
        "image": _imageUrls.first, // Main image
        "images": _imageUrls,
        "category": _selectedCategory, // All images
        "weights": _selectedWeights,
        "quantities": _selectedQuantities,
        "rate": _rate,
        "description": _description,
        "createdAt": FieldValue.serverTimestamp(),
      });

      log("Type added successfully");
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Type added successfully")),
      );

      // Navigate to ViewTypePage and replace current page
      // ignore: use_build_context_synchronously
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ViewTypePage(categoryName: _selectedCategory!),
          ));
    } catch (e) {
      log("Error saving type: $e");
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving type: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Show weight and quantity selection dialog
  void _showWeightSelection() async {
    List<String> selectedWeightOptions = List.from(_selectedWeights);
    List<String> selectedQuantityOptions = List.from(_selectedQuantities);

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text("Select Weights and Quantities"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Weights Section
                    const Text("Weights",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    ...weightOptions.map((String weight) {
                      return CheckboxListTile(
                        title: Text(weight),
                        value: selectedWeightOptions.contains(weight),
                        onChanged: (bool? value) {
                          setDialogState(() {
                            if (value == true) {
                              selectedWeightOptions.add(weight);
                            } else {
                              selectedWeightOptions.remove(weight);
                            }
                          });
                        },
                      );
                    }).toList(),

                    const Divider(),

                    // Quantities Section
                    const Text("Quantities",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    ...quantityOptions.map((String quantity) {
                      return CheckboxListTile(
                        title: Text(quantity),
                        value: selectedQuantityOptions.contains(quantity),
                        onChanged: (bool? value) {
                          setDialogState(() {
                            if (value == true) {
                              selectedQuantityOptions.add(quantity);
                            } else {
                              selectedQuantityOptions.remove(quantity);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedWeights = selectedWeightOptions;
                      _selectedQuantities = selectedQuantityOptions;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text("Done"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors().mainColor,
        toolbarHeight: 100,
        centerTitle: true,
        title: const Text(
          "Add New Type",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
        ],
        // flexibleSpace: Container(
        //   decoration: BoxDecoration(
        //     image: DecorationImage(
        //       image: AssetImage(
        //           'assets/Lavender Spritz Cocktail Recipe_ A Refreshing Floral Delight.jpeg'), // Replace with your image path
        //       fit: BoxFit.cover, // Ensures the image covers the entire appBar
        //     ),
        //   ),
        // ),
      ),
      body: Container(
        decoration: BoxDecoration(
            // image: DecorationImage(
            //   image: AssetImage(
            //       'assets/Lavender Spritz Cocktail Recipe_ A Refreshing Floral Delight.jpeg'), // Replace with your image path
            //   fit: BoxFit.cover, // Ensures the image covers the entire screen
            // ),
            ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Selection
                GestureDetector(
                  onTap: _isLoading ? null : _pickImages,
                  child: Container(
                    width: double.infinity,
                    height: 150, // Adjust height as needed
                    decoration: BoxDecoration(
                      color: AppColors()
                          .mainColor, // Set your preferred background color here
                      border: Border.all(color: AppColors().mainColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _images.isNotEmpty
                        ? PageView.builder(
                            itemCount: _images.length,
                            controller: PageController(
                                viewportFraction: 0.8), // Carousel effect
                            itemBuilder: (context, index) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _images[index],
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                          )
                        : const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate,
                                  size: 50,
                                  color: Colors.white,
                                ),
                                Text("Add Images"),
                              ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // Name Field
                TextFormField(
                  decoration: InputDecoration(
                    labelText: "Type Name",
                    labelStyle: TextStyle(
                      color: Colors.black
                          .withOpacity(0.3), // Adjust opacity for a light black
                    ),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: AppColors()
                        .mainColor, // Set your desired fill color here
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                  onChanged: (value) => _name = value,
                ),

                const SizedBox(height: 20),
                // Add this after the Name Field
                Container(
                  decoration: BoxDecoration(
                    color: AppColors().mainColor,
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ListTile(
                    title: Text(
                      _selectedCategory ?? "Select Category",
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.3),
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                    ),
                    onTap: _showCategorySelection,
                  ),
                ),

                const SizedBox(height: 20),

                // Weights & Quantities Selection
                Container(
                  decoration: BoxDecoration(
                    color: AppColors().mainColor, // Set your desired fill color
                    border: Border.all(color: Colors.black), // Optional border
                    borderRadius: BorderRadius.circular(4), // Rounded corners
                  ),
                  child: ListTile(
                    title: Text(
                      _selectedWeights.isEmpty
                          ? "Select Weights "
                          : "Selected: ${_selectedWeights.join(', ')}",
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.3),
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          4), // Match the container's radius
                    ),
                    onTap: _showWeightSelection,
                  ),
                ),
                const SizedBox(height: 20),

                // Rate Field
                TextFormField(
                  decoration: InputDecoration(
                    labelText: "Rate",
                    labelStyle: TextStyle(
                      color: Colors.black
                          .withOpacity(0.3), // Adjust opacity for a light black
                    ),
                    border: const OutlineInputBorder(),
                    prefixText: "₹",
                    fillColor:
                        AppColors().mainColor, // Set your desired fill color
                    filled: true, // This enables the fill color
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a rate';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                  onChanged: (value) => _rate = double.tryParse(value) ?? 0.0,
                ),

                const SizedBox(height: 20),

                // Description Field
                TextFormField(
                  decoration: InputDecoration(
                    labelText: "Description",
                    labelStyle: TextStyle(
                      color: Colors.black
                          .withOpacity(0.3), // Adjust opacity for a light black
                    ),
                    border: const OutlineInputBorder(),
                    fillColor:
                        AppColors().mainColor, // Set your desired fill color
                    filled: true, // This enables the fill color
                  ),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                  onChanged: (value) => _description = value,
                ),

                const SizedBox(height: 30),

                // Save Button
                SizedBox(
                    width: 90,
                    height: 50,
                    child: Center(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveType,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              AppColors().mainColor, // Use your desired color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                8), // Optional: for rounded corners
                          ),
                        ),
                        child: Text(
                          _isLoading ? "Saving..." : "Save",
                          style: const TextStyle(color: Colors.black),
                        ),
                      ),
                    ))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
