// import 'dart:io';
// import 'dart:typed_data';
// import 'package:cakebliss_admin/constants/appcolor.dart';
// import 'package:carousel_slider/carousel_slider.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_chat_ui/flutter_chat_ui.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import 'package:uuid/uuid.dart';

// class AddOfferPage extends StatefulWidget {
//   const AddOfferPage({Key? key}) : super(key: key);

//   @override
//   _AddOfferPageState createState() => _AddOfferPageState();
// }

// class _AddOfferPageState extends State<AddOfferPage> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _descriptionController = TextEditingController();
//   final TextEditingController _rateController = TextEditingController();

//   DateTime _startDate = DateTime.now();
//   DateTime _endDate = DateTime.now().add(const Duration(days: 7));

//   List<String> _availableWeights = [
//     '250g',
//     '500g',
//     '750g',
//     '1kg',
//     '1.5kg',
//     '2kg',
//     '2.5kg',
//     '3kg'
//   ];
//   List<String> _selectedWeights = [];

//   Map<String, double> _weightPrices = {};
//   Map<String, double> _weightDiscounts = {};
//   Map<String, double> _discountedPrices = {};

//   List<File> _selectedImages = [];
//   bool _isLoading = false;
//   bool _showWeightDropdown = false;

//   // Map to convert weight string to relative value
//   final Map<String, double> _weightMultipliers = {
//     '250g': 0.25,
//     '500g': 0.5,
//     '750g': 0.75,
//     '1kg': 1.0,
//     '1.5kg': 1.5,
//     '2kg': 2.0,
//     '2.5kg': 2.5,
//     '3kg': 3.0,
//   };

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _descriptionController.dispose();
//     _rateController.dispose();
//     super.dispose();
//   }

//   Future<void> _pickImages() async {
//     final ImagePicker picker = ImagePicker();
//     final List<XFile> images = await picker.pickMultiImage();

//     if (images.isNotEmpty) {
//       setState(() {
//         _selectedImages
//             .addAll(images.map((image) => File(image.path)).toList());
//       });
//     }
//   }

//   Future<void> _selectDate(BuildContext context, bool isStartDate) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: isStartDate ? _startDate : _endDate,
//       firstDate: isStartDate ? DateTime.now() : _startDate,
//       lastDate: DateTime.now().add(const Duration(days: 365)),
//     );

//     if (picked != null) {
//       setState(() {
//         if (isStartDate) {
//           _startDate = picked;
//           // Ensure end date is not before start date
//           if (_endDate.isBefore(_startDate)) {
//             _endDate = _startDate.add(const Duration(days: 1));
//           }
//         } else {
//           _endDate = picked;
//         }
//       });
//     }
//   }

//   void _toggleWeightSelection(String weight) {
//     setState(() {
//       if (_selectedWeights.contains(weight)) {
//         _selectedWeights.remove(weight);
//         _weightPrices.remove(weight);
//         _weightDiscounts.remove(weight);
//         _discountedPrices.remove(weight);
//       } else {
//         _selectedWeights.add(weight);

//         // Calculate the price based on the base rate (1kg)
//         double baseRate = double.tryParse(_rateController.text) ?? 0.0;
//         double multiplier = _weightMultipliers[weight] ?? 1.0;
//         _weightPrices[weight] = baseRate * multiplier;

//         _weightDiscounts[weight] = 0.0;
//         _updateDiscountedPrice(weight);
//       }
//     });
//   }

//   // Update all prices when base rate changes
//   void _updateAllPrices() {
//     double baseRate = double.tryParse(_rateController.text) ?? 0.0;

//     for (var weight in _selectedWeights) {
//       double multiplier = _weightMultipliers[weight] ?? 1.0;
//       _weightPrices[weight] = baseRate * multiplier;
//       _updateDiscountedPrice(weight);
//     }
//   }

//   void _updateDiscountedPrice(String weight) {
//     if (_weightPrices[weight] != null && _weightDiscounts[weight] != null) {
//       setState(() {
//         double originalPrice = _weightPrices[weight]!;
//         double discountPercentage = _weightDiscounts[weight]!;
//         double discountAmount = originalPrice * (discountPercentage / 100);
//         _discountedPrices[weight] = originalPrice - discountAmount;
//       });
//     }
//   }

//   Future<void> _saveOffer() async {
//     if (_formKey.currentState!.validate()) {
//       if (_selectedImages.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Please select at least one image')),
//         );
//         return;
//       }

//       if (_selectedWeights.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//               content: Text('Please select at least one weight option')),
//         );
//         return;
//       }

//       setState(() {
//         _isLoading = true;
//       });

//       try {
//         // Generate a unique ID for the offer
//         final String offerId = const Uuid().v4();

//         // Upload images to Firebase Storage
//         List<String> imageUrls = [];
//         for (var imageFile in _selectedImages) {
//           final storageRef = FirebaseStorage.instance
//               .ref()
//               .child('offers')
//               .child(offerId)
//               .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

//           await storageRef.putFile(imageFile);
//           final imageUrl = await storageRef.getDownloadURL();
//           imageUrls.add(imageUrl);
//         }

//         // Prepare weight data
//         List<Map<String, dynamic>> weightData = [];
//         for (var weight in _selectedWeights) {
//           weightData.add({
//             'weight': weight,
//             'price': _weightPrices[weight],
//             'discount': _weightDiscounts[weight],
//             'discountedPrice': _discountedPrices[weight],
//           });
//         }

//         // Save offer data to Firestore
//         await FirebaseFirestore.instance.collection('offers').doc(offerId).set({
//           'name': _nameController.text,
//           'description': _descriptionController.text,
//           'rate': double.tryParse(_rateController.text) ?? 0.0,
//           'images': imageUrls,
//           'weights': weightData,
//           'startDate': Timestamp.fromDate(_startDate),
//           'endDate': Timestamp.fromDate(_endDate),
//           'createdAt': FieldValue.serverTimestamp(),
//           'isActive': true,
//         });

//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Offer added successfully!')),
//         );
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => const OfferListPage()),
//         );
//         // Navigator.pushReplacement(
//         //   context,
//         //   MaterialPageRoute(builder: (context) => const OfferListPage()),
//         // );

