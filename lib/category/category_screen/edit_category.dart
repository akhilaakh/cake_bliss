import 'dart:io';

import 'package:cakebliss_admin/constants/appcolor.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class EditTypePage extends StatefulWidget {
  final String typeId;
  final Map<String, dynamic> typeData;
  final Function? onUpdate;

  const EditTypePage(
      {Key? key, required this.typeId, required this.typeData, this.onUpdate})
      : super(key: key);

  @override
  State<EditTypePage> createState() => _EditTypePageState();
}

class _EditTypePageState extends State<EditTypePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _rateController;
  late TextEditingController _weightController;
  List<String> _weights = [];
  List<String> _imageUrls = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.typeData['name']);
    _descriptionController =
        TextEditingController(text: widget.typeData['description']);
    _rateController =
        TextEditingController(text: widget.typeData['rate'].toString());
    _weightController = TextEditingController();
    _weights = List<String>.from(widget.typeData['weights'] ?? []);
    _imageUrls = List<String>.from(widget.typeData['images'] ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _rateController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() => _isLoading = true);

      try {
        final String fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
        final Reference storageRef =
            FirebaseStorage.instance.ref().child('type_images').child(fileName);

        await storageRef.putFile(File(image.path));
        final String downloadURL = await storageRef.getDownloadURL();

        setState(() {
          _imageUrls.add(downloadURL);
          _isLoading = false;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageUrls.removeAt(index);
    });
  }

  void _addWeight() {
    if (_weightController.text.isNotEmpty) {
      setState(() {
        _weights.add(_weightController.text);
        _weightController.clear();
      });
    }
  }

  void _removeWeight(int index) {
    setState(() {
      _weights.removeAt(index);
    });
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await FirebaseFirestore.instance
            .collection('types')
            .doc(widget.typeId)
            .update({
          'name': _nameController.text,
          'description': _descriptionController.text,
          'rate': double.parse(_rateController.text),
          'weights': _weights,
          'images': _imageUrls,
        });

        if (mounted) {
          widget.onUpdate?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Changes saved successfully')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving changes: $e')),
        );
      }

      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 150,
        backgroundColor: AppColors().mainColor,
        title: const Text(
          '                  Edit Type',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(100),
            bottomRight: Radius.circular(100),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Images Section
                    const Text(
                      'Images',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _imageUrls.length + 1,
                        itemBuilder: (context, index) {
                          if (index == _imageUrls.length) {
                            return GestureDetector(
                              onTap: _pickAndUploadImage,
                              child: Container(
                                width: 120,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.add_photo_alternate),
                              ),
                            );
                          }

                          return Stack(
                            children: [
                              Container(
                                width: 120,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: NetworkImage(_imageUrls[index]),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 12,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Name Field
                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        fillColor: AppColors().mainColor, // Background color
                        filled: true, // Enable fill color
                        labelText: 'Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                              8), // Optional rounded corners
                        ),
                        hintText: 'Start with capital letter',
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter a name';
                        }
                        if (!RegExp(r'^[A-Z][a-zA-Z ]*$').hasMatch(value!)) {
                          return 'Name must start with capital letter and contain only letters';
                        }
                        return null;
                      },
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
                      ],
                    ),
                    const SizedBox(height: 16),

// Rate Field
                    TextFormField(
                      controller: _rateController,
                      decoration: InputDecoration(
                        fillColor: AppColors().mainColor, // Background color
                        filled: true, // Enable fill color
                        labelText: 'Rate',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixText: '₹',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter a rate';
                        }
                        if (double.tryParse(value!) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Description Field
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        fillColor: AppColors().mainColor,
                        filled: true,
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Replace just the weights-related section in your existing code
// Find the "Weights" section and replace it with this code:

                    const Text(
                      'Weights',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Button to open multi-select dialog with predefined weights
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            // Create a StatefulBuilder to manage state inside dialog
                            return StatefulBuilder(
                              builder: (context, setDialogState) {
                                // Predefined list of weights
                                final List<String> availableWeights =
                                    List.generate(
                                        7, (index) => '${index + 1}kg');

                                return AlertDialog(
                                  title: const Text("Select Weights"),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: availableWeights.map((weight) {
                                        return CheckboxListTile(
                                          title: Text(weight),
                                          value: _weights.contains(weight),
                                          onChanged: (bool? selected) {
                                            setDialogState(() {
                                              setState(() {
                                                if (selected == true) {
                                                  if (!_weights
                                                      .contains(weight)) {
                                                    _weights.add(weight);
                                                  }
                                                } else {
                                                  _weights.remove(weight);
                                                }
                                              });
                                            });
                                          },
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("Cancel"),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("OK"),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text("Select Weights"),
                          Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Display selected weights as chips
                    Wrap(
                      spacing: 9,
                      children: _weights
                          .map(
                            (weight) => Chip(
                              backgroundColor: AppColors().mainColor,
                              label: Text(weight),
                              onDeleted: () {
                                setState(() {
                                  _weights.remove(weight);
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors().mainColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(fontSize: 16),
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
