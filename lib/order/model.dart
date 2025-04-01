// // First, let's create a model for the status history entry
// import 'package:cakebliss_admin/constants/appcolor.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';

// class OrderStatusHistory {
//   final String status;
//   final Timestamp timestamp;
//   final String updatedBy;
//   final String? note;

//   OrderStatusHistory({
//     required this.status,
//     required this.timestamp,
//     required this.updatedBy,
//     this.note,
//   });

//   Map<String, dynamic> toMap() {
//     return {
//       'status': status,
//       'timestamp': timestamp,
//       'updatedBy': updatedBy,
//       'note': note,
//     };
//   }

//   factory OrderStatusHistory.fromMap(Map<String, dynamic> map) {
//     return OrderStatusHistory(
//       status: map['status'],
//       timestamp: map['timestamp'],
//       updatedBy: map['updatedBy'],
//       note: map['note'],
//     );
//   }
// }

// // Function to update order status with history tracking
// Future<void> updateOrderStatus({
//   required String orderId,
//   required String newStatus,
//   required String updatedBy,
//   String? note,
// }) async {
//   final orderRef = FirebaseFirestore.instance.collection('orders').doc(orderId);
  
//   // Create a new history entry
//   final historyEntry = OrderStatusHistory(
//     status: newStatus,
//     timestamp: Timestamp.now(),
//     updatedBy: updatedBy,
//     note: note,
//   ).toMap();
  
//   // Run as a transaction to ensure consistency
//   return FirebaseFirestore.instance.runTransaction((transaction) async {
//     // Get the current order document
//     DocumentSnapshot orderSnapshot = await transaction.get(orderRef);
    
//     if (!orderSnapshot.exists) {
//       throw Exception("Order not found!");
//     }
    
//     // Get the current order data
//     Map<String, dynamic> orderData = orderSnapshot.data() as Map<String, dynamic>;
    
//     // Initialize or get the existing status history array
//     List<dynamic> statusHistory = orderData['statusHistory'] ?? [];
    
//     // Add the new history entry
//     statusHistory.add(historyEntry);
    
//     // Update the order with new status and history
//     transaction.update(orderRef, {
//       'status': newStatus,
//       'statusHistory': statusHistory,
//       'lastUpdated': Timestamp.now(),
//     });
//   });
// }

// // Modify the status update dialog in _showUpdateStatusDialog
// void _showUpdateStatusDialog(BuildContext context, Map<String, dynamic> order) {
//   final statuses = [
//     'pending',
//     'confirmed',
//     'processing',
//     'shipped',
//     'delivered',
//     'cancelled'
//   ];
//   String selectedStatus = order['status'] ?? 'pending';
//   TextEditingController noteController = TextEditingController();

