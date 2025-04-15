import 'package:cakebliss_admin/offer.dart';
import 'package:cakebliss_admin/offer/edit_offer.dart';
import 'package:carousel_slider/carousel_options.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OfferDetailPage extends StatefulWidget {
  final String offerId;

  const OfferDetailPage({Key? key, required this.offerId}) : super(key: key);

  @override
  _OfferDetailPageState createState() => _OfferDetailPageState();
}

class _OfferDetailPageState extends State<OfferDetailPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _offerData;
  int _currentImageIndex = 0;
  String _selectedWeight = '';

  @override
  void initState() {
    super.initState();
    _fetchOfferData();
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

  Future<void> _showDeleteConfirmation() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Offer'),
          content: const Text('Are you sure you want to delete this offer?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Yes', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteOffer();
              },
            ),
          ],
        );
      },
    );
  }

  // Delete the offer
  Future<void> _deleteOffer() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offerId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offer deleted successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting offer: $e')),
      );
    }
  }

  // Navigate to edit page
  void _navigateToEditPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditOfferPage(
          offerId: widget.offerId,
          offerData: _offerData!,
        ),
      ),
    );

    // If the edit was successful, refresh the data
    if (result == true) {
      _fetchOfferData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: Text(_offerData?['name'] ?? 'Offer Details'),
        // centerTitle: true,
        actions: [
          if (!_isLoading && _offerData != null)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _navigateToEditPage();
                } else if (value == 'delete') {
                  _showDeleteConfirmation();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                      ],
                    ),
                  ),
                ],
              ),
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
            color: Colors.transparent,
            child: const Center(
              child: Icon(
                Icons.image_not_supported,
                size: 50,
                color: Colors.transparent,
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
                    color: Colors.transparent,
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

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isActive ? Colors.green.shade100 : Colors.orange.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            isActive ? 'Active' : 'Upcoming',
            style: TextStyle(
              color: isActive ? Colors.green.shade700 : Colors.orange.shade700,
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
              ),
            ],
          ],
        ),
      ],
    );
  }
}