//         // Clear the form
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error adding offer: $e')),
//         );
//       } finally {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         toolbarHeight: 100,
//         backgroundColor: AppColors().mainColor,
//         title: const Text(
//           'Add Offer',
//           style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(16.0),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Image Selection
//                     Text(
//                       'Product Images',
//                       style: Theme.of(context).textTheme.titleMedium,
//                     ),
//                     const SizedBox(height: 8),
//                     Container(
//                       height: 120,
//                       child: ListView(
//                         scrollDirection: Axis.horizontal,
//                         children: [
//                           // Add image button
//                           GestureDetector(
//                             onTap: _pickImages,
//                             child: Container(
//                               width: 100,
//                               decoration: BoxDecoration(
//                                 border: Border.all(color: AppColors().subcolor),
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               margin: const EdgeInsets.only(right: 8),
//                               child: Column(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Icon(
//                                     Icons.add_photo_alternate,
//                                     size: 40,
//                                     color: AppColors().subcolor,
//                                   ),
//                                   SizedBox(height: 4),
//                                   Text('Add Images'),
//                                 ],
//                               ),
//                             ),
//                           ),
//                           // Selected images
//                           ..._selectedImages.map((image) {
//                             return Stack(
//                               children: [
//                                 Container(
//                                   width: 100,
//                                   margin: const EdgeInsets.only(right: 8),
//                                   decoration: BoxDecoration(
//                                     borderRadius: BorderRadius.circular(8),
//                                     image: DecorationImage(
//                                       image: FileImage(image),
//                                       fit: BoxFit.cover,
//                                     ),
//                                   ),
//                                 ),
//                                 Positioned(
//                                   top: 0,
//                                   right: 0,
//                                   child: GestureDetector(
//                                     onTap: () {
//                                       setState(() {
//                                         _selectedImages.remove(image);
//                                       });
//                                     },
//                                     child: Container(
//                                       padding: const EdgeInsets.all(2),
//                                       decoration: const BoxDecoration(
//                                         color: Colors.red,
//                                         shape: BoxShape.circle,
//                                       ),
//                                       child: const Icon(
//                                         Icons.close,
//                                         color: Colors.white,
//                                         size: 16,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             );
//                           }).toList(),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 16),

//                     // Product Name
//                     TextFormField(
//                       controller: _nameController,
//                       decoration: InputDecoration(
//                         labelText: 'Product Name',
//                         border: OutlineInputBorder(),
//                       ),
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please enter product name';
//                         }
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 16),

//                     // Base Rate (1kg Rate)
//                     TextFormField(
//                       controller: _rateController,
//                       decoration: const InputDecoration(
//                         labelText: 'Base Rate (1kg Price)',
//                         border: OutlineInputBorder(),
//                         prefixText: '₹',
//                         helperText:
//                             'Price for 1kg (other weights will be calculated proportionally)',
//                       ),
//                       keyboardType: TextInputType.number,
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please enter base rate';
//                         }
//                         if (double.tryParse(value) == null) {
//                           return 'Please enter a valid number';
//                         }
//                         return null;
//                       },
//                       onChanged: (value) {
//                         // Update all weight prices when base rate changes
//                         if (value.isNotEmpty) {
//                           _updateAllPrices();
//                         }
//                       },
//                     ),
//                     const SizedBox(height: 16),