//   showDialog(
//     context: context,
//     builder: (BuildContext context) {
//       return AlertDialog(
//         title: const Text('Update Order Status'),
//         content: StatefulBuilder(
//           builder: (BuildContext context, StateSetter setState) {
//             return SingleChildScrollView(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text('Order #${order['id'].toString().substring(0, 8)}'),
//                   const SizedBox(height: 16),
//                   // Status selection with color indicators
//                   Container(
//                     decoration: BoxDecoration(
//                       border: Border.all(color: Colors.grey.shade300),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Column(
//                       children: statuses.map((status) {
//                         bool isSelected = selectedStatus == status;
//                         return InkWell(
//                           onTap: () {
//                             setState(() {
//                               selectedStatus = status;
//                             });
//                           },
//                           child: Container(
//                             width: double.infinity,
//                             padding: const EdgeInsets.symmetric(
//                                 vertical: 12, horizontal: 16),
//                             decoration: BoxDecoration(
//                               color: isSelected
//                                   ? _getStatusBackgroundColor(status)
//                                   : Colors.transparent,
//                               border: Border(
//                                 bottom: BorderSide(
//                                   color: statuses.last == status
//                                       ? Colors.transparent
//                                       : Colors.grey.shade200,
//                                 ),
//                               ),
//                             ),
//                             child: Row(
//                               children: [
//                                 Container(
//                                   width: 16,
//                                   height: 16,
//                                   decoration: BoxDecoration(
//                                     shape: BoxShape.circle,
//                                     color: _getStatusColorAsColor(status),
//                                   ),
//                                 ),
//                                 const SizedBox(width: 12),
//                                 Text(
//                                   status.toUpperCase(),
//                                   style: TextStyle(
//                                     fontWeight: isSelected
//                                         ? FontWeight.bold
//                                         : FontWeight.normal,
//                                     color: isSelected
//                                         ? _getStatusTextColor(status)
//                                         : Colors.black87,
//                                   ),
//                                 ),
//                                 const Spacer(),
//                                 if (isSelected)
//                                   Icon(
//                                     Icons.check_circle,
//                                     color: _getStatusColorAsColor(status),
//                                     size: 20,
//                                   ),
//                               ],
//                             ),
//                           ),
//                         );
//                       }).toList(),
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   // Add note field
//                   TextField(
//                     controller: noteController,
//                     decoration: const InputDecoration(
//                       labelText: 'Status Update Note (Optional)',
//                       border: OutlineInputBorder(),
//                       hintText: 'Enter any notes about this status change',
//                     ),
//                     maxLines: 3,
//                   ),
//                 ],
//               ),
//             );
//           },
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.of(context).pop();
//             },
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () async {
//               try {
//                 // Get current user ID or name
//                 final String updatedBy = "Admin"; // Replace with actual admin ID or name if available
                
//                 // Use the new function to update status with history
//                 await updateOrderStatus(
//                   orderId: order['id'],
//                   newStatus: selectedStatus,
//                   updatedBy: updatedBy,
//                   note: noteController.text.isNotEmpty ? noteController.text : null,
//                 );

//                 // Update the local order list to reflect changes immediately
//                 final int orderIndex = _orders.indexWhere((o) => o['id'] == order['id']);
//                 if (orderIndex != -1) {
//                   setState(() {
//                     _orders[orderIndex]['status'] = selectedStatus;
//                   });
//                 }

//                 Navigator.of(context).pop();

//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(
//                     content: Text('Order status updated to ${selectedStatus.toUpperCase()}'),
//                     backgroundColor: Colors.green,
//                   ),
//                 );
//               } catch (e) {
//                 print('Error updating order status: $e');
//                 Navigator.of(context).pop();

//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(
//                     content: Text('Error updating order status: $e'),
//                     backgroundColor: Colors.red,
//                   ),
//                 );
//               }
//             },
//             style: TextButton.styleFrom(
//               backgroundColor: AppColors().mainColor,
//               foregroundColor: Colors.white,
//             ),
//             child: const Text('Update'),
//           ),
//         ],
//       );
//     },
//   );
// }

// // Add this method to AdminOrderDetailsPage to display status history
// Widget _buildStatusHistoryTimeline(List<dynamic> statusHistory) {
//   // Sort by timestamp, newest first
//   statusHistory.sort((a, b) => 
//     (b['timestamp'] as Timestamp).compareTo(a['timestamp'] as Timestamp));

//   return Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       Text(
//         'Status History',
//         style: TextStyle(
//           fontSize: 18,
//           fontWeight: FontWeight.bold,
//           color: Colors.grey[800],
//         ),
//       ),
//       const SizedBox(height: 16),
//       ListView.builder(
//         shrinkWrap: true,
//         physics: const NeverScrollableScrollPhysics(),
//         itemCount: statusHistory.length,
//         itemBuilder: (context, index) {
//           final entry = statusHistory[index];
//           final timestamp = entry['timestamp'] as Timestamp;
//           final date = DateTime.fromMillisecondsSinceEpoch(
//               timestamp.millisecondsSinceEpoch);
          
//           return Padding(
//             padding: const EdgeInsets.only(bottom: 16),
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Container(
//                   width: 16,
//                   height: 16,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: _getStatusColorAsColor(entry['status']),
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             entry['status'].toString().toUpperCase(),
//                             style: const TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                           Text(
//                             '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
//                             style: TextStyle(
//                               color: Colors.grey[600],
//                               fontSize: 12,
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         'Updated by: ${entry['updatedBy']}',
//                         style: TextStyle(color: Colors.grey[600], fontSize: 13),
//                       ),
//                       if (entry['note'] != null) ...[
//                         const SizedBox(height: 4),
//                         Container(
//                           padding: const EdgeInsets.all(8),
//                           decoration: BoxDecoration(
//                             color: Colors.grey[100],
//                             borderRadius: BorderRadius.circular(4),
//                           ),
//                           child: Text(
//                             entry['note'],
//                             style: TextStyle(
//                               color: Colors.grey[800],
//                               fontSize: 13,
//                               fontStyle: FontStyle.italic,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     ],
//   );
// }

// // Update the AdminOrderDetailsPage build method to include status history

  
//   // ... continue with existing code ...
