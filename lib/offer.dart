import 'package:cake_bliss/checkout/checkout_cart.dart';
import 'package:cake_bliss/screen/cart.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class UserOfferListPage extends StatefulWidget {
  const UserOfferListPage({Key? key}) : super(key: key);

  @override
  _UserOfferListPageState createState() => _UserOfferListPageState();
}

class _UserOfferListPageState extends State<UserOfferListPage> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Special Offers'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('offers')
                  .where('isActive', isEqualTo: true)
                  // Only show current offers (where current date is between start and end date)
                  .where('endDate',
                      isGreaterThanOrEqualTo:
                          Timestamp.fromDate(DateTime.now()))
                  .orderBy('endDate', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assetchocolate-liqueurs-alcohol-content-varies-in-the-candy-version-1703220515.jpg', // Add this image to your assets
                          height: 150,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No special offers available',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Check back later for delicious deals!',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'All Offers',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            final doc = snapshot.data!.docs[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final String offerId = doc.id;

                            return _buildOfferCard(context, offerId, data);
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildOfferCard(
      BuildContext context, String offerId, Map<String, dynamic> data) {
    List<dynamic> images = data['images'] ?? [];
    String imageUrl = images.isNotEmpty ? images[0] : '';

    List<dynamic> weights = data['weights'] ?? [];
    double? lowestPrice;
    double? highestDiscount = 0;

    if (weights.isNotEmpty) {
      for (var weight in weights) {
        final double discountedPrice = weight['discountedPrice'] ?? 0.0;
        final double discount = weight['discount'] ?? 0.0;

        if (lowestPrice == null || discountedPrice < lowestPrice) {
          lowestPrice = discountedPrice;
        }

        if (discount > highestDiscount!) {
          highestDiscount = discount;
        }
      }
    }

    // Get offer dates
    final startDate = (data['startDate'] as Timestamp?)?.toDate();
    final endDate = (data['endDate'] as Timestamp?)?.toDate();
    String validityText = '';

    if (startDate != null && endDate != null) {
      final now = DateTime.now();
      final isActive = now.isAfter(startDate) && now.isBefore(endDate);

      if (isActive) {
        // Calculate days remaining
        final daysRemaining = endDate.difference(now).inDays;
        if (daysRemaining == 0) {
          validityText = 'Ends today!';
        } else if (daysRemaining == 1) {
          validityText = 'Ends tomorrow';
        } else {
          validityText = 'Ends in $daysRemaining days';
        }
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserOfferDetailPage(offerId: offerId),
          ),
        );
      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      image: imageUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(imageUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: imageUrl.isEmpty
                        ? const Center(
                            child: Icon(
                              Icons.cake,
                              size: 40,
                              color: Colors.grey,
                            ),
                          )
                        : null,
                  ),
                  // Discount badge
                  if (highestDiscount! > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Up to ${highestDiscount.toStringAsFixed(0)}% OFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Name and Price
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['name'] ?? 'No Name',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (lowestPrice != null)
                    Text(
                      'From ₹${lowestPrice.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  if (validityText.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      validityText,
                      style: TextStyle(
                        color: validityText.contains('today')
                            ? Colors.red
                            : Colors.grey.shade600,
                        fontSize: 11,
                        fontWeight: validityText.contains('today')
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// You'll need to create this class separately

class UserOfferDetailPage extends StatefulWidget {
  final String offerId;

  const UserOfferDetailPage({Key? key, required this.offerId})
      : super(key: key);

  @override
  _UserOfferDetailPageState createState() => _UserOfferDetailPageState();
}

class _UserOfferDetailPageState extends State<UserOfferDetailPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _offerData;
  int _currentImageIndex = 0;
  String _selectedWeight = '';

  @override
  void initState() {
    super.initState();
    _fetchOfferData();
  }

  // Add this function to _UserOfferDetailPageState class
  Future<void> _buyNow() async {
    if (_offerData == null) return;

    final weightDetails = _getSelectedWeightDetails();
    if (weightDetails == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to proceed')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Create a direct checkout item with the exact structure CheckoutPage expects
      final price =
          weightDetails['discountedPrice'] ?? weightDetails['price'] ?? 0.0;
      final directCheckoutItem = {
        'offerId': widget.offerId,
        'typeId': widget.offerId,
        'name': _offerData!['name'],
        'image': _offerData!['images']?.isNotEmpty == true
            ? _offerData!['images'][0]
            : '',
        'categoryName': _offerData!['categoryName'] ?? 'Special Offer',
        'weight': _selectedWeight,
        'price': price,
        'totalPrice': price,
        'quantity': 1,
      };

      // Navigate to checkout page with direct checkout item
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              CheckoutPage(directCheckoutItem: directCheckoutItem),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addToCart() async {
    if (_offerData == null) return;

    final weightDetails = _getSelectedWeightDetails();
    if (weightDetails == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to add items to cart')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Reference to user's cart
      final cartRef = FirebaseFirestore.instance
          .collection('carts')
          .doc(userId)
          .collection('items');

      // Check if item already exists in cart
      final querySnapshot = await cartRef
          .where('offerId', isEqualTo: widget.offerId)
          .where('weight', isEqualTo: _selectedWeight)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Item exists, update quantity
        final docId = querySnapshot.docs.first.id;
        final existingItem = querySnapshot.docs.first.data();
        final newQuantity = (existingItem['quantity'] as int) + 1;
        final price =
            weightDetails['discountedPrice'] ?? weightDetails['price'] ?? 0.0;

        await cartRef.doc(docId).update({
          'quantity': newQuantity,
          'totalPrice': price * newQuantity,
        });
      } else {
        // Add new item to cart
        final price =
            weightDetails['discountedPrice'] ?? weightDetails['price'] ?? 0.0;

        await cartRef.add({
          'offerId': widget.offerId,
          'name': _offerData!['name'],
          'image': _offerData!['images']?.isNotEmpty == true
              ? _offerData!['images'][0]
              : '',
          'categoryName': _offerData!['categoryName'] ?? 'Special Offer',
          'weight': _selectedWeight,
          'price': price,
          'totalPrice': price,
          'quantity': 1,
          'addedAt': FieldValue.serverTimestamp(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added to cart'),
          action: SnackBarAction(
            label: 'VIEW CART',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CartPage()),
              );
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding to cart: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

// Now, add an "Add to Cart" button at the bottom of the OfferDetailPage build method
// Add this to the bottom of your build method, after the existing content
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Price',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  '₹${(_getSelectedWeightDetails()?['discountedPrice'] ?? _getSelectedWeightDetails()?['price'] ?? 0.0).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _addToCart,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
            child: Text(
              'Add to Cart',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchOfferData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offerId)
          .get();

      if (docSnapshot.exists) {
        setState(() {
          _offerData = docSnapshot.data();
          _isLoading = false;

          // Set the first weight as selected by default
          List<dynamic> weights = _offerData?['weights'] ?? [];
          if (weights.isNotEmpty) {
            _selectedWeight = weights[0]['weight'];
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offer not found')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading offer: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Get weight details based on selected weight
  Map<String, dynamic>? _getSelectedWeightDetails() {
    if (_offerData == null) return null;

    List<dynamic> weights = _offerData!['weights'] ?? [];
    for (var weight in weights) {
      if (weight['weight'] == _selectedWeight) {
        return weight;
      }
    }
    return null;
  }

  // Add to cart functionality
  // void _addToCart() {
  //   // Implement your add to cart functionality here
  //   // This is where you'd add the selected item to the user's cart

  //   final weightDetails = _getSelectedWeightDetails();
  //   if (weightDetails == null) return;

  //   // Show success message
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content:
  //           Text('${_offerData?['name']} (${_selectedWeight}) added to cart'),
  //       action: SnackBarAction(
  //         label: 'VIEW CART',
  //         onPressed: () {
  //           // Navigate to cart page here
  //           // Navigator.push(context, MaterialPageRoute(builder: (context) => CartPage()));
  //         },
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_offerData?['name'] ?? 'Offer Details'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              // Navigate to cart page
              // Navigator.push(context, MaterialPageRoute(builder: (context) => CartPage()));
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Carousel
                      _buildImageCarousel(),

                      // Product Info
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Name
                            Text(
                              _offerData?['name'] ?? 'No Name',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Offer Duration
                            _buildOfferDuration(),
                            const SizedBox(height: 16),

                            // Weight Options
                            _buildWeightOptions(),
                            const SizedBox(height: 24),

                            // Price Details
                            _buildPriceDetails(),
                            const SizedBox(height: 24),

                            // Description
                            const Text(
                              'Description',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _offerData?['description'] ??
                                  'No description available',
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),

                            // Add extra padding at bottom to account for the fixed add to cart button
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, -3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Price display
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Price',
                                style:
                                    TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                              Text(
                                '₹${(_getSelectedWeightDetails()?['discountedPrice'] ?? _getSelectedWeightDetails()?['price'] ?? 0.0).toStringAsFixed(2)}',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        // Add to Cart button
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ElevatedButton(
                              onPressed: _addToCart,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Theme.of(context).primaryColor,
                                side: BorderSide(
                                    color: Theme.of(context).primaryColor),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Add to Cart',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                        // Buy Now button
                        Expanded(
                          flex: 3,
                          child: ElevatedButton(
                            onPressed: _buyNow,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Buy Now',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildImageCarousel() {
    List<dynamic> images = _offerData?['images'] ?? [];

    return Column(
      children: [
        if (images.isEmpty)
          Container(
            height: 250,
            color: Colors.grey.shade200,
            child: const Center(
              child: Icon(
                Icons.cake,
                size: 50,
                color: Colors.grey,
              ),
            ),
          )
        else
          Column(
            children: [
              CarouselSlider(
                options: CarouselOptions(
                  height: 300,
                  viewportFraction: 1.0,
                  enlargeCenterPage: false,
                  enableInfiniteScroll: images.length > 1,
                  onPageChanged: (index, reason) {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                ),
                items: images.map<Widget>((imageUrl) {
                  return Container(
                    width: MediaQuery.of(context).size.width,
                    color: Colors.grey.shade100,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 50,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              if (images.length > 1)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: images.asMap().entries.map((entry) {
                    return Container(
                      width: 8.0,
                      height: 8.0,
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentImageIndex == entry.key
                            ? Theme.of(context).primaryColor
                            : Colors.grey.shade400,
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildOfferDuration() {
    final startDate = (_offerData?['startDate'] as Timestamp?)?.toDate();
    final endDate = (_offerData?['endDate'] as Timestamp?)?.toDate();

    if (startDate == null || endDate == null) {
      return const SizedBox.shrink();
    }

    final now = DateTime.now();
    final isActive = now.isAfter(startDate) && now.isBefore(endDate);

    // Calculate days remaining if offer is active
    String daysRemainingText = '';
    if (isActive) {
      final daysRemaining = endDate.difference(now).inDays;
      if (daysRemaining == 0) {
        daysRemainingText = 'Ends today!';
      } else if (daysRemaining == 1) {
        daysRemainingText = '1 day left';
      } else {
        daysRemainingText = '$daysRemaining days left';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color:
                    isActive ? Colors.green.shade100 : Colors.orange.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isActive ? 'Active' : 'Upcoming',
                style: TextStyle(
                  color:
                      isActive ? Colors.green.shade700 : Colors.orange.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Valid: ${DateFormat('dd MMM').format(startDate)} - ${DateFormat('dd MMM').format(endDate)}',
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        if (isActive && daysRemainingText.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: daysRemainingText.contains('today')
                  ? Colors.red.shade50
                  : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              daysRemainingText,
              style: TextStyle(
                color: daysRemainingText.contains('today')
                    ? Colors.red
                    : Colors.blue.shade700,
                fontWeight: daysRemainingText.contains('today')
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWeightOptions() {
    List<dynamic> weights = _offerData?['weights'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Weight',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: weights.map<Widget>((weight) {
            final String weightStr = weight['weight'];
            final bool isSelected = _selectedWeight == weightStr;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedWeight = weightStr;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade400,
                    width: 1,
                  ),
                ),
                child: Text(
                  weightStr,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPriceDetails() {
    final weightDetails = _getSelectedWeightDetails();

    if (weightDetails == null) {
      return const SizedBox.shrink();
    }

    final double originalPrice = weightDetails['price'] ?? 0.0;
    final double discountPercentage = weightDetails['discount'] ?? 0.0;
    final double discountedPrice =
        weightDetails['discountedPrice'] ?? originalPrice;
    final bool hasDiscount = discountPercentage > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Price Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${discountedPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            if (hasDiscount) ...[
              Text(
                '₹${originalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${discountPercentage.toStringAsFixed(0)}% OFF',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              )
            ],
          ],
        ),
        const SizedBox(height: 8),
        if (hasDiscount)
          Text(
            'You save: ₹${(originalPrice - discountedPrice).toStringAsFixed(2)}',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
            ),
          ),
        const SizedBox(height: 12),
        // Additional information about delivery or other details
        Row(
          children: [
            const Icon(
              Icons.local_shipping_outlined,
              size: 16,
              color: Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              'Free delivery on orders above ₹500',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(
              Icons.access_time,
              size: 16,
              color: Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              'Delivery within 24 hours',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Optional: Add a method to handle quantity selection
  Widget _buildQuantitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quantity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      // Implement decreasing quantity
                    },
                  ),
                  const Text(
                    '1', // This would be your quantity variable
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      // Implement increasing quantity
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Optional: Add related offers section
  Widget _buildRelatedOffers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'You might also like',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('offers')
                .where('isActive', isEqualTo: true)
                .where('category', isEqualTo: _offerData?['category'])
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return const Center(
                  child: Text('No related offers found'),
                );
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  if (doc.id == widget.offerId)
                    return const SizedBox.shrink(); // Skip current offer

                  final data = doc.data() as Map<String, dynamic>;
                  final String offerId = doc.id;

                  List<dynamic> images = data['images'] ?? [];
                  String imageUrl = images.isNotEmpty ? images[0] : '';

                  return GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              UserOfferDetailPage(offerId: offerId),
                        ),
                      );
                    },
                    child: Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: imageUrl.isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(imageUrl),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                color: Colors.grey.shade200,
                              ),
                              child: imageUrl.isEmpty
                                  ? const Center(
                                      child: Icon(
                                        Icons.cake,
                                        size: 30,
                                        color: Colors.grey,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            data['name'] ?? 'No Name',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          if (data['weights'] != null &&
                              (data['weights'] as List).isNotEmpty)
                            Text(
                              'From ₹${((data['weights'] as List)[0]['discountedPrice'] ?? 0.0).toStringAsFixed(0)}',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