//                     // Weight Selection with Dropdown
//                     Text(
//                       'Select Weights',
//                       style: Theme.of(context).textTheme.titleMedium,
//                     ),
//                     const SizedBox(height: 8),
//                     ElevatedButton(
//                       onPressed: () {
//                         setState(() {
//                           _showWeightDropdown = !_showWeightDropdown;
//                         });
//                       },
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Text(_selectedWeights.isEmpty
//                               ? 'Select Weights'
//                               : '${_selectedWeights.length} weights selected'),
//                           Icon(_showWeightDropdown
//                               ? Icons.arrow_drop_up
//                               : Icons.arrow_drop_down),
//                         ],
//                       ),
//                     ),
//                     if (_showWeightDropdown)
//                       Container(
//                         margin: const EdgeInsets.only(top: 8),
//                         padding: const EdgeInsets.all(12),
//                         decoration: BoxDecoration(
//                           border: Border.all(color: Colors.grey.shade300),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Wrap(
//                               spacing: 8,
//                               runSpacing: 8,
//                               children: _availableWeights.map((weight) {
//                                 final isSelected =
//                                     _selectedWeights.contains(weight);
//                                 return FilterChip(
//                                   label: Text(weight),
//                                   selected: isSelected,
//                                   onSelected: (_) =>
//                                       _toggleWeightSelection(weight),
//                                   backgroundColor: Colors.grey.shade200,
//                                   selectedColor: Theme.of(context)
//                                       .primaryColor
//                                       .withOpacity(0.3),
//                                   checkmarkColor:
//                                       Theme.of(context).primaryColor,
//                                 );
//                               }).toList(),
//                             ),
//                           ],
//                         ),
//                       ),
//                     const SizedBox(height: 16),

//                     // Discount fields for selected weights
//                     if (_selectedWeights.isNotEmpty) ...[
//                       Text(
//                         'Set Discounts',
//                         style: Theme.of(context).textTheme.titleMedium,
//                       ),
//                       const SizedBox(height: 8),
//                       ..._selectedWeights.map((weight) {
//                         return Padding(
//                           padding: const EdgeInsets.only(bottom: 16),
//                           child: Card(
//                             elevation: 2,
//                             child: Padding(
//                               padding: const EdgeInsets.all(12),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     'For $weight:',
//                                     style: const TextStyle(
//                                         fontWeight: FontWeight.bold),
//                                   ),
//                                   const SizedBox(height: 12),
//                                   Row(
//                                     children: [
//                                       Expanded(
//                                         child: TextFormField(
//                                           decoration: const InputDecoration(
//                                             labelText: 'Original Price',
//                                             border: OutlineInputBorder(),
//                                             prefixText: '₹',
//                                             enabled: false, // Make it read-only
//                                           ),
//                                           initialValue: _weightPrices[weight]
//                                                   ?.toStringAsFixed(2) ??
//                                               '0.00',
//                                           readOnly: true,
//                                         ),
//                                       ),
//                                       const SizedBox(width: 16),
//                                       Expanded(
//                                         child: TextFormField(
//                                           decoration: const InputDecoration(
//                                             labelText: 'Discount (%)',
//                                             border: OutlineInputBorder(),
//                                             suffixText: '%',
//                                           ),
//                                           keyboardType: TextInputType.number,
//                                           initialValue: _weightDiscounts[weight]
//                                                   ?.toString() ??
//                                               '0',
//                                           onChanged: (value) {
//                                             setState(() {
//                                               _weightDiscounts[weight] =
//                                                   double.tryParse(value) ?? 0.0;
//                                               _updateDiscountedPrice(weight);
//                                             });
//                                           },
//                                           validator: (value) {
//                                             if (value == null ||
//                                                 value.isEmpty) {
//                                               return 'Required';
//                                             }
//                                             final discount =
//                                                 double.tryParse(value);
//                                             if (discount == null) {
//                                               return 'Invalid number';
//                                             }
//                                             if (discount < 0 ||
//                                                 discount > 100) {
//                                               return 'Must be 0-100';
//                                             }
//                                             return null;
//                                           },
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                   if (_discountedPrices[weight] != null) ...[
//                                     const SizedBox(height: 16),
//                                     Row(
//                                       children: [
//                                         const Text('Discounted Price: '),
//                                         const SizedBox(width: 8),
//                                         Text(
//                                           '₹${_discountedPrices[weight]!.toStringAsFixed(2)}',
//                                           style: TextStyle(
//                                             fontWeight: FontWeight.bold,
//                                             color:
//                                                 Theme.of(context).primaryColor,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ],
//                                 ],
//                               ),
//                             ),
//                           ),
//                         );
//                       }).toList(),
//                     ],

//                     // Offer Date Range
//                     Text(
//                       'Offer Duration',
//                       style: Theme.of(context).textTheme.titleMedium,
//                     ),
//                     const SizedBox(height: 8),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: InkWell(
//                             onTap: () => _selectDate(context, true),
//                             child: InputDecorator(
//                               decoration: InputDecoration(
//                                 labelText: 'Start Date',
//                                 border: OutlineInputBorder(),
//                                 suffixIcon: Icon(
//                                   Icons.calendar_today,
//                                   color: AppColors().subcolor,
//                                 ),
//                               ),
//                               child: Text(
//                                 DateFormat("dd/MMM/yyyy").format(_startDate),
//                               ),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 16),
//                         Expanded(
//                           child: InkWell(
//                             onTap: () => _selectDate(context, false),
//                             child: InputDecorator(
//                                 decoration: InputDecoration(
//                                   labelText: 'End Date',
//                                   border: OutlineInputBorder(),
//                                   suffixIcon: Icon(
//                                     Icons.calendar_today,
//                                     color: AppColors().subcolor,
//                                   ),
//                                 ),
//                                 child: Text(
//                                   DateFormat("d/MMM/yyyy ").format(_endDate),
//                                 )),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 16),

//                     // Description
//                     TextFormField(
//                       controller: _descriptionController,
//                       decoration: const InputDecoration(
//                         labelText: 'Description',
//                         border: OutlineInputBorder(),
//                         alignLabelWithHint: true,
//                       ),
//                       maxLines: 5,
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please enter offer description';
//                         }
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 24),

//                     // Submit Button
//                     SizedBox(
//                       width: double.infinity,
//                       height: 50,
//                       child: ElevatedButton(
//                         onPressed: _saveOffer,
//                         child: Text(
//                           'SAVE OFFER',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//     );
//   }
// }

// class OfferListPage extends StatefulWidget {
//   const OfferListPage({Key? key}) : super(key: key);

//   @override
//   _OfferListPageState createState() => _OfferListPageState();
// }

// class _OfferListPageState extends State<OfferListPage> {
//   bool _isLoading = false;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         toolbarHeight: 100,
//         backgroundColor: AppColors().mainColor,
//         title: const Text(
//           'Offers',
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.add),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => const AddOfferPage()),
//               );
//             },
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : StreamBuilder<QuerySnapshot>(
//               stream: FirebaseFirestore.instance
//                   .collection('offers')
//                   .where('isActive', isEqualTo: true)
//                   .orderBy('createdAt', descending: true)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 if (snapshot.hasError) {
//                   return Center(
//                     child: Text('Error: ${snapshot.error}'),
//                   );
//                 }

//                 if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                   return const Center(
//                     child: Text('No offers available'),
//                   );
//                 }

//                 return GridView.builder(
//                   padding: const EdgeInsets.all(16),
//                   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                     crossAxisCount: 2,
//                     crossAxisSpacing: 12,
//                     mainAxisSpacing: 12,
//                     childAspectRatio: 0.75,
//                   ),
//                   itemCount: snapshot.data!.docs.length,
//                   itemBuilder: (context, index) {
//                     final doc = snapshot.data!.docs[index];
//                     final data = doc.data() as Map<String, dynamic>;
//                     final String offerId = doc.id;

//                     List<dynamic> images = data['images'] ?? [];
//                     String imageUrl = images.isNotEmpty ? images[0] : '';

//                     List<dynamic> weights = data['weights'] ?? [];
//                     double? lowestPrice;

//                     if (weights.isNotEmpty) {
//                       for (var weight in weights) {
//                         final double discountedPrice =
//                             weight['discountedPrice'] ?? 0.0;
//                         if (lowestPrice == null ||
//                             discountedPrice < lowestPrice) {
//                           lowestPrice = discountedPrice;
//                         }
//                       }
//                     }

//                     return GestureDetector(
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) =>
//                                 OfferDetailPage(offerId: offerId),
//                           ),
//                         );
//                       },
//                       child: Card(
//                         elevation: 3,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             // Image
//                             Expanded(
//                               child: Container(
//                                 width: double.infinity,
//                                 decoration: BoxDecoration(
//                                   borderRadius: const BorderRadius.vertical(
//                                     top: Radius.circular(10),
//                                   ),
//                                   image: imageUrl.isNotEmpty
//                                       ? DecorationImage(
//                                           image: NetworkImage(imageUrl),
//                                           fit: BoxFit.cover,
//                                         )
//                                       : null,
//                                 ),
//                                 child: imageUrl.isEmpty
//                                     ? const Center(
//                                         child: Icon(
//                                           Icons.image_not_supported,
//                                           size: 40,
//                                           color: Colors.grey,
//                                         ),
//                                       )
//                                     : null,
//                               ),
//                             ),

