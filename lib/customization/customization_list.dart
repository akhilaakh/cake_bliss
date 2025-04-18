import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cake_bliss/checkout/checkout_cart.dart'; // Import checkout page

class CustomizationList extends StatelessWidget {
  CustomizationList({Key? key}) : super(key: key);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _getCustomizationId(DocumentSnapshot doc) {
    return doc.id; // Return the document ID
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // Add to cart functionality
  Future<void> _addToCart(
      BuildContext context,
      Map<String, dynamic> customization,
      Map<String, dynamic> confirmData,
      String customizationId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to add items to cart')),
        );
        return;
      }

      // Check if this customization is already in the cart
      final existingCartItem = await _firestore
          .collection('carts')
          .doc(userId)
          .collection('items')
          .where('customizationId', isEqualTo: customizationId)
          .get();

      if (existingCartItem.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('This customization is already in your cart')),
        );
        return;
      }

      // Add the customization to cart
      await _firestore.collection('carts').doc(userId).collection('items').add({
        'name': 'Custom ${customization['flavor']} Cake',
        'price': double.parse(confirmData['rate'].toString()),
        'totalPrice': double.parse(confirmData['rate'].toString()),
        'quantity': 1,
        'weight': '${customization['weight']} kg',
        'categoryName': 'Custom Cake',
        'image': customization['imageUrl'] ?? '',
        'customizationId': customizationId,
        'addedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to Cart')),
      );
    } catch (e) {
      print('Error adding to cart: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to add to cart. Please try again.')),
      );
    }
  }

  // Buy now functionality (add to cart and go to checkout)
  Future<void> _buyNow(BuildContext context, Map<String, dynamic> customization,
      Map<String, dynamic> confirmData, String customizationId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to checkout')),
        );
        return;
      }

      // Create a direct checkout item map (don't add to cart)
      final directCheckoutItem = {
        'typeId': customizationId,
        'name': 'Custom ${customization['flavor']} Cake',
        'price': double.parse(confirmData['rate'].toString()),
        'quantity': 1,
        'weight': '${customization['weight']} kg',
        'categoryName': 'Custom Cake',
        'image': customization['imageUrl'] ?? '',
      };

      // Navigate directly to checkout with just this item
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              CheckoutPage(directCheckoutItem: directCheckoutItem),
        ),
      );
    } catch (e) {
      print('Error with buy now: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to process. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Customizations'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('customizations')
            .where('userId', isEqualTo: _auth.currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No customizations found'));
          }

          final sortedDocs = snapshot.data!.docs.toList()
            ..sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              final aTime = aData['createdAt'] as Timestamp?;
              final bTime = bData['createdAt'] as Timestamp?;
              if (aTime == null || bTime == null) return 0;
              return bTime.compareTo(aTime);
            });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedDocs.length,
            itemBuilder: (context, index) {
              final doc = sortedDocs[index];
              final customization = doc.data() as Map<String, dynamic>;
              final customizationId = _getCustomizationId(doc);
              final status = (customization['status'] ?? 'Pending').toString();

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            status.toLowerCase() == 'accepted'
                                ? Icons.check_circle
                                : status.toLowerCase() == 'rejected'
                                    ? Icons.cancel
                                    : Icons.pending,
                            color: _getStatusColor(status),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            status,
                            style: TextStyle(
                              color: _getStatusColor(status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (customization['imageUrl'] != null)
                      ClipRRect(
                        child: Image.network(
                          customization['imageUrl'],
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Flavor: ${customization['flavor']}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Weight: ${customization['weight']} kg',
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            'Description: ${customization['description']}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          if (status.toLowerCase() == 'rejected' &&
                              customization['rejectionReason'] != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Reason for Rejection:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    customization['rejectionReason'],
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Show quote details if status is accepted
                          if (status.toLowerCase() == 'accepted') ...[
                            const SizedBox(height: 16),
                            StreamBuilder<QuerySnapshot>(
                              stream: _firestore
                                  .collection('customization_confirmations')
                                  .where('customizationId',
                                      isEqualTo: customizationId)
                                  .limit(1)
                                  .snapshots(),
                              builder: (context, confirmSnapshot) {
                                if (confirmSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                      child: SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ));
                                }

                                if (confirmSnapshot.hasData &&
                                    confirmSnapshot.data!.docs.isNotEmpty) {
                                  final confirmData =
                                      confirmSnapshot.data!.docs[0].data()
                                          as Map<String, dynamic>;
                                  return Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Quote Details:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                const Icon(Icons.currency_rupee,
                                                    size: 16),
                                                Text(
                                                  ' Price: ₹${confirmData['rate']}',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            if (confirmData[
                                                        'adminDescription'] !=
                                                    null &&
                                                confirmData['adminDescription']
                                                    .toString()
                                                    .isNotEmpty) ...[
                                              const SizedBox(height: 8),
                                              Text(
                                                'Additional Details:',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                confirmData['adminDescription'],
                                                style: const TextStyle(
                                                    fontSize: 14),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Disclaimer:',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.w800),
                                              ),
                                              Text(
                                                  'If the order is not completed within one month of acceptance, it will be automatically canceled. ')
                                            ],
                                          ],
                                        ),
                                      ),

                                      // Add Cart and Buy Now buttons here
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              icon: const Icon(
                                                  Icons.shopping_cart,
                                                  color: Colors.white),
                                              label: const Text('Add to Cart',
                                                  style: TextStyle(
                                                      color: Colors.white)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.orange,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 12),
                                              ),
                                              onPressed: () => _addToCart(
                                                  context,
                                                  customization,
                                                  confirmData,
                                                  customizationId),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              icon: const Icon(Icons.flash_on,
                                                  color: Colors.white),
                                              label: const Text('Buy Now',
                                                  style: TextStyle(
                                                      color: Colors.white)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 12),
                                              ),
                                              onPressed: () => _buyNow(
                                                  context,
                                                  customization,
                                                  confirmData,
                                                  customizationId),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                }
                                return const Text(
                                  'Quote details loading...',
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                          ],

                          // Show time information
                          const SizedBox(height: 12),
                          if (customization['createdAt'] != null)
                            Text(
                              'Requested on: ${_formatTimestamp(customization['createdAt'])}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          if (customization['updatedAt'] != null)
                            Text(
                              'Last updated: ${_formatTimestamp(customization['updatedAt'])}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Helper method to format timestamps
String _formatTimestamp(Timestamp timestamp) {
  final date = timestamp.toDate();
  return DateFormat('yyyy/ MMM/ dd  hh:mm a').format(date);
}

class UserCustomizationsView extends StatelessWidget {
  final String userId;
  final String userName;

  const UserCustomizationsView({
    Key? key,
    required this.userId,
    required this.userName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text('$userName\'s Customizations'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Simplified query that doesn't require a composite index
        stream: _firestore
            .collection('customizations')
            .where('userId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No customizations found for this user'),
            );
          }

          // Sort the documents in memory instead
          final sortedDocs = snapshot.data!.docs.toList()
            ..sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              final aTime = aData['createdAt'] as Timestamp?;
              final bTime = bData['createdAt'] as Timestamp?;
              if (aTime == null || bTime == null) return 0;
              return bTime.compareTo(aTime); // Descending order
            });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedDocs.length,
            itemBuilder: (context, index) {
              final customization =
                  sortedDocs[index].data() as Map<String, dynamic>;

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (customization['imageUrl'] != null)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: Image.network(
                          customization['imageUrl'],
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return SizedBox(
                              height: 200,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status: ${customization['status'] ?? 'N/A'}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Flavor: ${customization['flavor'] ?? 'N/A'}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Weight: ${customization['weight'] ?? 'N/A'} kg',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          // Text(
                          //   'Budget: ₹${customization['budget'] ?? 'N/A'}',
                          //   style: const TextStyle(fontSize: 16),
                          // ),
                          const SizedBox(height: 8),
                          Text(
                            'Description: ${customization['description'] ?? 'N/A'}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          if (customization['createdAt'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Submitted: ${(customization['createdAt'] as Timestamp).toDate().toString()}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
