import 'package:cakebliss_admin/constants/appcolor.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Import for date formatting

class CustomizationDetailView extends StatelessWidget {
  final String userId;
  final String userName;

  const CustomizationDetailView({
    Key? key,
    required this.userId,
    required this.userName,
  }) : super(key: key);

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return const Color.fromARGB(255, 23, 91, 25);
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _updateStatus(String docId, String status,
      [String? rejectionReason]) async {
    final Map<String, dynamic> updateData = {
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Add rejection reason if provided
    if (rejectionReason != null) {
      updateData['rejectionReason'] = rejectionReason;
    }

    await FirebaseFirestore.instance
        .collection('customizations')
        .doc(docId)
        .update(updateData);
  }

  void _showRejectionReasonInput(BuildContext context, String docId) {
    final TextEditingController reasonController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Reason for Rejection',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Rejection Reason',
                  border: OutlineInputBorder(),
                  hintText:
                      'Please explain why this customization is being rejected',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () async {
                  if (reasonController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please enter a reason for rejection')),
                    );
                    return;
                  }

                  try {
                    // Update status to rejected with the reason
                    await _updateStatus(
                        docId, 'Rejected', reasonController.text);

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Customization rejected successfully')),
                    );
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                },
                child: const Text('SEND REJECTION'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showRateDescriptionInput(
      BuildContext context, String docId, String customizationId) {
    final TextEditingController rateController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController expiryDateController = TextEditingController();
    DateTime? selectedDate;

    // void _selectDate(BuildContext context) async {
    //   final DateTime? picked = await showDatePicker(
    //     context: context,
    //     initialDate: DateTime.now().add(const Duration(days: 7)),
    //     firstDate: DateTime.now(),
    //     lastDate: DateTime.now().add(const Duration(days: 60)),
    //   );
    //   if (picked != null) {
    //     selectedDate = picked;
    //     expiryDateController.text = DateFormat('yyyy-MM-dd').format(picked);
    //   }
    // }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Set Price and Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: rateController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Rate (₹)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // TextField(
              //   controller: expiryDateController,
              //   readOnly: true,
              //   onTap: () => _selectDate(context),
              //   decoration: const InputDecoration(
              //     labelText: 'Expiry Date',
              //     border: OutlineInputBorder(),
              //     suffixIcon: Icon(Icons.calendar_today),
              //     hintText: 'Select expiry date for the order',
              //   ),
              // ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Additional Details',
                  border: OutlineInputBorder(),
                  hintText: 'Enter any additional information for the customer',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors().mainColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () async {
                  if (rateController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a rate')),
                    );
                    return;
                  }

                  // if (expiryDateController.text.isEmpty) {
                  //   ScaffoldMessenger.of(context).showSnackBar(
                  //     const SnackBar(
                  //         content: Text('Please select an expiry date')),
                  //   );
                  //   return;
                  // }

                  try {
                    // Update status to accepted
                    await _updateStatus(docId, 'Accepted');

                    // Create the new confirmation document
                    await FirebaseFirestore.instance
                        .collection('customization_confirmations')
                        .add({
                      'customizationId': docId,
                      'userId': userId,
                      'rate': double.parse(rateController.text),
                      'adminDescription': descriptionController.text,
                      // 'expiryDate': Timestamp.fromDate(selectedDate!),
                      'status': 'Awaiting Customer Response',
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Quote sent to customer successfully')),
                    );
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                },
                child: const Text('SEND'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showStatusLockMessage(BuildContext context, String currentStatus) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'This customization is already $currentStatus. Status cannot be changed.',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red[700],
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildStatusButton(BuildContext context, String currentStatus,
      String newStatus, Color color, String docId) {
    final bool isSelected =
        currentStatus.toLowerCase() == newStatus.toLowerCase();

    // Determine if the status is locked (Accepted or Rejected)
    final bool isStatusLocked = currentStatus.toLowerCase() == 'accepted' ||
        currentStatus.toLowerCase() == 'rejected';

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : AppColors().mainColor,
        foregroundColor: isSelected ? AppColors().subcolor : Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      onPressed: isSelected
          ? null
          : () {
              // Check if status is locked and trying to change to a different status
              if (isStatusLocked &&
                  currentStatus.toLowerCase() != newStatus.toLowerCase()) {
                _showStatusLockMessage(context, currentStatus);
                return;
              }

              if (newStatus == 'Accepted') {
                _showRateDescriptionInput(context, docId, docId);
              } else if (newStatus == 'Rejected') {
                _showRejectionReasonInput(context, docId);
              } else {
                _updateStatus(docId, newStatus);
              }
            },
      child: Text(newStatus),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        backgroundColor: AppColors().mainColor,
        title: Text(
          '$userName\'s Customizations',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('customizations')
            .where('userId', isEqualTo: userId)
            //checking the update in admin side
            // Using client-side sorting instead of orderBy to avoid needing a Firestore index
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No customizations found'));
          }

          // Sort documents client-side
          final sortedDocs = snapshot.data!.docs.toList()
            ..sort((a, b) {
              final Timestamp? aTime =
                  (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
              final Timestamp? bTime =
                  (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;

              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return 1; // null values go last
              if (bTime == null) return -1;

              return bTime.compareTo(aTime); // descending order (newest first)
            });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedDocs.length,
            itemBuilder: (context, index) {
              final doc = sortedDocs[index];
              final customization = doc.data() as Map<String, dynamic>;
              final currentStatus = customization['status'] ?? 'Pending';

              // Format the creation date if available
              String formattedDate = 'No date';
              if (customization['createdAt'] != null) {
                try {
                  final timestamp = customization['createdAt'] as Timestamp;
                  formattedDate = DateFormat('d,MMM, yyyy - h:mm a')
                      .format(timestamp.toDate());
                } catch (e) {
                  formattedDate = 'Invalid date';
                }
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: _getStatusColor(currentStatus).withOpacity(0.1),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                currentStatus.toLowerCase() == 'accepted'
                                    ? Icons.check_circle
                                    : currentStatus.toLowerCase() == 'rejected'
                                        ? Icons.cancel
                                        : Icons.pending,
                                color: _getStatusColor(currentStatus),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                currentStatus,
                                style: TextStyle(
                                  color: _getStatusColor(currentStatus),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (customization['imageUrl'] != null)
                      Image.network(
                        customization['imageUrl'],
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
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
                          if (customization['rejectionReason'] != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Rejection Reason:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                  Text(customization['rejectionReason']),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('customization_confirmations')
                                .where('customizationId', isEqualTo: doc.id)
                                .limit(1)
                                .snapshots(),
                            builder: (context, confirmSnapshot) {
                              if (confirmSnapshot.hasData &&
                                  confirmSnapshot.data!.docs.isNotEmpty) {
                                final confirmData =
                                    confirmSnapshot.data!.docs[0].data()
                                        as Map<String, dynamic>;

                                // Format expiry date if available
                                // String expiryDate = 'No expiry date set';
                                // if (confirmData['expiryDate'] != null) {
                                //   try {
                                //     final timestamp =
                                //         confirmData['expiryDate'] as Timestamp;
                                //     expiryDate = DateFormat('MMM d, yyyy')
                                //         .format(timestamp.toDate());
                                //   } catch (e) {
                                //     expiryDate = 'Invalid date';
                                //   }
                                // }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Divider(),
                                    const Text(
                                      'Admin:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text('Rate: ₹${confirmData['rate']}'),
                                    // Text('Expiry Date: $expiryDate'),
                                    if (confirmData['adminDescription'] !=
                                            null &&
                                        confirmData['adminDescription']
                                            .toString()
                                            .isNotEmpty)
                                      Text(
                                          'Details: ${confirmData['adminDescription']}'),
                                    const SizedBox(height: 8),
                                  ],
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatusButton(context, currentStatus,
                                  'Pending', Colors.orange, doc.id),
                              _buildStatusButton(
                                  context,
                                  currentStatus,
                                  'Accepted',
                                  const Color.fromARGB(255, 23, 91, 25),
                                  doc.id),
                              _buildStatusButton(context, currentStatus,
                                  'Rejected', Colors.red, doc.id),
                            ],
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