//                             // Name and Price
//                             Padding(
//                               padding: const EdgeInsets.all(12.0),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     data['name'] ?? 'No Name',
//                                     style: const TextStyle(
//                                       fontWeight: FontWeight.bold,
//                                       fontSize: 16,
//                                     ),
//                                     maxLines: 1,
//                                     overflow: TextOverflow.ellipsis,
//                                   ),
//                                   const SizedBox(height: 6),
//                                   if (lowestPrice != null)
//                                     Text(
//                                       'From ₹${lowestPrice.toStringAsFixed(2)}',
//                                       style: TextStyle(
//                                         color: Theme.of(context).primaryColor,
//                                         fontWeight: FontWeight.w500,
//                                       ),
//                                     ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//     );
//   }
// }

// class OfferDetailPage extends StatefulWidget {
//   final String offerId;

//   const OfferDetailPage({Key? key, required this.offerId}) : super(key: key);

//   @override
//   _OfferDetailPageState createState() => _OfferDetailPageState();
// }

// class _OfferDetailPageState extends State<OfferDetailPage> {
//   bool _isLoading = true;
//   Map<String, dynamic>? _offerData;
//   int _currentImageIndex = 0;
//   String _selectedWeight = '';

//   @override
//   void initState() {
//     super.initState();
//     _fetchOfferData();
//   }

//   Future<void> _fetchOfferData() async {
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final docSnapshot = await FirebaseFirestore.instance
//           .collection('offers')
//           .doc(widget.offerId)
//           .get();

//       if (docSnapshot.exists) {
//         setState(() {
//           _offerData = docSnapshot.data();
//           _isLoading = false;

//           // Set the first weight as selected by default
//           List<dynamic> weights = _offerData?['weights'] ?? [];
//           if (weights.isNotEmpty) {
//             _selectedWeight = weights[0]['weight'];
//           }
//         });
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Offer not found')),
//         );
//         Navigator.pop(context);
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading offer: $e')),
//       );
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   // Get weight details based on selected weight
//   Map<String, dynamic>? _getSelectedWeightDetails() {
//     if (_offerData == null) return null;

//     List<dynamic> weights = _offerData!['weights'] ?? [];
//     for (var weight in weights) {
//       if (weight['weight'] == _selectedWeight) {
//         return weight;
//       }
//     }
//     return null;
//   }

//   Future<void> _showDeleteConfirmation() async {
//     return showDialog<void>(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Delete Offer'),
//           content: const Text('Are you sure you want to delete this offer?'),
//           actions: <Widget>[
//             TextButton(
//               child: const Text('No'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//             TextButton(
//               child: const Text('Yes', style: TextStyle(color: Colors.red)),
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 _deleteOffer();
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // Delete the offer
//   Future<void> _deleteOffer() async {
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       await FirebaseFirestore.instance
//           .collection('offers')
//           .doc(widget.offerId)
//           .delete();

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Offer deleted successfully')),
//       );
//       Navigator.pop(context);
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error deleting offer: $e')),
//       );
//     }
//   }

//   // Navigate to edit page
//   void _navigateToEditPage() async {
//     final result = await Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => EditOfferPage(
//           offerId: widget.offerId,
//           offerData: _offerData!,
//         ),
//       ),
//     );

//     // If the edit was successful, refresh the data
//     if (result == true) {
//       _fetchOfferData();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         // title: Text(_offerData?['name'] ?? 'Offer Details'),
//         // centerTitle: true,
//         actions: [
//           if (!_isLoading && _offerData != null)
//             PopupMenuButton<String>(
//               onSelected: (value) {
//                 if (value == 'edit') {
//                   _navigateToEditPage();
//                 } else if (value == 'delete') {
//                   _showDeleteConfirmation();
//                 }
//               },
//               itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
//                 const PopupMenuItem<String>(
//                   value: 'edit',
//                   child: Row(
//                     children: [
//                       Icon(Icons.edit),
//                       SizedBox(width: 8),
//                       Text('Edit'),
//                     ],
//                   ),
//                 ),
//                 const PopupMenuItem<String>(
//                   value: 'delete',
//                   child: Row(
//                     children: [
//                       Icon(Icons.delete, color: Colors.red),
//                       SizedBox(width: 8),
//                       Text('Delete', style: TextStyle(color: Colors.red)),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Image Carousel
//                   _buildImageCarousel(),

//                   // Product Info
//                   Padding(
//                     padding: const EdgeInsets.all(16.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // Product Name
//                         Text(
//                           _offerData?['name'] ?? 'No Name',
//                           style: const TextStyle(
//                             fontSize: 24,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 8),

//                         // Offer Duration
//                         _buildOfferDuration(),
//                         const SizedBox(height: 16),

//                         // Weight Options
//                         _buildWeightOptions(),
//                         const SizedBox(height: 24),

//                         // Price Details
//                         _buildPriceDetails(),
//                         const SizedBox(height: 24),

//                         // Description
//                         const Text(
//                           'Description',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           _offerData?['description'] ??
//                               'No description available',
//                           style: const TextStyle(
//                             fontSize: 16,
//                             height: 1.5,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }

//   Widget _buildImageCarousel() {
//     List<dynamic> images = _offerData?['images'] ?? [];

