// // import 'package:flutter/material.dart';
// // import 'package:flutter/widgets.dart';

// // class UserTile extends StatelessWidget {
// //   final String text;
// //   final void Function()? onTap;
// //   const UserTile({super.key, required this.text, required this.onTap});

// //   @override
// //   Widget build(BuildContext context) {
// //     return GestureDetector(
// //       onTap: onTap,
// //       child: Container(
// //         decoration: BoxDecoration(
// //             color: Theme.of(context).colorScheme.secondary,
// //             borderRadius: BorderRadius.circular(12)),
// //         child: Row(
// //           children: [Icon(Icons.person), Text('data')],
// //         ),
// //       ),
// //     );
// //   }
// // }
// // chat_services.dart (Admin side)
// import 'package:cakebliss_admin/Screen/homepage.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/widgets.dart';
// import 'package:intl/intl.dart';

// class ChatServices {
//   // Get instance of firestore
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   // Get current user
//   String getCurrentUserEmail() {
//     return _auth.currentUser!.email ?? '';
//   }

//   // Get user stream (for displaying available chat users)
// // Update this in the admin-side ChatServices
//   Stream<List<Map<String, dynamic>>> getUserStream() {
//     return _firestore.collection('users').snapshots().map((snapshot) {
//       return snapshot.docs.map((doc) {
//         final data = doc.data();
//         return {
//           'uid': doc.id,
//           'email': data['email'] ?? '',
//           'name': data['name'] ?? 'User',
//         };
//       }).toList();
//     });
//   }

//   // Get recent chats stream (all chat rooms for current admin)
//   Stream<List<Map<String, dynamic>>> getRecentChats() {
//     final adminEmail = getCurrentUserEmail();

//     return _firestore
//         .collection('chat_rooms')
//         .where('users', arrayContains: adminEmail)
//         .orderBy('lastMessageTimestamp', descending: true)
//         .snapshots()
//         .asyncMap((querySnapshot) async {
//       List<Map<String, dynamic>> chatRooms = [];

//       for (var doc in querySnapshot.docs) {
//         final data = doc.data();
//         final List<dynamic> users = data['users'];
//         // Get the other user's email (not the admin)
//         final String otherUserEmail =
//             users.firstWhere((email) => email != adminEmail, orElse: () => '');

//         if (otherUserEmail.isNotEmpty) {
//           // Get user information - MAKE SURE THIS COLLECTION NAME MATCHES WHERE YOUR USERS ARE STORED
//           final userSnapshot = await _firestore
//               .collection(
//                   'users') // This should match where your users are stored
//               .where('email', isEqualTo: otherUserEmail)
//               .limit(1)
//               .get();

//           String userName = 'User';
//           String userImage = '';

//           if (userSnapshot.docs.isNotEmpty) {
//             final userData = userSnapshot.docs.first.data();
//             userName = userData['name'] ?? 'User';
//             userImage = userData['imageUrl'] ?? '';
//           }

//           // Count unread messages
//           final unreadSnapshot = await _firestore
//               .collection('chat_rooms')
//               .doc(doc.id)
//               .collection('messages')
//               .where('receiverEmail', isEqualTo: adminEmail)
//               .where('isRead', isEqualTo: false)
//               .count()
//               .get();

//           chatRooms.add({
//             'roomId': doc.id,
//             'userEmail': otherUserEmail,
//             'userName': userName,
//             'userImage': userImage,
//             'lastMessage': data['lastMessage'] ?? '',
//             'lastMessageTimestamp': data['lastMessageTimestamp'],
//             'lastMessageSender': data['lastMessageSender'] ?? '',
//             'unreadCount': unreadSnapshot.count,
//           });
//         }
//       }

//       return chatRooms;
//     });
//   }

//   // Get chat ID
//   String getChatRoomId(String user1, String user2) {
//     // Sort emails to ensure consistent chat room IDs regardless of who initiates
//     List<String> ids = [user1, user2];
//     ids.sort();
//     return '${ids[0]}_${ids[1]}';
//   }

//   // Send message
//   Future<void> sendMessage(String receiverEmail, String message) async {
//     // Get current user info
//     final String currentUserEmail = getCurrentUserEmail();
//     final Timestamp timestamp = Timestamp.now();

//     // Create a new message
//     Map<String, dynamic> newMessage = {
//       'senderEmail': currentUserEmail,
//       'receiverEmail': receiverEmail,
//       'message': message,
//       'timestamp': timestamp,
//       'isRead': false
//     };

//     // Construct chat room ID
//     final chatRoomId = getChatRoomId(currentUserEmail, receiverEmail);

//     // Add the message to the database
//     await _firestore
//         .collection('chat_rooms')
//         .doc(chatRoomId)
//         .collection('messages')
//         .add(newMessage);

//     // Update the chat room info with last message
//     await _firestore.collection('chat_rooms').doc(chatRoomId).set({
//       'users': [currentUserEmail, receiverEmail],
//       'lastMessage': message,
//       'lastMessageTimestamp': timestamp,
//       'lastMessageSender': currentUserEmail
//     });
//   }

