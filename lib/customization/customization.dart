import 'dart:io';

import 'package:cake_bliss/customization/customization_list.dart';
import 'package:cake_bliss/customization/model/model.dart';
import 'package:cake_bliss/databaseServices/database_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomizationPage extends StatefulWidget {
  const CustomizationPage({Key? key}) : super(key: key);

  @override
  _CustomizationPageState createState() => _CustomizationPageState();
}

class _CustomizationPageState extends State<CustomizationPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _weightController = TextEditingController();
  // final _priceController = TextEditingController();

  File? _selectedImage;
  String? _selectedFlavor;
  bool _isLoading = false;

  final _storage = FirebaseStorage.instance;
  final _customizationService = CustomizationService();
  final _auth = FirebaseAuth.instance;

  final List<String> _flavors = [
    'Chocolate',
    'Vanilla',
    'Strawberry',
    'Red Velvet',
    'Black Forest',
    'Butterscotch'
  ];

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<String> _uploadImage(File image) async {
    final path = 'customizations/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child(path);

    final uploadTask = await ref.putFile(image);
    return await uploadTask.ref.getDownloadURL();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() ||
        _selectedImage == null ||
        _selectedFlavor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final imageUrl = await _uploadImage(_selectedImage!);

      final customization = CustomizationModel(
        id: '', // Will be set by Firestore
        userId: _auth.currentUser!.uid,
        imageUrl: imageUrl,
        weight: double.parse(_weightController.text),
        flavor: _selectedFlavor!,
        description: _descriptionController.text,
        // budget: double.parse(_priceController.text),
      );

      await _customizationService.createCustomization(customization);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customization saved successfully!')),
        );
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => CustomizationList()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customize Your Cake'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _selectedImage != null
                      ? Image.file(_selectedImage!, fit: BoxFit.cover)
                      : const Center(child: Text('Tap to select image')),
                ),
              ),
              const SizedBox(height: 16),

              // Flavor Dropdown
              DropdownButtonFormField<String>(
                value: _selectedFlavor,
                decoration: const InputDecoration(
                  labelText: 'Flavor',
                  border: OutlineInputBorder(),
                ),
                items: _flavors.map((flavor) {
                  return DropdownMenuItem(
                    value: flavor,
                    child: Text(flavor),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFlavor = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a flavor';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Weight Input
              TextFormField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter weight';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Price Input
              // TextFormField(
              //   controller: _priceController,
              //   keyboardType: TextInputType.number,
              //   decoration: const InputDecoration(
              //     labelText: 'Budget',
              //     border: OutlineInputBorder(),
              //   ),
              //   validator: (value) {
              //     if (value == null || value.isEmpty) {
              //       return 'Please enter your budget';
              //     }
              //     if (double.tryParse(value) == null) {
              //       return 'Please enter a valid number';
              //     }
              //     return null;
              //   },
              // ),
              const SizedBox(height: 16),

              // Description Input
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _weightController.dispose();
    // _priceController.dispose();
    super.dispose();
  }
}