//     return Column(
//       children: [
//         if (images.isEmpty)
//           Container(
//             height: 250,
//             color: Colors.transparent,
//             child: const Center(
//               child: Icon(
//                 Icons.image_not_supported,
//                 size: 50,
//                 color: Colors.transparent,
//               ),
//             ),
//           )
//         else
//           Column(
//             children: [
//               CarouselSlider(
//                 options: CarouselOptions(
//                   height: 300,
//                   viewportFraction: 1.0,
//                   enlargeCenterPage: false,
//                   enableInfiniteScroll: images.length > 1,
//                   onPageChanged: (index, reason) {
//                     setState(() {
//                       _currentImageIndex = index;
//                     });
//                   },
//                 ),
//                 items: images.map<Widget>((imageUrl) {
//                   return Container(
//                     width: MediaQuery.of(context).size.width,
//                     color: Colors.transparent,
//                     child: Image.network(
//                       imageUrl,
//                       fit: BoxFit.cover,
//                       loadingBuilder: (context, child, loadingProgress) {
//                         if (loadingProgress == null) return child;
//                         return Center(
//                           child: CircularProgressIndicator(
//                             value: loadingProgress.expectedTotalBytes != null
//                                 ? loadingProgress.cumulativeBytesLoaded /
//                                     loadingProgress.expectedTotalBytes!
//                                 : null,
//                           ),
//                         );
//                       },
//                       errorBuilder: (context, error, stackTrace) {
//                         return const Center(
//                           child: Icon(
//                             Icons.broken_image,
//                             size: 50,
//                             color: Colors.grey,
//                           ),
//                         );
//                       },
//                     ),
//                   );
//                 }).toList(),
//               ),
//               const SizedBox(height: 8),
//               if (images.length > 1)
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: images.asMap().entries.map((entry) {
//                     return Container(
//                       width: 8.0,
//                       height: 8.0,
//                       margin: const EdgeInsets.symmetric(horizontal: 4.0),
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         color: _currentImageIndex == entry.key
//                             ? Theme.of(context).primaryColor
//                             : Colors.grey.shade400,
//                       ),
//                     );
//                   }).toList(),
//                 ),
//             ],
//           ),
//       ],
//     );
//   }

//   Widget _buildOfferDuration() {
//     final startDate = (_offerData?['startDate'] as Timestamp?)?.toDate();
//     final endDate = (_offerData?['endDate'] as Timestamp?)?.toDate();

//     if (startDate == null || endDate == null) {
//       return const SizedBox.shrink();
//     }

//     final now = DateTime.now();
//     final isActive = now.isAfter(startDate) && now.isBefore(endDate);

//     return Row(
//       children: [
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//           decoration: BoxDecoration(
//             color: isActive ? Colors.green.shade100 : Colors.orange.shade100,
//             borderRadius: BorderRadius.circular(4),
//           ),
//           child: Text(
//             isActive ? 'Active' : 'Upcoming',
//             style: TextStyle(
//               color: isActive ? Colors.green.shade700 : Colors.orange.shade700,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//         const SizedBox(width: 8),
//         Text(
//           'Valid: ${DateFormat('dd MMM').format(startDate)} - ${DateFormat('dd MMM').format(endDate)}',
//           style: TextStyle(
//             color: Colors.grey.shade700,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildWeightOptions() {
//     List<dynamic> weights = _offerData?['weights'] ?? [];

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Select Weight',
//           style: TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         const SizedBox(height: 12),
//         Wrap(
//           spacing: 8,
//           runSpacing: 8,
//           children: weights.map<Widget>((weight) {
//             final String weightStr = weight['weight'];
//             final bool isSelected = _selectedWeight == weightStr;

//             return GestureDetector(
//               onTap: () {
//                 setState(() {
//                   _selectedWeight = weightStr;
//                 });
//               },
//               child: Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 16,
//                   vertical: 10,
//                 ),
//                 decoration: BoxDecoration(
//                   color: isSelected
//                       ? Theme.of(context).primaryColor
//                       : Colors.grey.shade200,
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(
//                     color: isSelected
//                         ? Theme.of(context).primaryColor
//                         : Colors.grey.shade400,
//                     width: 1,
//                   ),
//                 ),
//                 child: Text(
//                   weightStr,
//                   style: TextStyle(
//                     fontWeight: FontWeight.w500,
//                     color: isSelected ? Colors.white : Colors.black87,
//                   ),
//                 ),
//               ),
//             );
//           }).toList(),
//         ),
//       ],
//     );
//   }

//   Widget _buildPriceDetails() {
//     final weightDetails = _getSelectedWeightDetails();

//     if (weightDetails == null) {
//       return const SizedBox.shrink();
//     }

//     final double originalPrice = weightDetails['price'] ?? 0.0;
//     final double discountPercentage = weightDetails['discount'] ?? 0.0;
//     final double discountedPrice =
//         weightDetails['discountedPrice'] ?? originalPrice;
//     final bool hasDiscount = discountPercentage > 0;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Price Details',
//           style: TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         const SizedBox(height: 12),
//         Row(
//           crossAxisAlignment: CrossAxisAlignment.end,
//           children: [
//             Text(
//               '₹${discountedPrice.toStringAsFixed(2)}',
//               style: const TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.green,
//               ),
//             ),
//             const SizedBox(width: 8),
//             if (hasDiscount) ...[
//               Text(
//                 '₹${originalPrice.toStringAsFixed(2)}',
//                 style: const TextStyle(
//                   fontSize: 16,
//                   decoration: TextDecoration.lineThrough,
//                   color: Colors.grey,
//                 ),
//               ),
//               const SizedBox(width: 8),
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 6,
//                   vertical: 2,
//                 ),
//                 decoration: BoxDecoration(
//                   color: Colors.red.shade100,
//                   borderRadius: BorderRadius.circular(4),
//                 ),
//                 child: Text(
//                   '${discountPercentage.toStringAsFixed(0)}% OFF',
//                   style: TextStyle(
//                     color: Colors.red.shade700,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 12,
//                   ),
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ],
//     );
//   }
// }

// class EditOfferPage extends StatefulWidget {
//   final String offerId;
//   final Map<String, dynamic> offerData;

//   const EditOfferPage({
//     Key? key,
//     required this.offerId,
//     required this.offerData,
//   }) : super(key: key);

//   @override
//   _EditOfferPageState createState() => _EditOfferPageState();
// }

// class _EditOfferPageState extends State<EditOfferPage> {
//   final _formKey = GlobalKey<FormState>();
//   final ImagePicker _picker = ImagePicker();
//   bool _isLoading = false;

//   // Controllers
//   late TextEditingController _nameController;
//   late TextEditingController _descriptionController;
//   late DateTime _startDate;
//   late DateTime _endDate;

//   // Images
//   List<dynamic> _existingImages = [];
//   List<XFile> _newImages = [];
//   List<int> _imagesToDelete = [];

//   // Weights
//   List<WeightEntry> _weightEntries = [];

//   @override
//   void initState() {
//     super.initState();
//     _initializeControllers();
//   }

//   void _initializeControllers() {
//     // Initialize text controllers
//     _nameController =
//         TextEditingController(text: widget.offerData['name'] ?? '');
//     _descriptionController =
//         TextEditingController(text: widget.offerData['description'] ?? '');

//     // Initialize dates
//     _startDate = (widget.offerData['startDate'] as Timestamp?)?.toDate() ??
//         DateTime.now();
//     _endDate = (widget.offerData['endDate'] as Timestamp?)?.toDate() ??
//         DateTime.now().add(const Duration(days: 7));

//     // Initialize images
//     _existingImages = List<dynamic>.from(widget.offerData['images'] ?? []);

//     // Initialize weights
//     List<dynamic> weights = widget.offerData['weights'] ?? [];
//     _weightEntries = weights.map<WeightEntry>((weight) {
//       return WeightEntry(
//         weight: weight['weight'],
//         price: weight['price']?.toDouble() ?? 0.0,
//         discount: weight['discount']?.toDouble() ?? 0.0,
//         discountedPrice: weight['discountedPrice']?.toDouble() ?? 0.0,
//       );
//     }).toList();

//     // Add empty weight entry if no weights exist
//     if (_weightEntries.isEmpty) {
//       _weightEntries.add(WeightEntry(
//         weight: '',
//         price: 0.0,
//         discount: 0.0,
//         discountedPrice: 0.0,
//       ));
//     }
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _descriptionController.dispose();
//     super.dispose();
//   }

//   // Pick images from gallery
//   Future<void> _pickImages() async {
//     try {
//       final List<XFile> pickedImages = await _picker.pickMultiImage();
//       if (pickedImages.isNotEmpty) {
//         setState(() {
//           _newImages.addAll(pickedImages);
//         });
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error picking images: $e')),
//       );
//     }
//   }

//   // Remove an existing image
//   void _removeExistingImage(int index) {
//     setState(() {
//       _imagesToDelete.add(index);
//     });
//   }

//   // Remove a new image
//   void _removeNewImage(int index) {
//     setState(() {
//       _newImages.removeAt(index);
//     });
//   }

//   // Date picker
//   Future<void> _selectDate(BuildContext context, bool isStartDate) async {
//     final DateTime initialDate = isStartDate ? _startDate : _endDate;
//     final DateTime firstDate = isStartDate ? DateTime.now() : _startDate;

//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: initialDate,
//       firstDate: firstDate,
//       lastDate: DateTime(2101),
//     );

//     if (picked != null) {
//       setState(() {
//         if (isStartDate) {
//           _startDate = picked;
//           // If end date is before new start date, update end date
//           if (_endDate.isBefore(_startDate)) {
//             _endDate = _startDate.add(const Duration(days: 1));
//           }
//         } else {
//           _endDate = picked;
//         }
//       });
//     }
//   }

//   // Add a new weight entry
//   void _addWeightEntry() {
//     setState(() {
//       _weightEntries.add(WeightEntry(
//         weight: '',
//         price: 0.0,
//         discount: 0.0,
//         discountedPrice: 0.0,
//       ));
//     });
//   }

//   // Remove a weight entry
//   void _removeWeightEntry(int index) {
//     setState(() {
//       _weightEntries.removeAt(index);
//     });
//   }

//   // Choose weight from menu
//   Future<void> _showWeightSelectionDialog(int index) async {
//     final TextEditingController weightController = TextEditingController(
//       text: _weightEntries[index].weight,
//     );

//     const List<String> commonWeights = [
//       '100g',
//       '250g',
//       '500g',
//       '750g',
//       '1kg',
//       '1.5kg',
//       '2kg',
//       '5kg',
//       '10kg'
//     ];

//     return showDialog<void>(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Select Weight'),
//           content: StatefulBuilder(
//             builder: (BuildContext context, StateSetter setState) {
//               return SingleChildScrollView(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     TextField(
//                       controller: weightController,
//                       decoration: const InputDecoration(
//                         labelText: 'Custom Weight',
//                         hintText: 'e.g. 250g',
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     const Text('Common Weights:'),
//                     Wrap(
//                       spacing: 8,
//                       runSpacing: 8,
//                       children: commonWeights.map((String weight) {
//                         return ElevatedButton(
//                           onPressed: () {
//                             weightController.text = weight;
//                           },
//                           child: Text(weight),
//                         );
//                       }).toList(),
//                     ),
//                   ],
//                 ),
//               );
//             },
//           ),
//           actions: <Widget>[
//             TextButton(
//               child: const Text('Cancel'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//             TextButton(
//               child: const Text('Save'),
//               onPressed: () {
//                 setState(() {
//                   _weightEntries[index].weight = weightController.text;
//                 });
//                 Navigator.of(context).pop();
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // Calculate discounted price
//   void _calculateDiscountedPrice(int index) {
//     final double price = _weightEntries[index].price;
//     final double discount = _weightEntries[index].discount;

//     setState(() {
//       _weightEntries[index].discountedPrice = price - (price * discount / 100);
//     });
//   }

//   // Save offer
//   Future<void> _saveOffer() async {
//     if (!_formKey.currentState!.validate()) {
//       return;
//     }

//     // Check if at least one weight entry has valid data
//     bool hasValidWeight = false;
//     for (var entry in _weightEntries) {
//       if (entry.weight.isNotEmpty && entry.price > 0) {
//         hasValidWeight = true;
//         break;
//       }
//     }

//     if (!hasValidWeight) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please add at least one valid weight')),
//       );
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       // Handle images
//       List<String> updatedImageUrls = [];

//       // Keep existing images that are not marked for deletion
//       for (int i = 0; i < _existingImages.length; i++) {
//         if (!_imagesToDelete.contains(i)) {
//           updatedImageUrls.add(_existingImages[i]);
//         }
//       }

//       // Upload new images
//       for (var newImage in _newImages) {
//         String fileName = DateTime.now().millisecondsSinceEpoch.toString();
//         Reference storageRef = FirebaseStorage.instance
//             .ref()
//             .child('offers')
//             .child(widget.offerId)
//             .child('$fileName.jpg');

//         File imageFile = File(newImage.path);
//         await storageRef.putFile(imageFile);
//         String downloadUrl = await storageRef.getDownloadURL();
//         updatedImageUrls.add(downloadUrl);
//       }

//       // Remove empty or invalid weight entries
//       List<WeightEntry> validWeightEntries = _weightEntries
//           .where((entry) => entry.weight.isNotEmpty && entry.price > 0)
//           .toList();

//       // Convert weight entries to Map for Firestore
//       List<Map<String, dynamic>> weightsData = validWeightEntries.map((entry) {
//         return {
//           'weight': entry.weight,
//           'price': entry.price,
//           'discount': entry.discount,
//           'discountedPrice': entry.discountedPrice,
//         };
//       }).toList();

//       // Update Firestore document
//       await FirebaseFirestore.instance
//           .collection('offers')
//           .doc(widget.offerId)
//           .update({
//         'name': _nameController.text,
//         'description': _descriptionController.text,
//         'startDate': Timestamp.fromDate(_startDate),
//         'endDate': Timestamp.fromDate(_endDate),
//         'images': updatedImageUrls,
//         'weights': weightsData,
//         'updatedAt': Timestamp.now(),
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Offer updated successfully')),
//       );
//       Navigator.pop(context, true);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error updating offer: $e')),
//       );
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: AppColors().mainColor,
//         toolbarHeight: 100,
//         title: const Text(
//           'Edit Offer',
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.save),
//             onPressed: _isLoading ? null : _saveOffer,
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Form(
//               key: _formKey,
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Images Section
//                     _buildImagesSection(),
//                     const SizedBox(height: 24),

//                     // Basic Info Section
//                     _buildBasicInfoSection(),
//                     const SizedBox(height: 24),

//                     // Validity Period Section
//                     _buildValiditySection(),
//                     const SizedBox(height: 24),

//                     // Weights Section
//                     _buildWeightsSection(),
//                     const SizedBox(height: 24),

//                     // Description Section
//                     _buildDescriptionSection(),
//                     const SizedBox(height: 40),

//                     // Save Button
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         onPressed: _isLoading ? null : _saveOffer,
//                         style: ElevatedButton.styleFrom(
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                         ),
//                         child: Text(_isLoading ? 'Saving...' : 'Save Changes'),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//     );
//   }

//   Widget _buildImagesSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Images',
//           style: TextStyle(
//             color: AppColors().subcolor,
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         const SizedBox(height: 12),

//         // Existing Images
//         if (_existingImages.isNotEmpty)
//           Wrap(
//             spacing: 8,
//             runSpacing: 8,
//             children: List.generate(_existingImages.length, (index) {
//               final bool isMarkedForDeletion = _imagesToDelete.contains(index);

//               return Stack(
//                 children: [
//                   Container(
//                     width: 100,
//                     height: 100,
//                     decoration: BoxDecoration(
//                       border: Border.all(color: Colors.grey),
//                       borderRadius: BorderRadius.circular(8),
//                       color: isMarkedForDeletion ? Colors.grey.shade300 : null,
//                     ),
//                     child: isMarkedForDeletion
//                         ? const Center(
//                             child: Icon(Icons.delete, color: Colors.grey),
//                           )
//                         : ClipRRect(
//                             borderRadius: BorderRadius.circular(8),
//                             child: Image.network(
//                               _existingImages[index],
//                               fit: BoxFit.cover,
//                               loadingBuilder:
//                                   (context, child, loadingProgress) {
//                                 if (loadingProgress == null) return child;
//                                 return Center(
//                                   child: CircularProgressIndicator(
//                                     value: loadingProgress.expectedTotalBytes !=
//                                             null
//                                         ? loadingProgress
//                                                 .cumulativeBytesLoaded /
//                                             loadingProgress.expectedTotalBytes!
//                                         : null,
//                                   ),
//                                 );
//                               },
//                             ),
//                           ),
//                   ),
//                   Positioned(
//                     top: 5,
//                     right: 5,
//                     child: GestureDetector(
//                       onTap: () {
//                         setState(() {
//                           if (isMarkedForDeletion) {
//                             _imagesToDelete.remove(index);
//                           } else {
//                             _removeExistingImage(index);
//                           }
//                         });
//                       },
//                       child: Container(
//                         padding: const EdgeInsets.all(2),
//                         decoration: BoxDecoration(
//                           color: isMarkedForDeletion
//                               ? Colors.blue
//                               : AppColors().subcolor,
//                           shape: BoxShape.circle,
//                         ),
//                         child: Icon(
//                           isMarkedForDeletion ? Icons.undo : Icons.close,
//                           size: 18,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               );
//             }),
//           ),

//         // New Images
//         if (_newImages.isNotEmpty)
//           Padding(
//             padding: const EdgeInsets.only(top: 12),
//             child: Wrap(
//               spacing: 8,
//               runSpacing: 8,
//               children: List.generate(_newImages.length, (index) {
//                 return Stack(
//                   children: [
//                     Container(
//                       width: 100,
//                       height: 100,
//                       decoration: BoxDecoration(
//                         border: Border.all(color: Colors.green),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: ClipRRect(
//                         borderRadius: BorderRadius.circular(8),
//                         child: Image.file(
//                           File(_newImages[index].path),
//                           fit: BoxFit.cover,
//                         ),
//                       ),
//                     ),
//                     Positioned(
//                       top: 5,
//                       right: 5,
//                       child: GestureDetector(
//                         onTap: () => _removeNewImage(index),
//                         child: Container(
//                           padding: EdgeInsets.all(2),
//                           decoration: BoxDecoration(
//                             color: AppColors().subcolor,
//                             shape: BoxShape.circle,
//                           ),
//                           child: const Icon(
//                             Icons.close,
//                             size: 18,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 );
//               }),
//             ),
//           ),

//         const SizedBox(height: 12),

//         // Add Image Button
//         OutlinedButton.icon(
//           onPressed: _pickImages,
//           icon: const Icon(Icons.add_photo_alternate),
//           label: const Text('Add Images'),
//           style: OutlinedButton.styleFrom(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildBasicInfoSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Basic Information',
//           style: TextStyle(
//             color: AppColors().subcolor,
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         const SizedBox(height: 12),
//         TextFormField(
//           controller: _nameController,
//           decoration: const InputDecoration(
//             labelText: 'Offer Name',
//             border: OutlineInputBorder(),
//           ),
//           validator: (value) {
//             if (value == null || value.isEmpty) {
//               return 'Please enter a name for this offer';
//             }
//             return null;
//           },
//         ),
//       ],
//     );
//   }

//   Widget _buildValiditySection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Validity Period',
//           style: TextStyle(
//             color: AppColors().subcolor,
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         const SizedBox(height: 12),
//         Row(
//           children: [
//             Expanded(
//               child: InkWell(
//                 onTap: () => _selectDate(context, true),
//                 child: InputDecorator(
//                   decoration: InputDecoration(
//                     labelText: 'Start Date',
//                     border: OutlineInputBorder(),
//                     suffixIcon: Icon(
//                       Icons.calendar_today,
//                       color: AppColors().subcolor,
//                     ),
//                   ),
//                   child: Text(
//                     DateFormat('dd MMM yyyy').format(_startDate),
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: InkWell(
//                 onTap: () => _selectDate(context, false),
//                 child: InputDecorator(
//                   decoration: InputDecoration(
//                     labelText: 'End Date',
//                     border: OutlineInputBorder(),
//                     suffixIcon: Icon(
//                       Icons.calendar_today,
//                       color: AppColors().subcolor,
//                     ),
//                   ),
//                   child: Text(
//                     DateFormat('dd MMM yyyy').format(_endDate),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildWeightsSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               'Weights & Prices',
//               style: TextStyle(
//                 color: AppColors().subcolor,
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             TextButton.icon(
//               onPressed: _addWeightEntry,
//               icon: const Icon(Icons.add),
//               label: const Text('Add Weight'),
//             ),
//           ],
//         ),
//         const SizedBox(height: 12),

//         // Weight entries
//         ListView.builder(
//           shrinkWrap: true,
//           physics: const NeverScrollableScrollPhysics(),
//           itemCount: _weightEntries.length,
//           itemBuilder: (context, index) {
//             return Card(
//               margin: const EdgeInsets.only(bottom: 16),
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Expanded(
//                           child: GestureDetector(
//                             onTap: () => _showWeightSelectionDialog(index),
//                             child: InputDecorator(
//                               decoration: const InputDecoration(
//                                 labelText: 'Weight',
//                                 border: OutlineInputBorder(),
//                                 suffixIcon: Icon(Icons.arrow_drop_down),
//                               ),
//                               child: Text(
//                                 _weightEntries[index].weight.isEmpty
//                                     ? 'Select Weight'
//                                     : _weightEntries[index].weight,
//                               ),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 8),
//                         if (_weightEntries.length > 1)
//                           IconButton(
//                             icon:
//                                 Icon(Icons.delete, color: AppColors().subcolor),
//                             onPressed: () => _removeWeightEntry(index),
//                           ),
//                       ],
//                     ),
//                     const SizedBox(height: 16),
//                     TextFormField(
//                       initialValue: _weightEntries[index].price.toString(),
//                       decoration: const InputDecoration(
//                         labelText: 'Original Price (₹)',
//                         border: OutlineInputBorder(),
//                         prefixText: '₹',
//                       ),
//                       keyboardType:
//                           const TextInputType.numberWithOptions(decimal: true),
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please enter a price';
//                         }
//                         if (double.tryParse(value) == null ||
//                             double.parse(value) <= 0) {
//                           return 'Please enter a valid price';
//                         }
//                         return null;
//                       },
//                       onChanged: (value) {
//                         setState(() {
//                           _weightEntries[index].price =
//                               double.tryParse(value) ?? 0.0;
//                           _calculateDiscountedPrice(index);
//                         });
//                       },
//                     ),
//                     const SizedBox(height: 16),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: TextFormField(
//                             initialValue:
//                                 _weightEntries[index].discount.toString(),
//                             decoration: const InputDecoration(
//                               labelText: 'Discount (%)',
//                               border: OutlineInputBorder(),
//                               suffixText: '%',
//                             ),
//                             keyboardType: const TextInputType.numberWithOptions(
//                                 decimal: true),
//                             validator: (value) {
//                               if (value == null || value.isEmpty) {
//                                 return null;
//                               }
//                               double? discount = double.tryParse(value);
//                               if (discount == null ||
//                                   discount < 0 ||
//                                   discount > 100) {
//                                 return 'Enter valid % (0-100)';
//                               }
//                               return null;
//                             },
//                             onChanged: (value) {
//                               setState(() {
//                                 _weightEntries[index].discount =
//                                     double.tryParse(value) ?? 0.0;
//                                 _calculateDiscountedPrice(index);
//                               });
//                             },
//                           ),
//                         ),
//                         const SizedBox(width: 16),
//                         Expanded(
//                           child: TextFormField(
//                             initialValue: _weightEntries[index]
//                                 .discountedPrice
//                                 .toString(),
//                             decoration: const InputDecoration(
//                               labelText: 'Final Price (₹)',
//                               border: OutlineInputBorder(),
//                               prefixText: '₹',
//                             ),
//                             keyboardType: const TextInputType.numberWithOptions(
//                                 decimal: true),
//                             readOnly: true,
//                             enabled: false,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           },
//         ),
//       ],
//     );
//   }

//   Widget _buildDescriptionSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Description',
//           style: TextStyle(
//             color: AppColors().subcolor,
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         const SizedBox(height: 12),
//         TextFormField(
//           controller: _descriptionController,
//           decoration: const InputDecoration(
//             labelText: 'Offer Description',
//             border: OutlineInputBorder(),
//             hintText: 'Describe your offer...',
//           ),
//           maxLines: 5,
//         ),
//       ],
//     );
//   }
// }

// class WeightEntry {
//   String weight;
//   double price;
//   double discount;
//   double discountedPrice;

//   WeightEntry({
//     required this.weight,
//     required this.price,
//     required this.discount,
//     required this.discountedPrice,
//   });
// }