// // Add this to the admin-side ChatServices class
//   Future<void> debugUserStructure() async {
//     try {
//       // Check users collection
//       final usersCollection = await _firestore.collection('users').get();
//       print("Users collection count: ${usersCollection.docs.length}");
//       if (usersCollection.docs.isNotEmpty) {
//         print("Sample user data: ${usersCollection.docs.first.data()}");
//       }

//       // Check chat rooms
//       final chatRoomsCollection =
//           await _firestore.collection('chat_rooms').get();
//       print("Chat rooms count: ${chatRoomsCollection.docs.length}");
//       if (chatRoomsCollection.docs.isNotEmpty) {
//         print("Sample chat room: ${chatRoomsCollection.docs.first.data()}");

//         // Check messages in the first chat room
//         final messages = await _firestore
//             .collection('chat_rooms')
//             .doc(chatRoomsCollection.docs.first.id)
//             .collection('messages')
//             .get();
//         print("Messages in this room: ${messages.docs.length}");
//       }
//     } catch (e) {
//       print("Error debugging user structure: $e");
//     }
//   }

//   // Get messages
//   Stream<QuerySnapshot> getMessages(String otherUserEmail) {
//     final String currentUserEmail = getCurrentUserEmail();
//     final chatRoomId = getChatRoomId(currentUserEmail, otherUserEmail);

//     return _firestore
//         .collection('chat_rooms')
//         .doc(chatRoomId)
//         .collection('messages')
//         .orderBy('timestamp', descending: false)
//         .snapshots();
//   }

//   // Mark messages as read
//   Future<void> markMessagesAsRead(String otherUserEmail) async {
//     final String currentUserEmail = getCurrentUserEmail();
//     final chatRoomId = getChatRoomId(currentUserEmail, otherUserEmail);

//     final messagesSnapshot = await _firestore
//         .collection('chat_rooms')
//         .doc(chatRoomId)
//         .collection('messages')
//         .where('receiverEmail', isEqualTo: currentUserEmail)
//         .where('isRead', isEqualTo: false)
//         .get();

//     for (var doc in messagesSnapshot.docs) {
//       await doc.reference.update({'isRead': true});
//     }
//   }
// }

// // chat_list.dart (Admin side)

