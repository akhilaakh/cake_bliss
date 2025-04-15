import 'dart:io';
import 'dart:typed_data';
import 'package:cakebliss_admin/constants/appcolor.dart';
import 'package:cakebliss_admin/offer.dart';
import 'package:cakebliss_admin/offer/list_offer.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class AddOfferPage extends StatefulWidget {
  const AddOfferPage({Key? key}) : super(key: key);

  @override
  _AddOfferPageState createState() => _AddOfferPageState();
}

class _AddOfferPageState extends State<AddOfferPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));

  List<String> _availableWeights = [
    '250g',
    '500g',
    '750g',
    '1kg',
    '1.5kg',
    '2kg',
    '2.5kg',
    '3kg'
  ];
  List<String> _selectedWeights = [];

  Map<String, double> _weightPrices = {};
  Map<String, double> _weightDiscounts = {};
  Map<String, double> _discountedPrices = {};

  List<File> _selectedImages = [];
  bool _isLoading = false;
  bool _showWeightDropdown = false;

  // Map to convert weight string to relative value
  final Map<String, double> _weightMultipliers = {
    '250g': 0.25,
    '500g': 0.5,
    '750g': 0.75,
    '1kg': 1.0,
    '1.5kg': 1.5,
    '2kg': 2.0,
    '2.5kg': 2.5,
    '3kg': 3.0,
  };

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();

    if (images.isNotEmpty) {
      setState(() {
        _selectedImages
            .addAll(images.map((image) => File(image.path)).toList());
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: isStartDate ? DateTime.now() : _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // Ensure end date is not before start date
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 1));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _toggleWeightSelection(String weight) {
    setState(() {
      if (_selectedWeights.contains(weight)) {
        _selectedWeights.remove(weight);
        _weightPrices.remove(weight);
        _weightDiscounts.remove(weight);
        _discountedPrices.remove(weight);
      } else {
        _selectedWeights.add(weight);

        // Calculate the price based on the base rate (1kg)
        double baseRate = double.tryParse(_rateController.text) ?? 0.0;
        double multiplier = _weightMultipliers[weight] ?? 1.0;
        _weightPrices[weight] = baseRate * multiplier;

        _weightDiscounts[weight] = 0.0;
        _updateDiscountedPrice(weight);
      }
    });
  }

  // Update all prices when base rate changes
  void _updateAllPrices() {
    double baseRate = double.tryParse(_rateController.text) ?? 0.0;

    for (var weight in _selectedWeights) {
      double multiplier = _weightMultipliers[weight] ?? 1.0;
      _weightPrices[weight] = baseRate * multiplier;
      _updateDiscountedPrice(weight);
    }
  }

  void _updateDiscountedPrice(String weight) {
    if (_weightPrices[weight] != null && _weightDiscounts[weight] != null) {
      setState(() {
        double originalPrice = _weightPrices[weight]!;
        double discountPercentage = _weightDiscounts[weight]!;
        double discountAmount = originalPrice * (discountPercentage / 100);
        _discountedPrices[weight] = originalPrice - discountAmount;
      });
    }
  }

  Future<void> _saveOffer() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one image')),
        );
        return;
      }

      if (_selectedWeights.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please select at least one weight option')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Generate a unique ID for the offer
        final String offerId = const Uuid().v4();

        // Upload images to Firebase Storage
        List<String> imageUrls = [];
        for (var imageFile in _selectedImages) {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('offers')
              .child(offerId)
              .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

          await storageRef.putFile(imageFile);
          final imageUrl = await storageRef.getDownloadURL();
          imageUrls.add(imageUrl);
        }

        // Prepare weight data
        List<Map<String, dynamic>> weightData = [];
        for (var weight in _selectedWeights) {
          weightData.add({
            'weight': weight,
            'price': _weightPrices[weight],
            'discount': _weightDiscounts[weight],
            'discountedPrice': _discountedPrices[weight],
          });
        }

        // Save offer data to Firestore
        await FirebaseFirestore.instance.collection('offers').doc(offerId).set({
          'name': _nameController.text,
          'description': _descriptionController.text,
          'rate': double.tryParse(_rateController.text) ?? 0.0,
          'images': imageUrls,
          'weights': weightData,
          'startDate': Timestamp.fromDate(_startDate),
          'endDate': Timestamp.fromDate(_endDate),
          'createdAt': FieldValue.serverTimestamp(),
          'isActive': true,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offer added successfully!')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OfferListPage()),
        );
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(builder: (context) => const OfferListPage()),
        // );

        // Clear the form
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding offer: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        backgroundColor: AppColors().mainColor,
        title: const Text(
          'Add Offer',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Selection
                    Text(
                      'Product Images',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 120,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          // Add image button
                          GestureDetector(
                            onTap: _pickImages,
                            child: Container(
                              width: 100,
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors().subcolor),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              margin: const EdgeInsets.only(right: 8),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate,
                                    size: 40,
                                    color: AppColors().subcolor,
                                  ),
                                  SizedBox(height: 4),
                                  Text('Add Images'),
                                ],
                              ),
                            ),
                          ),
                          // Selected images
                          ..._selectedImages.map((image) {
                            return Stack(
                              children: [
                                Container(
                                  width: 100,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: FileImage(image),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedImages.remove(image);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
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
                          }).toList(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Product Name
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Product Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter product name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Base Rate (1kg Rate)
                    TextFormField(
                      controller: _rateController,
                      decoration: const InputDecoration(
                        labelText: 'Base Rate (1kg Price)',
                        border: OutlineInputBorder(),
                        prefixText: '₹',
                        helperText:
                            'Price for 1kg (other weights will be calculated proportionally)',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter base rate';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        // Update all weight prices when base rate changes
                        if (value.isNotEmpty) {
                          _updateAllPrices();
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Weight Selection with Dropdown
                    Text(
                      'Select Weights',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showWeightDropdown = !_showWeightDropdown;
                        });
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_selectedWeights.isEmpty
                              ? 'Select Weights'
                              : '${_selectedWeights.length} weights selected'),
                          Icon(_showWeightDropdown
                              ? Icons.arrow_drop_up
                              : Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                    if (_showWeightDropdown)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _availableWeights.map((weight) {
                                final isSelected =
                                    _selectedWeights.contains(weight);
                                return FilterChip(
                                  label: Text(weight),
                                  selected: isSelected,
                                  onSelected: (_) =>
                                      _toggleWeightSelection(weight),
                                  backgroundColor: Colors.grey.shade200,
                                  selectedColor: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.3),
                                  checkmarkColor:
                                      Theme.of(context).primaryColor,
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Discount fields for selected weights
                    if (_selectedWeights.isNotEmpty) ...[
                      Text(
                        'Set Discounts',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ..._selectedWeights.map((weight) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Card(
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'For $weight:',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          decoration: const InputDecoration(
                                            labelText: 'Original Price',
                                            border: OutlineInputBorder(),
                                            prefixText: '₹',
                                            enabled: false, // Make it read-only
                                          ),
                                          initialValue: _weightPrices[weight]
                                                  ?.toStringAsFixed(2) ??
                                              '0.00',
                                          readOnly: true,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: TextFormField(
                                          decoration: const InputDecoration(
                                            labelText: 'Discount (%)',
                                            border: OutlineInputBorder(),
                                            suffixText: '%',
                                          ),
                                          keyboardType: TextInputType.number,
                                          initialValue: _weightDiscounts[weight]
                                                  ?.toString() ??
                                              '0',
                                          onChanged: (value) {
                                            setState(() {
                                              _weightDiscounts[weight] =
                                                  double.tryParse(value) ?? 0.0;
                                              _updateDiscountedPrice(weight);
                                            });
                                          },
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Required';
                                            }
                                            final discount =
                                                double.tryParse(value);
                                            if (discount == null) {
                                              return 'Invalid number';
                                            }
                                            if (discount < 0 ||
                                                discount > 100) {
                                              return 'Must be 0-100';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_discountedPrices[weight] != null) ...[
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        const Text('Discounted Price: '),
                                        const SizedBox(width: 8),
                                        Text(
                                          '₹${_discountedPrices[weight]!.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color:
                                                Theme.of(context).primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],

                    // Offer Date Range
                    Text(
                      'Offer Duration',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
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
                                DateFormat("dd/MMM/yyyy").format(_startDate),
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
                                  DateFormat("d/MMM/yyyy ").format(_endDate),
                                )),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter offer description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveOffer,
                        child: Text(
                          'SAVE OFFER',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
