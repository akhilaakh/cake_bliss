import 'package:cakebliss_admin/constants/appcolor.dart';
import 'package:cakebliss_admin/customization/customization_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CustomerList extends StatelessWidget {
  CustomerList({Key? key}) : super(key: key);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors().mainColor,
        toolbarHeight: 100,
        title: const Text(
          'Customer Customizations',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('customizations').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No customization requests found'));
          }

          final Set<String> userIds = snapshot.data!.docs
              .map((doc) =>
                  (doc.data() as Map<String, dynamic>)['userId'] as String)
              .toSet();

          return StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('users')
                .where(FieldPath.documentId, whereIn: userIds.toList())
                .snapshots(),
            builder: (context, userSnapshot) {
              if (!userSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              return ListView.builder(
                itemCount: userSnapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final userData = userSnapshot.data!.docs[index].data()
                      as Map<String, dynamic>;
                  final userId = userSnapshot.data!.docs[index].id;
                  final userName = userData['name'] ?? 'Unknown User';

                  final userCustomizations = snapshot.data!.docs
                      .where((doc) =>
                          (doc.data() as Map<String, dynamic>)['userId'] ==
                          userId)
                      .toList();

                  final pendingCount = userCustomizations.where((doc) {
                    final status = (doc.data()
                        as Map<String, dynamic>)['status'] as String?;
                    return status == null || status.toLowerCase() == 'pending';
                  }).length;

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(userName),
                      subtitle: Text(
                        '${userCustomizations.length} customization(s) • $pendingCount pending',
                        style: TextStyle(
                          color: pendingCount > 0 ? Colors.orange : Colors.grey,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CustomizationDetailView(
                              userId: userId,
                              userName: userName,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}