// class ChatList extends StatelessWidget {
//   ChatList({super.key});
//   final ChatServices _chatServices = ChatServices();
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Customer Chats"),
//         backgroundColor: Colors.pink[100],
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () {
//             Navigator.pushReplacement(
//                 context, MaterialPageRoute(builder: (context) => Homepage()));
//           },
//         ),
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Text(
//               "Recent Conversations",
//               style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.pink[800]),
//             ),
//           ),
//           Expanded(
//             child: _buildRecentChats(),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildRecentChats() {
//     return StreamBuilder(
//       stream: _chatServices.getRecentChats(),
//       builder: (context, snapshot) {
//         if (snapshot.hasError) {
//           return const Center(child: Text("Error loading conversations"));
//         }
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }
//         if (!snapshot.hasData || snapshot.data!.isEmpty) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(Icons.chat_bubble_outline,
//                     size: 64, color: Colors.grey[400]),
//                 const SizedBox(height: 16),
//                 const Text(
//                   "No conversations yet",
//                   style: TextStyle(
//                     fontSize: 16,
//                     color: Colors.grey,
//                   ),
//                 ),
//               ],
//             ),
//           );
//         }

//         return ListView.separated(
//           itemCount: snapshot.data!.length,
//           separatorBuilder: (context, index) => const Divider(height: 1),
//           itemBuilder: (context, index) {
//             final chatData = snapshot.data![index];
//             return _buildChatListItem(chatData, context);
//           },
//         );
//       },
//     );
//   }

//   Widget _buildChatListItem(
//       Map<String, dynamic> chatData, BuildContext context) {
//     final bool isUnread = chatData['unreadCount'] > 0;
//     final bool isFromUser =
//         chatData['lastMessageSender'] != _auth.currentUser!.email;

//     // Format timestamp
//     String formattedTime = '';
//     if (chatData['lastMessageTimestamp'] != null) {
//       DateTime messageTime =
//           (chatData['lastMessageTimestamp'] as Timestamp).toDate();

//       // If today, show time, otherwise show date
//       final now = DateTime.now();
//       if (messageTime.day == now.day &&
//           messageTime.month == now.month &&
//           messageTime.year == now.year) {
//         formattedTime = DateFormat.jm().format(messageTime);
//       } else {
//         formattedTime = DateFormat.MMMd().format(messageTime);
//       }
//     }

//     return ListTile(
//       leading: CircleAvatar(
//         backgroundColor: Colors.pink[200],
//         backgroundImage:
//             chatData['userImage'] != null && chatData['userImage'].isNotEmpty
//                 ? NetworkImage(chatData['userImage'])
//                 : null,
//         child: chatData['userImage'] == null || chatData['userImage'].isEmpty
//             ? Icon(Icons.person, color: Colors.white)
//             : null,
//       ),
//       title: Text(
//         chatData['userName'] ?? "User",
//         style: TextStyle(
//           fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
//         ),
//       ),
//       subtitle: Row(
//         children: [
//           if (isFromUser && isUnread)
//             Icon(Icons.circle, size: 8, color: Colors.pink[400]),
//           if (isFromUser && isUnread) const SizedBox(width: 4),
//           Expanded(
//             child: Text(
//               chatData['lastMessage'] ?? "",
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//               style: TextStyle(
//                 color: isUnread ? Colors.black87 : Colors.grey[600],
//                 fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
//               ),
//             ),
//           ),
//         ],
//       ),
//       trailing: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         crossAxisAlignment: CrossAxisAlignment.end,
//         children: [
//           Text(
//             formattedTime,
//             style: TextStyle(
//               fontSize: 12,
//               color: isUnread ? Colors.pink[400] : Colors.grey[500],
//             ),
//           ),
//           const SizedBox(height: 4),
//           if (isUnread)
//             Container(
//               padding: const EdgeInsets.all(6),
//               decoration: BoxDecoration(
//                 color: Colors.pink[400],
//                 shape: BoxShape.circle,
//               ),
//               child: Text(
//                 chatData['unreadCount'].toString(),
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 10,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//         ],
//       ),
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => ChatPage(
//               receiverEmail: chatData['userEmail'],
//               receiverName: chatData['userName'] ?? "User",
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

// // chat_page.dart (Admin side)

// class ChatPage extends StatefulWidget {
//   final String receiverEmail;
//   final String receiverName;

//   const ChatPage(
//       {Key? key, required this.receiverEmail, required this.receiverName})
//       : super(key: key);

//   @override
//   _ChatPageState createState() => _ChatPageState();
// }

// class _ChatPageState extends State<ChatPage> {
//   final TextEditingController _messageController = TextEditingController();
//   final ChatServices _chatServices = ChatServices();
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   @override
//   void initState() {
//     super.initState();
//     // Mark messages as read when opening chat
//     _chatServices.markMessagesAsRead(widget.receiverEmail);
//   }

//   void _sendMessage() async {
//     if (_messageController.text.trim().isNotEmpty) {
//       await _chatServices.sendMessage(
//         widget.receiverEmail,
//         _messageController.text.trim(),
//       );
//       _messageController.clear();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(widget.receiverName),
//             Text(
//               widget.receiverEmail,
//               style: const TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.normal,
//               ),
//             ),
//           ],
//         ),
//         backgroundColor: Colors.pink[100],
//       ),
//       body: Column(
//         children: [
//           // Messages area
//           Expanded(
//             child: _buildMessageList(),
//           ),
//           // Input area
//           _buildMessageInput(),
//         ],
//       ),
//     );
//   }

//   Widget _buildMessageList() {
//     return StreamBuilder(
//       stream: _chatServices.getMessages(widget.receiverEmail),
//       builder: (context, snapshot) {
//         if (snapshot.hasError) {
//           return const Center(child: Text("Error loading messages"));
//         }
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           return const Center(
//             child: Text(
//                 "No messages yet. Send a message to start the conversation!"),
//           );
//         }

//         return ListView(
//           padding: const EdgeInsets.all(10),
//           children:
//               snapshot.data!.docs.map((doc) => _buildMessageItem(doc)).toList(),
//         );
//       },
//     );
//   }

//   Widget _buildMessageItem(DocumentSnapshot document) {
//     Map<String, dynamic> data = document.data() as Map<String, dynamic>;
//     bool isCurrentUser = data['senderEmail'] == _auth.currentUser!.email;

//     // Format timestamp
//     String formattedTime = '';
//     if (data['timestamp'] != null) {
//       DateTime messageTime = (data['timestamp'] as Timestamp).toDate();
//       formattedTime = DateFormat.jm().format(messageTime);
//     }

//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Align(
//         alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
//         child: Container(
//           padding: const EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: isCurrentUser ? Colors.pink[100] : Colors.grey[200],
//             borderRadius: BorderRadius.circular(12),
//           ),
//           constraints: BoxConstraints(
//             maxWidth: MediaQuery.of(context).size.width * 0.7,
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 data['message'] ?? '',
//                 style: const TextStyle(fontSize: 16),
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 formattedTime,
//                 style: TextStyle(
//                   fontSize: 12,
//                   color: Colors.grey[600],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildMessageInput() {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       color: Colors.white,
//       child: Row(
//         children: [
//           // Text input
//           Expanded(
//             child: TextField(
//               controller: _messageController,
//               decoration: InputDecoration(
//                 hintText: "Type a message to ${widget.receiverName}...",
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(24),
//                   borderSide: BorderSide.none,
//                 ),
//                 filled: true,
//                 fillColor: Colors.grey[200],
//                 contentPadding: const EdgeInsets.symmetric(
//                   horizontal: 16,
//                   vertical: 12,
//                 ),
//               ),
//               textCapitalization: TextCapitalization.sentences,
//               maxLines: null,
//               keyboardType: TextInputType.multiline,
//             ),
//           ),
//           // Send button
//           const SizedBox(width: 8),
//           CircleAvatar(
//             backgroundColor: Colors.pink[300],
//             child: IconButton(
//               icon: const Icon(Icons.send, color: Colors.white),
//               onPressed: _sendMessage,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
