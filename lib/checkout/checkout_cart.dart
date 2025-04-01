import 'package:cake_bliss/checkout/address_addedit.dart';
import 'package:cake_bliss/checkout/address_list.dart';
import 'package:cake_bliss/constants/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class CheckoutPage extends StatefulWidget {
  final Map<String, dynamic>? directCheckoutItem;

  const CheckoutPage({Key? key, this.directCheckoutItem}) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool _isLoading = true;
  bool _isDirectCheckout = false;
  List<Map<String, dynamic>> _cartItems = [];
  List<Map<String, dynamic>> _addresses = [];
  Map<String, dynamic>? _selectedAddress;
  double _subtotal = 0.0;
  final double _deliveryFee = 50.0;
  double _total = 0.0;
  String orderId = '';

  @override
  void initState() {
    super.initState();

    // Check if this is a direct checkout
    if (widget.directCheckoutItem != null) {
      setState(() {
        _isDirectCheckout = true;
        // Create a list with just the single item
        _cartItems = [widget.directCheckoutItem!];
        _calculateTotals();
        _isLoading = false;
      });
    } else {
      // Regular cart checkout
      _fetchCartItems();
    }
    _fetchAddresses();
  }

  Future<void> _fetchCartItems() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('carts')
          .doc(userId)
          .collection('items')
          .get();

      final items = snapshot.docs
          .map((doc) => {
                ...doc.data(),
                'id': doc.id,
              })
          .toList();

      setState(() {
        _cartItems = items;
        _calculateTotals();
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching cart items: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAddresses() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .get();

      final addresses = snapshot.docs
          .map((doc) => {
                ...doc.data(),
                'id': doc.id,
              })
          .toList();

      setState(() {
        _addresses = addresses;
        if (addresses.isNotEmpty) {
          // Select the default address if available
          _selectedAddress = addresses.firstWhere(
              (addr) => addr['isDefault'] == true,
              orElse: () => addresses.first);
        }
      });
    } catch (e) {
      print('Error fetching addresses: $e');
    }
  }

  void _calculateTotals() {
    double sum = 0.0;
    for (var item in _cartItems) {
      sum += (item['price'] * item['quantity']).toDouble();
    }
    setState(() {
      _subtotal = sum;
      _total = _subtotal + _deliveryFee;
    });
  }

  void _updateQuantity(int index, int newQuantity) {
    if (newQuantity < 1) return;

    setState(() {
      _cartItems[index]['quantity'] = newQuantity;
      _cartItems[index]['totalPrice'] =
          _cartItems[index]['price'] * newQuantity;
      _calculateTotals();
    });

    // Update Firestore only if it's from the cart (not direct checkout)
    if (!_isDirectCheckout && _cartItems[index].containsKey('id')) {
      _updateCartItemInFirestore(_cartItems[index]['id'], newQuantity);
    }
  }

  Future<void> _updateCartItemInFirestore(String itemId, int quantity) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      await FirebaseFirestore.instance
          .collection('carts')
          .doc(userId)
          .collection('items')
          .doc(itemId)
          .update({
        'quantity': quantity,
        'totalPrice': double.parse((quantity *
                _cartItems.firstWhere((item) => item['id'] == itemId)['price'])
            .toStringAsFixed(2)),
      });
    } catch (e) {
      print('Error updating cart item: $e');
    }
  }

  void _showAddressSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Select Delivery Address',
          style: TextStyle(color: AppColors().mainColor),
        ),
        content: _addresses.isEmpty
            ? const Text('No addresses found. Please add an address.')
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _addresses.map((address) {
                    return RadioListTile<Map<String, dynamic>>(
                      title: Text(address['name']),
                      subtitle: Text(
                          '${address['street']}, ${address['city']}, ${address['state']} - ${address['pincode']}'),
                      value: address,
                      groupValue: _selectedAddress,
                      onChanged: (value) {
                        setState(() {
                          _selectedAddress = value;
                          Navigator.pop(context);
                        });
                      },
                      activeColor: AppColors().mainColor,
                    );
                  }).toList(),
                ),
              ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to add new address page
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AddEditAddressPage()));
            },
            child: Text(
              'Add New Address',
              style: TextStyle(color: AppColors().mainColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Future<String> _placeOrder() async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a delivery address'),
          duration: Duration(seconds: 2),
        ),
      );
      return '';
    }

    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty'),
          duration: Duration(seconds: 2),
        ),
      );
      return '';
    }

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        setState(() => _isLoading = false);
        return '';
      }

      // Create a new order
      final orderRef = FirebaseFirestore.instance.collection('orders').doc();
      final orderNumber = 'ORD-${DateTime.now().millisecondsSinceEpoch}';

      await orderRef.set({
        'userId': userId,
        'orderNumber': orderNumber,
        'items': _cartItems
            .map((item) => {
                  'typeId': item['typeId'],
                  'name': item['name'],
                  'weight': item['weight'],
                  'quantity': item['quantity'],
                  'price': item['price'],
                  'totalPrice': item['price'] * item['quantity'],
                  'image': item['image'],
                })
            .toList(),
        'address': {
          'name': _selectedAddress!['name'],
          'phone': _selectedAddress!['phone'],
          'street': _selectedAddress!['street'],
          'city': _selectedAddress!['city'],
          'state': _selectedAddress!['state'],
          'pincode': _selectedAddress!['pincode'],
        },
        'subtotal': _subtotal,
        'deliveryFee': _deliveryFee,
        'total': _total,
        'status': 'pending',
        'paymentMethod': 'RazorPay',
        'paymentStatus': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() => _isLoading = false);
      return orderRef.id;
    } catch (e) {
      print('Error placing order: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to place order. Please try again.'),
          duration: Duration(seconds: 2),
        ),
      );
      return '';
    }
  }

  void _proceedToPayment() async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a delivery address'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // First create the order in Firestore
    final orderId = await _placeOrder();

    if (orderId.isEmpty) return;

    // Navigate to payment screen with the orderId
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          orderId: orderId,
          deliveryAddress: _selectedAddress!,
          totalAmount: _total,
          cartItems: _cartItems,
          isDirectCheckout: _isDirectCheckout,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Checkout'),
          backgroundColor: AppColors().mainColor,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        title: Center(
          child: Text(
            _isDirectCheckout ? 'Buy Now' : 'Checkout',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context)
                .pop(); // This allows the default back navigation
          },
        ),
        backgroundColor: AppColors().mainColor,
      ),
      body: _cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_outlined, size: 80),
                  const SizedBox(height: 16),
                  const Text(
                    'Your cart is empty',
                    style: TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/home'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors().mainColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: Text(
                      'Continue Shopping',
                      style: TextStyle(color: AppColors().white),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Items section
                        Text(
                          _isDirectCheckout ? 'Your Item' : 'Order Items',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors().mainColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...List.generate(_cartItems.length, (index) {
                          final item = _cartItems[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Product image
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      item['image'],
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          width: 80,
                                          height: 80,
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.error),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Item details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['name'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text('Weight: ${item['weight']}'),
                                        const SizedBox(height: 4),
                                        Text(
                                          '₹${item['price'].toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color: AppColors().mainColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Quantity controls
                                  Column(
                                    children: [
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.remove_circle_outline,
                                              color: AppColors().mainColor,
                                            ),
                                            onPressed: () => _updateQuantity(
                                                index, item['quantity'] - 1),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 8),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: AppColors().mainColor),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              item['quantity'].toString(),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors().mainColor,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.add_circle_outline,
                                              color: AppColors().mainColor,
                                            ),
                                            onPressed: () => _updateQuantity(
                                                index, item['quantity'] + 1),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '₹${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 24),

                        // Delivery address section
                        Row(
                          children: [
                            Text(
                              'Delivery Address',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors().mainColor,
                              ),
                            ),
                            SizedBox(
                              width: 110,
                            ),
                            GestureDetector(
                              onTap: () {
                                // Navigate to the all addresses screen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AddressListPage(), // Your all addresses screen
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  Text(
                                    'All Addresses',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors().mainColor,
                                    ),
                                  ),
                                  Icon(
                                    Icons.list_alt_outlined,
                                    color: AppColors().mainColor,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: _showAddressSelectionDialog,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _selectedAddress == null
                                ? Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Select Delivery Address'),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                        color: AppColors().mainColor,
                                      ),
                                    ],
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _selectedAddress!['name'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            'CHANGE',
                                            style: TextStyle(
                                              color: AppColors().mainColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(_selectedAddress!['phone']),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_selectedAddress!['street']}, ${_selectedAddress!['city']}, ${_selectedAddress!['state']} - ${_selectedAddress!['pincode']}',
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Order summary
                        Text(
                          'Order Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors().mainColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Subtotal'),
                                  Text('₹${_subtotal.toStringAsFixed(2)}'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Delivery Fee'),
                                  Text('₹${_deliveryFee.toStringAsFixed(2)}'),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    '₹${_total.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Bottom action bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors().white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Total:',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                '₹${_total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _proceedToPayment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors().mainColor,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              "Place Order",
                              style: TextStyle(
                                color: AppColors().white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
}

// Address Model
class Address {
  final String? id;
  final String name;
  final String phone;
  final String street;
  final String city;
  final String state;
  final String pincode;
  final bool isDefault;

  Address({
    this.id,
    required this.name,
    required this.phone,
    required this.street,
    required this.city,
    required this.state,
    required this.pincode,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'street': street,
      'city': city,
      'state': state,
      'pincode': pincode,
      'isDefault': isDefault,
    };
  }

  factory Address.fromMap(Map<String, dynamic> map, String id) {
    return Address(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      street: map['street'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      pincode: map['pincode'] ?? '',
      isDefault: map['isDefault'] ?? false,
    );
  }
}

// Payment Screen
class PaymentScreen extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic> deliveryAddress;
  final double totalAmount;
  final List<Map<String, dynamic>> cartItems;
  final bool isDirectCheckout;

  const PaymentScreen({
    Key? key,
    required this.orderId,
    required this.deliveryAddress,
    required this.totalAmount,
    required this.cartItems,
    required this.isDirectCheckout,
  }) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late Razorpay _razorpay;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Debug print to verify order ID
    print("PaymentScreen initState - orderId: '${widget.orderId}'");

    _razorpay = Razorpay();

    // Event listeners
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    // Automatically open checkout when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      openCheckout();
    });
  }

  void openCheckout() {
    setState(() => _isProcessing = true);

    // Get user's email (you might want to fetch this from Firestore)
    final email =
        FirebaseAuth.instance.currentUser?.email ?? 'user@example.com';

    var options = {
      'key': 'rzp_test_THYUb6UHdSUKXP', // Replace with your Razorpay API key
      'amount': (widget.totalAmount * 100).toInt(), // Convert to paise
      'name': 'Cake Bliss',
      'description': 'Order #${widget.orderId.substring(0, 8)}',
      'prefill': {
        'contact': widget.deliveryAddress['phone'] ?? '9876543210',
        'email': email,
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      print("Error opening Razorpay: $e");
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error initiating payment. Please try again."),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    print("Payment Success: ${response.paymentId}");
    setState(() => _isProcessing = true);

    try {
      // Update order in Firestore with payment details
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({
        'paymentId': response.paymentId,
        'paymentStatus': 'completed',
        'status': 'Pending',
      });

      // Clear cart if this was a regular checkout
      if (!widget.isDirectCheckout) {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId != null) {
          await FirebaseFirestore.instance
              .collection('carts')
              .doc(userId)
              .collection('items')
              .get()
              .then((snapshot) {
            for (var doc in snapshot.docs) {
              doc.reference.delete();
            }
          });
        }
      }

      if (mounted) {
        // Navigate to order success page
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => OrderSuccessPage(
              orderId: widget.orderId,
              paymentId: response.paymentId ?? "Not available",
              deliveryAddress: "${widget.deliveryAddress['street']}, "
                  "${widget.deliveryAddress['city']}, "
                  "${widget.deliveryAddress['state']} - "
                  "${widget.deliveryAddress['pincode']}",
              totalAmount: widget.totalAmount,
            ),
          ),
          (route) => route.isFirst, // Clear all routes except the first one
        );
      }
    } catch (e) {
      print("Error updating order after payment: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "Payment successful but there was an error updating your order."),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print("Payment Error: ${response.message}");
    setState(() => _isProcessing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            "Payment Failed: ${response.message ?? 'Error processing payment'}"),
        duration: const Duration(seconds: 3),
      ),
    );

    // Update the order status in Firestore
    FirebaseFirestore.instance.collection('orders').doc(widget.orderId).update({
      'paymentStatus': 'failed',
      'paymentError': response.message,
    }).catchError((error) {
      print("Error updating order payment status: $error");
    });
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print("External Wallet Selected: ${response.walletName}");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("External Wallet: ${response.walletName}"),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _razorpay.clear(); // Clean up resources
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Processing Payment"),
        backgroundColor: AppColors().mainColor,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isProcessing) const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              "Processing payment for Order #${widget.orderId.substring(0, 8)}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            if (!_isProcessing)
              ElevatedButton(
                onPressed: openCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors().mainColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(
                  "Retry Payment",
                  style: TextStyle(color: AppColors().white),
                ),
              ),
            const SizedBox(height: 16),
            if (!_isProcessing)
              TextButton(
                onPressed: () {
                  // Cancel the order
                  FirebaseFirestore.instance
                      .collection('orders')
                      .doc(widget.orderId)
                      .update({
                    'status': 'cancelled',
                    'paymentStatus': 'cancelled',
                  }).then((_) {
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/home', (route) => false);
                  });
                },
                child: const Text("Cancel Order"),
              ),
          ],
        ),
      ),
    );
  }
}

