import 'package:cake_bliss/checkout/address_list.dart';
import 'package:cake_bliss/checkout/checkout_cart.dart';
import 'package:cake_bliss/constants/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddEditAddressPage extends StatefulWidget {
  final Map<String, dynamic>? address; // Pass existing address for editing

  const AddEditAddressPage({Key? key, this.address}) : super(key: key);

  @override
  State<AddEditAddressPage> createState() => _AddEditAddressPageState();
}

class _AddEditAddressPageState extends State<AddEditAddressPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  bool _isDefault = false;
  bool _isLoading = false;

  // List of Indian states
  final List<String> _indianStates = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal'
  ];

  @override
  void initState() {
    super.initState();

    if (widget.address != null) {
      _nameController.text = widget.address!['name'];
      _phoneController.text = widget.address!['phone'];
      _streetController.text = widget.address!['street'];
      _cityController.text = widget.address!['city'];
      _stateController.text = widget.address!['state'];
      _pincodeController.text = widget.address!['pincode'];
      _isDefault = widget.address!['isDefault'] ?? false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  // Validation method for name
  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your full name';
    }

    // Regex to allow only alphabets without spaces, emojis, etc.
    final nameRegex = RegExp(r'^[a-zA-Z]+$');

    if (!nameRegex.hasMatch(value)) {
      return 'Name should contain only alphabets without spaces';
    }

    return null;
  }

  // Validation method for phone number
  String? _validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your phone number';
    }

    // Regex to allow only 10 digits
    final phoneRegex = RegExp(r'^[0-9]{10}$');

    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid 10-digit phone number';
    }

    return null;
  }

  // Validation method for street address
  String? _validateStreetAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your street address';
    }

    // Regex to allow only alphabets and single spaces between words
    final streetRegex = RegExp(r'^[a-zA-Z]+( [a-zA-Z]+)*$');

    if (!streetRegex.hasMatch(value.trim())) {
      return 'Street address should contain only alphabets with single spaces';
    }

    return null;
  }

  // Validation method for city
  String? _validateCity(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your city';
    }

    // Regex to allow only alphabets without spaces, dots, commas, emojis
    final cityRegex = RegExp(r'^[a-zA-Z]+$');

    if (!cityRegex.hasMatch(value)) {
      return 'City should contain only alphabets';
    }

    return null;
  }

  // Method to show state selection bottom sheet
  void _showStateSelectionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.4,
      ),
      builder: (BuildContext context) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Select State',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors().mainColor,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _indianStates.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_indianStates[index]),
                    onTap: () {
                      setState(() {
                        _stateController.text = _indianStates[index];
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // Validation method for pincode
  String? _validatePincode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your pincode';
    }

    // Regex to allow only 6 digits
    final pincodeRegex = RegExp(r'^[0-9]{6}$');

    if (!pincodeRegex.hasMatch(value)) {
      return 'Please enter a valid 6-digit pincode';
    }

    return null;
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('You need to be logged in to save an address')),
        );
        setState(() => _isLoading = false);
        return;
      }

      final addressesCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('addresses');

      // Check if this is the first address (to make it default)
      bool makeDefault = _isDefault;
      if (!makeDefault) {
        final addressesSnapshot = await addressesCollection.get();
        if (addressesSnapshot.docs.isEmpty) {
          makeDefault = true; // First address, make it default
        }
      }

      // If making this address default, update all other addresses
      if (makeDefault) {
        final batch = FirebaseFirestore.instance.batch();
        final existingAddresses =
            await addressesCollection.where('isDefault', isEqualTo: true).get();

        for (var doc in existingAddresses.docs) {
          batch.update(doc.reference, {'isDefault': false});
        }
        await batch.commit();
      }

      final addressData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'street': _streetController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'isDefault': makeDefault,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.address != null) {
        // Update existing address
        await addressesCollection
            .doc(widget.address!['id'])
            .update(addressData);
      } else {
        // Add new address
        addressData['createdAt'] = FieldValue.serverTimestamp();
        await addressesCollection.add(addressData);
      }

      if (mounted) {
        setState(() => _isLoading = false);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Address saved successfully'),
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate to address list page
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const AddressListPage()));
      }
    } catch (e) {
      print('Error saving address: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save address: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.address != null ? 'Edit Address' : 'Add New Address'),
        backgroundColor: AppColors().mainColor,
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
                    Text(
                      'Contact Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors().mainColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Name field
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors().mainColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon:
                            Icon(Icons.person, color: AppColors().mainColor),
                      ),
                      validator: _validateName,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Phone field
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors().mainColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon:
                            Icon(Icons.phone, color: AppColors().mainColor),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: _validatePhoneNumber,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Address Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors().mainColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Street address field
                    TextFormField(
                      controller: _streetController,
                      decoration: InputDecoration(
                        labelText: 'Street Address',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors().mainColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon:
                            Icon(Icons.home, color: AppColors().mainColor),
                      ),
                      validator: _validateStreetAddress,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
                      ],
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    // City field
                    TextFormField(
                      controller: _cityController,
                      decoration: InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors().mainColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(Icons.location_city,
                            color: AppColors().mainColor),
                      ),
                      validator: _validateCity,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // State field
                    TextFormField(
                      controller: _stateController,
                      decoration: InputDecoration(
                        labelText: 'State',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors().mainColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon:
                            Icon(Icons.map, color: AppColors().mainColor),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.arrow_drop_down,
                              color: AppColors().mainColor),
                          onPressed: _showStateSelectionSheet,
                        ),
                      ),
                      readOnly: true,
                      onTap: _showStateSelectionSheet,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please select your state';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Pincode field
                    TextFormField(
                      controller: _pincodeController,
                      decoration: InputDecoration(
                        labelText: 'Pincode',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors().mainColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon:
                            Icon(Icons.pin_drop, color: AppColors().mainColor),
                      ),
                      keyboardType: TextInputType.number,
                      validator: _validatePincode,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Default address checkbox
                    CheckboxListTile(
                      title: const Text('Make this my default address'),
                      value: _isDefault,
                      onChanged: (value) {
                        setState(() {
                          _isDefault = value ?? false;
                        });
                      },
                      activeColor: AppColors().mainColor,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 32),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveAddress,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors().mainColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          widget.address != null
                              ? 'Update Address'
                              : 'Save Address',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
