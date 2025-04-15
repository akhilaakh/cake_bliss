import 'dart:io';

import 'package:cakebliss_admin/constants/appcolor.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class EditOfferPage extends StatefulWidget {
  final String offerId;
  final Map<String, dynamic> offerData;

  const EditOfferPage({
    Key? key,
    required this.offerId,
    required this.offerData,
  }) : super(key: key);

  @override
  _EditOfferPageState createState() => _EditOfferPageState();
}

class _EditOfferPageState extends State<EditOfferPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late DateTime _startDate;
  late DateTime _endDate;

  // Images
  List<dynamic> _existingImages = [];
  List<XFile> _newImages = [];
  List<int> _imagesToDelete = [];

  // Weights
  List<WeightEntry> _weightEntries = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    // Initialize text controllers
    _nameController =
        TextEditingController(text: widget.offerData['name'] ?? '');
    _descriptionController =
        TextEditingController(text: widget.offerData['description'] ?? '');

    // Initialize dates
    _startDate = (widget.offerData['startDate'] as Timestamp?)?.toDate() ??
        DateTime.now();
    _endDate = (widget.offerData['endDate'] as Timestamp?)?.toDate() ??
        DateTime.now().add(const Duration(days: 7));

    // Initialize images
    _existingImages = List<dynamic>.from(widget.offerData['images'] ?? []);

    // Initialize weights
    List<dynamic> weights = widget.offerData['weights'] ?? [];
    _weightEntries = weights.map<WeightEntry>((weight) {
      return WeightEntry(
        weight: weight['weight'],
        price: weight['price']?.toDouble() ?? 0.0,
        discount: weight['discount']?.toDouble() ?? 0.0,
        discountedPrice: weight['discountedPrice']?.toDouble() ?? 0.0,
      );
    }).toList();

    // Add empty weight entry if no weights exist
    if (_weightEntries.isEmpty) {
      _weightEntries.add(WeightEntry(
        weight: '',
        price: 0.0,
        discount: 0.0,
        discountedPrice: 0.0,
      ));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Pick images from gallery
  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedImages = await _picker.pickMultiImage();
      if (pickedImages.isNotEmpty) {
        setState(() {
          _newImages.addAll(pickedImages);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e')),
      );
    }
  }

  // Remove an existing image
  void _removeExistingImage(int index) {
    setState(() {
      _imagesToDelete.add(index);
    });
  }

  // Remove a new image
  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  // Date picker
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime initialDate = isStartDate ? _startDate : _endDate;
    final DateTime firstDate = isStartDate ? DateTime.now() : _startDate;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // If end date is before new start date, update end date
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 1));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  // Add a new weight entry
  void _addWeightEntry() {
    setState(() {
      _weightEntries.add(WeightEntry(
        weight: '',
        price: 0.0,
        discount: 0.0,
        discountedPrice: 0.0,
      ));
    });
  }

  // Remove a weight entry
  void _removeWeightEntry(int index) {
    setState(() {
      _weightEntries.removeAt(index);
    });
  }

  // Choose weight from menu
  Future<void> _showWeightSelectionDialog(int index) async {
    final TextEditingController weightController = TextEditingController(
      text: _weightEntries[index].weight,
    );

    const List<String> commonWeights = [
      '100g',
      '250g',
      '500g',
      '750g',
      '1kg',
      '1.5kg',
      '2kg',
      '5kg',
      '10kg'
    ];

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Weight'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: weightController,
                      decoration: const InputDecoration(
                        labelText: 'Custom Weight',
                        hintText: 'e.g. 250g',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Common Weights:'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: commonWeights.map((String weight) {
                        return ElevatedButton(
                          onPressed: () {
                            weightController.text = weight;
                          },
                          child: Text(weight),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                setState(() {
                  _weightEntries[index].weight = weightController.text;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Calculate discounted price
  void _calculateDiscountedPrice(int index) {
    final double price = _weightEntries[index].price;
    final double discount = _weightEntries[index].discount;

    setState(() {
      _weightEntries[index].discountedPrice = price - (price * discount / 100);
    });
  }

  // Save offer
  Future<void> _saveOffer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if at least one weight entry has valid data
    bool hasValidWeight = false;
    for (var entry in _weightEntries) {
      if (entry.weight.isNotEmpty && entry.price > 0) {
        hasValidWeight = true;
        break;
      }
    }

    if (!hasValidWeight) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one valid weight')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Handle images
      List<String> updatedImageUrls = [];

      // Keep existing images that are not marked for deletion
      for (int i = 0; i < _existingImages.length; i++) {
        if (!_imagesToDelete.contains(i)) {
          updatedImageUrls.add(_existingImages[i]);
        }
      }

      // Upload new images
      for (var newImage in _newImages) {
        String fileName = DateTime.now().millisecondsSinceEpoch.toString();
        Reference storageRef = FirebaseStorage.instance
            .ref()
            .child('offers')
            .child(widget.offerId)
            .child('$fileName.jpg');

        File imageFile = File(newImage.path);
        await storageRef.putFile(imageFile);
        String downloadUrl = await storageRef.getDownloadURL();
        updatedImageUrls.add(downloadUrl);
      }

      // Remove empty or invalid weight entries
      List<WeightEntry> validWeightEntries = _weightEntries
          .where((entry) => entry.weight.isNotEmpty && entry.price > 0)
          .toList();

      // Convert weight entries to Map for Firestore
      List<Map<String, dynamic>> weightsData = validWeightEntries.map((entry) {
        return {
          'weight': entry.weight,
          'price': entry.price,
          'discount': entry.discount,
          'discountedPrice': entry.discountedPrice,
        };
      }).toList();

      // Update Firestore document
      await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offerId)
          .update({
        'name': _nameController.text,
        'description': _descriptionController.text,
        'startDate': Timestamp.fromDate(_startDate),
        'endDate': Timestamp.fromDate(_endDate),
        'images': updatedImageUrls,
        'weights': weightsData,
        'updatedAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offer updated successfully')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating offer: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors().mainColor,
        toolbarHeight: 100,
        title: const Text(
          'Edit Offer',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveOffer,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Images Section
                    _buildImagesSection(),
                    const SizedBox(height: 24),

                    // Basic Info Section
                    _buildBasicInfoSection(),
                    const SizedBox(height: 24),

                    // Validity Period Section
                    _buildValiditySection(),
                    const SizedBox(height: 24),

                    // Weights Section
                    _buildWeightsSection(),
                    const SizedBox(height: 24),

                    // Description Section
                    _buildDescriptionSection(),
                    const SizedBox(height: 40),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveOffer,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(_isLoading ? 'Saving...' : 'Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Images',
          style: TextStyle(
            color: AppColors().subcolor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // Existing Images
        if (_existingImages.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_existingImages.length, (index) {
              final bool isMarkedForDeletion = _imagesToDelete.contains(index);

              return Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                      color: isMarkedForDeletion ? Colors.grey.shade300 : null,
                    ),
                    child: isMarkedForDeletion
                        ? const Center(
                            child: Icon(Icons.delete, color: Colors.grey),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _existingImages[index],
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                  Positioned(
                    top: 5,
                    right: 5,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isMarkedForDeletion) {
                            _imagesToDelete.remove(index);
                          } else {
                            _removeExistingImage(index);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isMarkedForDeletion
                              ? Colors.blue
                              : AppColors().subcolor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isMarkedForDeletion ? Icons.undo : Icons.close,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),

        // New Images
        if (_newImages.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_newImages.length, (index) {
                return Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_newImages[index].path),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 5,
                      right: 5,
                      child: GestureDetector(
                        onTap: () => _removeNewImage(index),
                        child: Container(
                          padding: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppColors().subcolor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),

        const SizedBox(height: 12),

        // Add Image Button
        OutlinedButton.icon(
          onPressed: _pickImages,
          icon: const Icon(Icons.add_photo_alternate),
          label: const Text('Add Images'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic Information',
          style: TextStyle(
            color: AppColors().subcolor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Offer Name',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a name for this offer';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildValiditySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Validity Period',
          style: TextStyle(
            color: AppColors().subcolor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(context, true),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Start Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(
                      Icons.calendar_today,
                      color: AppColors().subcolor,
                    ),
                  ),
                  child: Text(
                    DateFormat('dd MMM yyyy').format(_startDate),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(context, false),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'End Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(
                      Icons.calendar_today,
                      color: AppColors().subcolor,
                    ),
                  ),
                  child: Text(
                    DateFormat('dd MMM yyyy').format(_endDate),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeightsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Weights & Prices',
              style: TextStyle(
                color: AppColors().subcolor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: _addWeightEntry,
              icon: const Icon(Icons.add),
              label: const Text('Add Weight'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Weight entries
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _weightEntries.length,
          itemBuilder: (context, index) {
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _showWeightSelectionDialog(index),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Weight',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.arrow_drop_down),
                              ),
                              child: Text(
                                _weightEntries[index].weight.isEmpty
                                    ? 'Select Weight'
                                    : _weightEntries[index].weight,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_weightEntries.length > 1)
                          IconButton(
                            icon:
                                Icon(Icons.delete, color: AppColors().subcolor),
                            onPressed: () => _removeWeightEntry(index),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: _weightEntries[index].price.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Original Price (₹)',
                        border: OutlineInputBorder(),
                        prefixText: '₹',
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a price';
                        }
                        if (double.tryParse(value) == null ||
                            double.parse(value) <= 0) {
                          return 'Please enter a valid price';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {
                          _weightEntries[index].price =
                              double.tryParse(value) ?? 0.0;
                          _calculateDiscountedPrice(index);
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue:
                                _weightEntries[index].discount.toString(),
                            decoration: const InputDecoration(
                              labelText: 'Discount (%)',
                              border: OutlineInputBorder(),
                              suffixText: '%',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return null;
                              }
                              double? discount = double.tryParse(value);
                              if (discount == null ||
                                  discount < 0 ||
                                  discount > 100) {
                                return 'Enter valid % (0-100)';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              setState(() {
                                _weightEntries[index].discount =
                                    double.tryParse(value) ?? 0.0;
                                _calculateDiscountedPrice(index);
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            initialValue: _weightEntries[index]
                                .discountedPrice
                                .toString(),
                            decoration: const InputDecoration(
                              labelText: 'Final Price (₹)',
                              border: OutlineInputBorder(),
                              prefixText: '₹',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            readOnly: true,
                            enabled: false,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: TextStyle(
            color: AppColors().subcolor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Offer Description',
            border: OutlineInputBorder(),
            hintText: 'Describe your offer...',
          ),
          maxLines: 5,
        ),
      ],
    );
  }
}

class WeightEntry {
  String weight;
  double price;
  double discount;
  double discountedPrice;

  WeightEntry({
    required this.weight,
    required this.price,
    required this.discount,
    required this.discountedPrice,
  });
}
