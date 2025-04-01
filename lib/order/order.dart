import 'package:cakebliss_admin/constants/appcolor.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({Key? key}) : super(key: key);

  @override
  _AdminOrdersPageState createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _users = [];
  String? _selectedUserId;
  // Add this to toggle between showing all orders and user list
  bool _showUsersList = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);

    try {
      // First fetch all orders to get unique user IDs
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .get();

      // Get unique user IDs from orders
      final Set<String> userIds = {};
      for (var doc in ordersSnapshot.docs) {
        userIds.add(doc.data()['userId'] as String);
      }

      // Now fetch user details
      final List<Map<String, dynamic>> userData = [];

      for (String userId in userIds) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          // Count orders for this user
          final userOrdersSnapshot = await FirebaseFirestore.instance
              .collection('orders')
              .where('userId', isEqualTo: userId)
              .get();

          userData.add({
            ...userDoc.data()!,
            'id': userDoc.id,
            'displayName': userDoc.data()?['displayName'] ??
                userDoc.data()?['name'] ??
                'Unknown User',
            'orderCount': userOrdersSnapshot.docs.length,
          });
        }
      }

      setState(() {
        _users = userData;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching users: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAllOrders() async {
    setState(() => _isLoading = true);

    try {
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _orders = ordersSnapshot.docs
            .map((doc) => {
                  ...doc.data(),
                  'id': doc.id,
                })
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching all orders: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchOrdersByUser(String userId) async {
    setState(() => _isLoading = true);

    try {
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _orders = ordersSnapshot.docs
            .map((doc) => {
                  ...doc.data(),
                  'id': doc.id,
                })
            .toList();
        _isLoading = false;
        _selectedUserId = userId;
        _showUsersList = false; // Switch to orders view
      });
    } catch (e) {
      print('Error fetching orders for user: $e');
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
      case 'canceled':
        return 'red';
      case 'processing':
        return 'purple';
      case 'shipped':
        return 'teal';
      default:
        return 'grey';
    }
  }

  Color _getStatusColorAsColor(String status) {
    switch (_getStatusColor(status)) {
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'blue':
        return Colors.blue;
      case 'red':
        return Colors.red;
      case 'purple':
        return Colors.purple;
      case 'teal':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusBackgroundColor(String status) {
    switch (_getStatusColor(status)) {
      case 'green':
        return Colors.green[100]!;
      case 'orange':
        return Colors.orange[100]!;
      case 'blue':
        return Colors.blue[100]!;
      case 'red':
        return Colors.red[100]!;
      case 'purple':
        return Colors.purple[100]!;
      case 'teal':
        return Colors.teal[100]!;
      default:
        return Colors.grey[100]!;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (_getStatusColor(status)) {
      case 'green':
        return Colors.green[800]!;
      case 'orange':
        return Colors.orange[800]!;
      case 'blue':
        return Colors.blue[800]!;
      case 'red':
        return Colors.red[800]!;
      case 'purple':
        return Colors.purple[800]!;
      case 'teal':
        return Colors.teal[800]!;
      default:
        return Colors.grey[800]!;
    }
  }

  String _getUserName(String userId) {
    final user = _users.firstWhere((user) => user['id'] == userId,
        orElse: () => {'displayName': 'Unknown User'});
    return user['displayName'] ?? 'Unknown User';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        title: Text(
          _showUsersList
              ? 'Customer order List'
              : _selectedUserId != null
                  ? 'Orders - ${_getUserName(_selectedUserId!)}'
                  : 'Admin - All Orders',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors().mainColor,
        actions: [
          if (!_showUsersList)
            // IconButton(
            //   icon: const Icon(Icons.people),
            //   onPressed: () {
            //     setState(() {
            //       _showUsersList = true;
            //       _selectedUserId = null;
            //     });
            //   },
            //   tooltip: 'Show User List',
            // ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                if (_showUsersList) {
                  _fetchUsers();
                } else if (_selectedUserId == null) {
                  _fetchAllOrders();
                } else {
                  _fetchOrdersByUser(_selectedUserId!);
                }
              },
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _showUsersList
              ? _buildUsersList()
              : _buildOrdersList(),
    );
  }

  Widget _buildUsersList() {
    return _users.isEmpty
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No customers found',
                  style: TextStyle(fontSize: 20),
                ),
                SizedBox(height: 8),
                Text(
                  'There are no customers with orders in the system yet',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _users.length,
            itemBuilder: (context, index) {
              final user = _users[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: InkWell(
                  onTap: () {
                    _fetchOrdersByUser(user['id']);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // User avatar
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: user['imageUrl'] != null &&
                                  user['imageUrl'].toString().isNotEmpty
                              ? NetworkImage(user['imageUrl'])
                              : null,
                          child: user['imageUrl'] == null ||
                                  user['imageUrl'].toString().isEmpty
                              ? Icon(Icons.person, color: Colors.grey[800])
                              : null,
                        ),
                        const SizedBox(width: 16),
                        // User details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user['displayName'] ?? 'Unknown User',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user['email'] ?? 'No email provided',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user['phone'] ?? 'No phone provided',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Order count
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors().mainColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${user['orderCount']} orders',
                            style: TextStyle(
                              color: AppColors().mainColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
  }

  Widget _buildOrdersList() {
    return Column(
      children: [
        if (_selectedUserId != null)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // ElevatedButton.icon(
                //   icon: const Icon(Icons.arrow_back),
                //   label: const Text('Back to Customers'),
                //   onPressed: () {
                //     setState(() {
                //       _showUsersList = true;
                //       _selectedUserId = null;
                //     });
                //   },
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: Colors.grey[200],
                //     foregroundColor: Colors.black87,
                //   ),
                // ),
              ],
            ),
          ),
        Expanded(
          child: _orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_bag_outlined,
                          size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No orders found',
                        style: TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedUserId == null
                            ? 'There are no orders in the system yet'
                            : 'This customer has no orders yet',
                        style: const TextStyle(color: Colors.grey),
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
                                  AdminOrderDetailsPage(order: order),
                            ),
                          ).then((_) {
                            // Refresh data when returning from details page
                            if (_selectedUserId == null) {
                              _fetchAllOrders();
                            } else {
                              _fetchOrdersByUser(_selectedUserId!);
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Order #${order['id'].toString().substring(0, 8)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  // Making the status clickable
                                  InkWell(
                                    onTap: () {
                                      _showUpdateStatusDialog(context, order);
                                    },
                                    borderRadius: BorderRadius.circular(4),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusBackgroundColor(
                                            order['status']),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            order['status']
                                                .toString()
                                                .toUpperCase(),
                                            style: TextStyle(
                                              color: _getStatusTextColor(
                                                  order['status']),
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.edit,
                                            size: 12,
                                            color: _getStatusTextColor(
                                                order['status']),
                                          ),
                                        ],
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
                              const Divider(height: 16),
                              Text(
                                '${items.length} ${items.length == 1 ? 'item' : 'items'}',
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
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            width: 50,
                                            height: 50,
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.error,
                                                size: 20),
                                          );
                                        },
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
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
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                AdminOrderDetailsPage(
                                                    order: order),
                                          ),
                                        ).then((_) {
                                          // Refresh when returning from details
                                          if (_selectedUserId == null) {
                                            _fetchAllOrders();
                                          } else {
                                            _fetchOrdersByUser(
                                                _selectedUserId!);
                                          }
                                        });
                                      },
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                            color: AppColors().mainColor),
                                      ),
                                      child: Text(
                                        'View Details',
                                        style: TextStyle(
                                            color: AppColors().mainColor),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton(
                                    onPressed: () {
                                      _showUpdateStatusDialog(context, order);
                                    },
                                    style: OutlinedButton.styleFrom(
                                      side:
                                          const BorderSide(color: Colors.blue),
                                    ),
                                    child: const Text(
                                      'Update Status',
                                      style: TextStyle(color: Colors.blue),
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
        ),
      ],
    );
  }

  void _showUpdateStatusDialog(
      BuildContext context, Map<String, dynamic> order) {
    final statuses = [
      'pending',
      'confirmed',
      'processing',
      'shipped',
      'delivered',
      'cancelled'
    ];
    String selectedStatus = order['status'] ?? 'pending';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Order Status'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Order #${order['id'].toString().substring(0, 8)}'),
                  const SizedBox(height: 16),
                  // Enhanced status selection with color indicators
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: statuses.map((status) {
                        bool isSelected = selectedStatus == status;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              selectedStatus = status;
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _getStatusBackgroundColor(status)
                                  : Colors.transparent,
                              border: Border(
                                bottom: BorderSide(
                                  color: statuses.last == status
                                      ? Colors.transparent
                                      : Colors.grey.shade200,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _getStatusColorAsColor(status),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? _getStatusTextColor(status)
                                        : Colors.black87,
                                  ),
                                ),
                                const Spacer(),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle,
                                    color: _getStatusColorAsColor(status),
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('orders')
                      .doc(order['id'])
                      .update({'status': selectedStatus});

                  // Update the local order list to reflect changes immediately
                  final int orderIndex =
                      _orders.indexWhere((o) => o['id'] == order['id']);
                  if (orderIndex != -1) {
                    setState(() {
                      _orders[orderIndex]['status'] = selectedStatus;
                    });
                  }

                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Order status updated to ${selectedStatus.toUpperCase()}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  print('Error updating order status: $e');
                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating order status: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(
                backgroundColor: AppColors().mainColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }
}

// Admin Order Details Page with Status Update Functionality
class AdminOrderDetailsPage extends StatefulWidget {
  final Map<String, dynamic> order;

  const AdminOrderDetailsPage({Key? key, required this.order})
      : super(key: key);

  @override
  _AdminOrderDetailsPageState createState() => _AdminOrderDetailsPageState();
}

class _AdminOrderDetailsPageState extends State<AdminOrderDetailsPage> {
  late Map<String, dynamic> _order;

  @override
  void initState() {
    super.initState();
    // Create a local copy of the order that we can modify
    _order = Map<String, dynamic>.from(widget.order);
  }

  String _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'orange'; // Yellow/orange for pending
      case 'processing':
        return 'blue'; // Blue for processing
      case 'out of delivery':
        return 'lightgreen'; // Light green for out of delivery
      case 'delivered':
        return 'darkgreen'; // Dark green for delivered
      case 'cancelled':
      case 'canceled':
        return 'red'; // Red for cancelled
      default:
        return 'grey';
    }
  }

  Color _getStatusColorAsColor(String status) {
    switch (_getStatusColor(status)) {
      case 'orange':
        return Colors.orange;
      case 'blue':
        return Colors.blue;
      case 'lightgreen':
        return Colors.green[400]!; // Light green
      case 'darkgreen':
        return Colors.green[800]!; // Dark green
      case 'red':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusBackgroundColor(String status) {
    switch (_getStatusColor(status)) {
      case 'orange':
        return Colors.orange[100]!;
      case 'blue':
        return Colors.blue[100]!;
      case 'lightgreen':
        return Colors.green[100]!;
      case 'darkgreen':
        return Colors.green[200]!;
      case 'red':
        return Colors.red[100]!;
      default:
        return Colors.grey[100]!;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (_getStatusColor(status)) {
      case 'orange':
        return Colors.orange[800]!;
      case 'blue':
        return Colors.blue[800]!;
      case 'lightgreen':
        return Colors.green[600]!;
      case 'darkgreen':
        return Colors.green[900]!;
      case 'red':
        return Colors.red[800]!;
      default:
        return Colors.grey[800]!;
    }
  }

  void _showUpdateStatusDialog(BuildContext context) {
    final statuses = [
      'pending',
      'processing',
      'shipped',
      'delivered',
      'cancelled'
    ];
    String selectedStatus = _order['status'] ?? 'pending';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Order Status'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Order #${_order['id'].toString().substring(0, 8)}'),
                  const SizedBox(height: 16),
                  // Enhanced status selection with color indicators
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: statuses.map((status) {
                        bool isSelected = selectedStatus == status;
                        return InkWell(
                          onTap: () {
                            setDialogState(() {
                              selectedStatus = status;
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _getStatusBackgroundColor(status)
                                  : Colors.transparent,
                              border: Border(
                                bottom: BorderSide(
                                  color: statuses.last == status
                                      ? Colors.transparent
                                      : Colors.grey.shade200,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _getStatusColorAsColor(status),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? _getStatusTextColor(status)
                                        : Colors.black87,
                                  ),
                                ),
                                const Spacer(),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle,
                                    color: _getStatusColorAsColor(status),
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  // Update the order status in Firestore
                  await FirebaseFirestore.instance
                      .collection('orders')
                      .doc(_order['id'])
                      .update({
                    'status': selectedStatus,
                    'lastUpdated': FieldValue.serverTimestamp(),
                    'statusHistory': FieldValue.arrayUnion([
                      {
                        'status': selectedStatus,
                        'timestamp': FieldValue.serverTimestamp(),
                        'updatedBy': 'admin'
                      }
                    ])
                  });

                  // Update the local state to reflect the new status
                  setState(() {
                    _order['status'] = selectedStatus;
                  });

                  Navigator.of(context).pop();

                  // Show a success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Order status updated to ${selectedStatus.toUpperCase()}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  print('Error updating order status: $e');
                  Navigator.of(context).pop();

                  // Show an error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating order status: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(
                backgroundColor: AppColors().mainColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _order['items'] as List<dynamic>;
    final createdAt = _order['createdAt'] as Timestamp?;
    final date = createdAt != null
        ? DateTime.fromMillisecondsSinceEpoch(createdAt.millisecondsSinceEpoch)
        : DateTime.now();
    final address = _order['deliveryAddress'] as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        title: Center(
            child: const Text(
          'Order Details',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        )),
        backgroundColor: AppColors().mainColor,
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.edit),
          //   onPressed: () {
          //     _showUpdateStatusDialog(context);
          //   },
          //   tooltip: 'Update Status',
          // ),
        ],
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
                          '#${_order['id'].toString().substring(0, 8)}',
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
                          '₹${_order['total'].toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Order Status',
                          style: TextStyle(color: Colors.grey),
                        ),
                        InkWell(
                          onTap: () {
                            _showUpdateStatusDialog(context);
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  _getStatusBackgroundColor(_order['status']),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _order['status'].toString().toUpperCase(),
                                  style: TextStyle(
                                    color:
                                        _getStatusTextColor(_order['status']),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.edit,
                                  size: 12,
                                  color: _getStatusTextColor(_order['status']),
                                ),
                              ],
                            ),
                          ),
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
                            color: _getStatusBackgroundColor(
                                _order['paymentStatus']),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _order['paymentStatus'].toString().toUpperCase(),
                            style: TextStyle(
                              color:
                                  _getStatusTextColor(_order['paymentStatus']),
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

            // Customer Information
            FutureBuilder<Map<String, dynamic>?>(
              future: _getUserDetails(_order['userId']),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }

                final userData = snapshot.data;

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
                          'Customer Information',
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
                              'Name',
                              style: TextStyle(color: Colors.grey),
                            ),
                            Text(
                              userData?['name'] ?? 'Name',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Email',
                              style: TextStyle(color: Colors.grey),
                            ),
                            Text(
                              userData?['email'] ?? 'N/A',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Phone',
                              style: TextStyle(color: Colors.grey),
                            ),
                            Text(
                              userData?['phone'] ?? 'N/A',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'User ID',
                              style: TextStyle(color: Colors.grey),
                            ),
                            Text(
                              _order['userId'],
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

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
                                      child: const Icon(Icons.error, size: 20),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
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
                                      'Qty: ${item['quantity']} x ₹${item['price'].toStringAsFixed(2)}',
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Total: ₹${(item['quantity'] * item['price']).toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: Colors.grey[800],
                                        fontWeight: FontWeight.bold,
                                      ),
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
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _getUserDetails(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        return {
          ...userDoc.data()!,
          'id': userDoc.id,
        };
      }
      return null;
    } catch (e) {
      print('Error fetching user details: $e');
      return null;
    }
  }
}