// Order Success Page
class OrderSuccessPage extends StatelessWidget {
  final String orderId;
  final String paymentId;
  final String deliveryAddress;
  final double totalAmount;

  const OrderSuccessPage({
    Key? key,
    required this.orderId,
    required this.paymentId,
    required this.deliveryAddress,
    required this.totalAmount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Confirmed"),
        backgroundColor: AppColors().mainColor,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 100,
            ),
            const SizedBox(height: 24),
            const Text(
              "Thank You!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Your order has been placed successfully",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Order Details",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow("Order ID", "#${orderId.substring(0, 8)}"),
                  _buildDetailRow("Payment ID", paymentId),
                  _buildDetailRow(
                      "Amount", "₹${totalAmount.toStringAsFixed(2)}"),
                  _buildDetailRow("Delivery Address", deliveryAddress),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/home', (route) => false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors().mainColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: Text(
                "Continue Shopping",
                style: TextStyle(color: AppColors().white),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// Order History Page
class OrdersHistoryPage extends StatefulWidget {
  const OrdersHistoryPage({Key? key}) : super(key: key);

  @override
  _OrdersHistoryPageState createState() => _OrdersHistoryPageState();
}

class _OrdersHistoryPageState extends State<OrdersHistoryPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];
  Map<String, double> _orderRatings = {};

  @override
  void initState() {
    super.initState();
    _fetchOrdersAndRatings();
  }

  Future<void> _fetchOrdersAndRatings() async {
    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Fetch orders
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      // Fetch ratings for these orders
      final ratingsSnapshot = await FirebaseFirestore.instance
          .collection('orderRatings')
          .where('userId', isEqualTo: userId)
          .get();

      // Create a map of order ratings
      final ratings = {
        for (var doc in ratingsSnapshot.docs)
          doc.data()['orderId']: doc.data()['rating']
      };

      setState(() {
        _orders = ordersSnapshot.docs
            .map((doc) => {
                  ...doc.data(),
                  'id': doc.id,
                })
            .toList();
        _orderRatings = ratings
            .map((key, value) => MapEntry(key as String, value as double));
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching orders and ratings: $e');
      setState(() => _isLoading = false);
    }
  }

  String _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'green';
      case 'pending':
        return 'orange';
      case 'delivered':
        return 'blue';
      case 'cancelled':
        return 'red';
      default:
        return 'grey';
    }
  }

  // Method to build rating stars
  Widget _buildRatingStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: index < rating ? Colors.amber : Colors.grey,
          size: 16,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Orders'),
          backgroundColor: AppColors().mainColor,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: AppColors().mainColor,
      ),
      body: _orders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined,
                      size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No orders yet',
                    style: TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your order history will appear here',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/home'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors().mainColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: Text(
                      'Start Shopping',
                      style: TextStyle(color: AppColors().white),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];
                final items = order['items'] as List<dynamic>;
                final createdAt = order['createdAt'] as Timestamp?;
                final date = createdAt != null
                    ? DateTime.fromMillisecondsSinceEpoch(
                        createdAt.millisecondsSinceEpoch)
                    : DateTime.now();

                // Get rating for this order
                final rating = _orderRatings[order['id']];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: InkWell(
                    onTap: () {
                      // Navigate to order details page
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  OrderDetailsPage(order: order)));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Order #${order['id'].toString().substring(0, 8)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(order['status']) ==
                                          'green'
                                      ? Colors.green[100]
                                      : _getStatusColor(order['status']) ==
                                              'orange'
                                          ? Colors.orange[100]
                                          : _getStatusColor(order['status']) ==
                                                  'blue'
                                              ? Colors.blue[100]
                                              : _getStatusColor(
                                                          order['status']) ==
                                                      'red'
                                                  ? Colors.red[100]
                                                  : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  order['status'].toString().toUpperCase(),
                                  style: TextStyle(
                                    color: _getStatusColor(order['status']) ==
                                            'green'
                                        ? Colors.green[800]
                                        : _getStatusColor(order['status']) ==
                                                'orange'
                                            ? Colors.orange[800]
                                            : _getStatusColor(
                                                        order['status']) ==
                                                    'blue'
                                                ? Colors.blue[800]
                                                : _getStatusColor(
                                                            order['status']) ==
                                                        'red'
                                                    ? Colors.red[800]
                                                    : Colors.grey[800],
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          Text(
                            'Placed on ${DateFormat("d/MMM/yyyy 'at' h:mm a").format(date)}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),

                          const SizedBox(height: 8),
                          // Show only the first item and a +X more if there are more items
                          Row(
                            children: [
                              if (items.isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    items[0]['image'],
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 50,
                                        height: 50,
                                        color: Colors.grey[300],
                                        child:
                                            const Icon(Icons.error, size: 20),
                                      );
                                    },
                                  ),
                                ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      items[0]['name'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'Qty: ${items[0]['quantity']} x ₹${items[0]['price'].toStringAsFixed(2)}',
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 13),
                                    ),
                                    if (items.length > 1)
                                      Text(
                                        '+ ${items.length - 1} more items',
                                        style: TextStyle(
                                            color: AppColors().mainColor,
                                            fontSize: 13),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '₹${order['total'].toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors().mainColor,
                                ),
                              ),
                            ],
                          ),

                          // Add rating display if order has been rated
                          if (rating != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text(
                                  'Your Rating: ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                _buildRatingStars(rating),
                              ],
                            ),
                          ],

                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    // Navigate to order details page
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                OrderDetailsPage(
                                                    order: order)));
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                        color: AppColors().mainColor),
                                  ),
                                  child: Text(
                                    'View Details',
                                    style:
                                        TextStyle(color: AppColors().mainColor),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
// Order Details Page
// Add this to your OrderDetailsPage class
// Modifications to OrderDetailsPage class

class OrderDetailsPage extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetailsPage({Key? key, required this.order}) : super(key: key);

  @override
  _OrderDetailsPageState createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  double _rating = 0;
  String _review = '';
  bool _isSubmitting = false;
  TextEditingController _reviewController = TextEditingController();

  String _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'green';
      case 'pending':
        return 'orange';
      case 'delivered':
        return 'blue';
      case 'cancelled':
        return 'red';
      default:
        return 'grey';
    }
  }

  // Add this method to check if the order has been rated already
  Future<bool> _hasOrderBeenRated() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('orderRatings')
          .where('orderId', isEqualTo: widget.order['id'])
          .limit(1)
          .get();

      return docSnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking order rating: $e');
      return false;
    }
  }

  // Add this method to submit the rating to Firestore
  Future<void> _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get current user ID
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Create rating document
      await FirebaseFirestore.instance.collection('orderRatings').add({
        'orderId': widget.order['id'],
        'userId': userId,
        'rating': _rating,
        'review': _review,
        'items': widget.order['items'],
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you for your feedback!'),
          backgroundColor: Colors.green,
        ),
      );

      // Update state to show the submitted rating
      setState(() {});
    } catch (e) {
      print('Error submitting rating: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit rating: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  // Build rating widget
  Widget _buildRatingSection(BuildContext context) {
    return FutureBuilder<bool>(
        future: _hasOrderBeenRated(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final bool hasRated = snapshot.data ?? false;

          if (hasRated) {
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Rating',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You have already rated this order',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
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

          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rate Your Order',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        // Star rating
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            return IconButton(
                              icon: Icon(
                                index < _rating
                                    ? Icons.star
                                    : Icons.star_border,
                                color: index < _rating
                                    ? Colors.amber
                                    : Colors.grey,
                                size: 36,
                              ),
                              onPressed: () {
                                setState(() {
                                  _rating = index + 1;
                                });
                              },
                            );
                          }),
                        ),

                        const SizedBox(height: 16),

                        TextField(
                          controller: _reviewController,
                          decoration: const InputDecoration(
                            hintText: 'Share your experience (optional)',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.all(16),
                          ),
                          maxLines: 3,
                        ),

                        const SizedBox(height: 16),

                        // Submit button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitRating,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors().mainColor,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : Text(
                                    'Submit Review',
                                    style: TextStyle(
                                      color: AppColors().white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  Widget _buildOrderTimeline(BuildContext context) {
    // Order status progression
    final List<String> statusSteps = [
      'pending',
      'confirmed',
      'shipped',
      'out for delivery',
      'delivered'
    ];
    final currentStatus = widget.order['status'].toString().toLowerCase();

    // Find the current step index
    int currentStepIndex = statusSteps.indexOf(currentStatus);
    if (currentStepIndex == -1) {
      currentStepIndex =
          currentStatus == 'cancelled' ? -2 : 0; // Special case for cancelled
    }

    // Get timestamps for each status if available
    final Map<String, dynamic> statusTimestamps =
        widget.order['statusTimestamps'] as Map<String, dynamic>? ?? {};

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Timeline',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 24),

            // Cancelled status needs special handling
            if (currentStatus == 'cancelled')
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cancel, color: Colors.red[700], size: 24),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order Cancelled',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (statusTimestamps.containsKey('cancelled'))
                            Text(
                              _formatTimestamp(statusTimestamps['cancelled']),
                              style: TextStyle(
                                  color: Colors.red[700], fontSize: 14),
                            ),
                          if (widget.order.containsKey('cancellationReason'))
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Reason: ${widget.order['cancellationReason']}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              // Regular status timeline
              Column(
                children: List.generate(statusSteps.length, (index) {
                  final status = statusSteps[index];
                  final isCompleted = index <= currentStepIndex;
                  final isCurrent = index == currentStepIndex;

                  // Get timestamp for this status if available
                  final timestamp = statusTimestamps[status] as Timestamp?;
                  final hasTimestamp = timestamp != null;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status indicator and connector line
                      Column(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? AppColors().mainColor
                                  : Colors.grey[300],
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                isCompleted ? Icons.check : Icons.circle,
                                size: 16,
                                color: isCompleted
                                    ? Colors.white
                                    : Colors.grey[400],
                              ),
                            ),
                          ),
                          if (index < statusSteps.length - 1)
                            Container(
                              width: 2,
                              height: 50,
                              color: isCompleted
                                  ? AppColors().mainColor
                                  : Colors.grey[300],
                            ),
                        ],
                      ),
                      const SizedBox(width: 16),

                      // Status content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatStatusText(status),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isCurrent ? AppColors().mainColor : null,
                                fontSize: 15,
                              ),
                            ),
                            if (hasTimestamp) ...[
                              const SizedBox(height: 4),
                              Text(
                                _formatTimestamp(timestamp),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],

                            // Add estimated delivery date if it's not yet delivered
                            if (status == 'out for delivery' &&
                                isCurrent &&
                                widget.order
                                    .containsKey('estimatedDelivery')) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Estimated delivery: ${_formatEstimatedDelivery(widget.order['estimatedDelivery'])}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],

                            SizedBox(
                                height:
                                    index < statusSteps.length - 1 ? 30 : 0),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }

  String _formatStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Order Placed';
      case 'confirmed':
        return 'Order Confirmed';
      case 'shipped':
        return 'Order Shipped';
      case 'out for delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      default:
        return status.split(' ').map((word) => word.capitalize()).join(' ');
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date =
        DateTime.fromMillisecondsSinceEpoch(timestamp.millisecondsSinceEpoch);
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatEstimatedDelivery(Timestamp timestamp) {
    final date =
        DateTime.fromMillisecondsSinceEpoch(timestamp.millisecondsSinceEpoch);
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.order['items'] as List<dynamic>;
    final createdAt = widget.order['createdAt'] as Timestamp?;
    final date = createdAt != null
        ? DateTime.fromMillisecondsSinceEpoch(createdAt.millisecondsSinceEpoch)
        : DateTime.now();
    final address = widget.order['deliveryAddress'] as Map<String, dynamic>?;
    final isDelivered =
        widget.order['status'].toString().toLowerCase() == 'delivered';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: AppColors().mainColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Order ID',
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          '#${widget.order['id'].toString().substring(0, 8)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Order Date',
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          'Placed on ${DateFormat("d/MMM/yyyy 'at' h:mm a").format(date)}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Amount',
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          '₹${widget.order['total'].toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Payment Status',
                          style: TextStyle(color: Colors.grey),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                                        widget.order['paymentStatus']) ==
                                    'green'
                                ? Colors.green[100]
                                : _getStatusColor(
                                            widget.order['paymentStatus']) ==
                                        'orange'
                                    ? Colors.orange[100]
                                    : _getStatusColor(widget
                                                .order['paymentStatus']) ==
                                            'blue'
                                        ? Colors.blue[100]
                                        : _getStatusColor(widget
                                                    .order['paymentStatus']) ==
                                                'red'
                                            ? Colors.red[100]
                                            : Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.order['paymentStatus']
                                .toString()
                                .toUpperCase(),
                            style: TextStyle(
                              color: _getStatusColor(
                                          widget.order['paymentStatus']) ==
                                      'green'
                                  ? Colors.green[800]
                                  : _getStatusColor(
                                              widget.order['paymentStatus']) ==
                                          'orange'
                                      ? Colors.orange[800]
                                      : _getStatusColor(widget
                                                  .order['paymentStatus']) ==
                                              'blue'
                                          ? Colors.blue[800]
                                          : _getStatusColor(widget.order[
                                                      'paymentStatus']) ==
                                                  'red'
                                              ? Colors.red[800]
                                              : Colors.grey[800],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Order Timeline
            _buildOrderTimeline(context),
            const SizedBox(height: 16),

            // Rating section (only shown for delivered orders)
            if (isDelivered) ...[
              _buildRatingSection(context),
              const SizedBox(height: 16),
            ],

            // Delivery Address
            if (address != null)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delivery Address',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        address['name'] ?? 'N/A',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        address['addressLine1'] ?? 'N/A',
                        style: const TextStyle(fontSize: 14),
                      ),
                      if (address['addressLine2'] != null)
                        Text(
                          address['addressLine2'],
                          style: const TextStyle(fontSize: 14),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        '${address['city'] ?? ''}, ${address['state'] ?? ''} - ${address['pincode'] ?? ''}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Phone: ${address['phone'] ?? 'N/A'}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Order Items
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Items',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Item image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  item['image'],
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 70,
                                      height: 70,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.error),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Item details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Weight: ${item['weight']} • Qty: ${item['quantity']}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₹${item['price'].toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Add this extension to capitalize the first letter of each word
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
