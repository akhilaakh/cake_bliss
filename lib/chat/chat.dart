// // // chat_services.dart (User side)
// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:flutter/material.dart';
// // import 'package:intl/intl.dart';

// // class ChatServices {
// //   // Get instance of firestore
// //   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
// //   final FirebaseAuth _auth = FirebaseAuth.instance;

// //   // // Get current user
// //   // String getCurrentUserEmail() {
// //   //   return _auth.currentUser!.email ?? '';
// //   // }
// //   String getCurrentUserEmail() {
// //     if (_auth.currentUser == null || _auth.currentUser!.email == null) {
// //       print("Warning: Current user or email is null");
// //       return '';
// //     }
// //     return _auth.currentUser!.email!;
// //   }

// //   // Get user stream (for displaying available chat users)
// //   Stream<List<Map<String, dynamic>>> getUserStream() {
// //     return _firestore.collection('admin').snapshots().map((snapshot) {
// //       return snapshot.docs.map((doc) {
// //         final data = doc.data();
// //         return {
// //           'uid': doc.id,
// //           'email': data['email'] ?? '',
// //           'name': data['name'] ?? 'Admin',
// //         };
// //       }).toList();
// //     });
// //   }

// //   // Get chat ID
// //   String getChatRoomId(String user1, String user2) {
// //     // Sort emails to ensure consistent chat room IDs regardless of who initiates
// //     List<String> ids = [user1, user2];
// //     ids.sort();
// //     return '${ids[0]}_${ids[1]}';
// //   }

// //   // Send message
// // // Update your sendMessage function in ChatServices
// //   Future<void> sendMessage(String receiverEmail, String message) async {
// //     try {
// //       // Get current user info
// //       final String currentUserEmail = getCurrentUserEmail();
// //       if (currentUserEmail.isEmpty) {
// //         throw Exception("User not logged in or email not available");
// //       }

// //       final Timestamp timestamp = Timestamp.now();

// //       // Create a new message
// //       Map<String, dynamic> newMessage = {
// //         'senderEmail': currentUserEmail,
// //         'receiverEmail': receiverEmail,
// //         'message': message,
// //         'timestamp': timestamp,
// //         'isRead': false
// //       };

// //       // Construct chat room ID
// //       final chatRoomId = getChatRoomId(currentUserEmail, receiverEmail);

// //       print("Sending message to room: $chatRoomId");

// //       // Add the message to the database
// //       await _firestore
// //           .collection('chat_rooms')
// //           .doc(chatRoomId)
// //           .collection('messages')
// //           .add(newMessage);

// //       // Update the chat room info with last message
// //       await _firestore.collection('chat_rooms').doc(chatRoomId).set({
// //         'users': [currentUserEmail, receiverEmail],
// //         'lastMessage': message,
// //         'lastMessageTimestamp': timestamp,
// //         'lastMessageSender': currentUserEmail
// //       });

// //       print("Message sent successfully");
// //     } catch (e) {
// //       print("Error in sendMessage: $e");
// //       throw e; // Re-throw to handle in UI
// //     }
// //   }

// //   // Get messages
// //   Stream<QuerySnapshot> getMessages(String otherUserEmail) {
// //     final String currentUserEmail = getCurrentUserEmail();
// //     final chatRoomId = getChatRoomId(currentUserEmail, otherUserEmail);

// //     return _firestore
// //         .collection('chat_rooms')
// //         .doc(chatRoomId)
// //         .collection('messages')
// //         .orderBy('timestamp', descending: false)
// //         .snapshots();
// //   }

// //   // Mark messages as read
// //   Future<void> markMessagesAsRead(String otherUserEmail) async {
// //     final String currentUserEmail = getCurrentUserEmail();
// //     final chatRoomId = getChatRoomId(currentUserEmail, otherUserEmail);

// //     final messagesSnapshot = await _firestore
// //         .collection('chat_rooms')
// //         .doc(chatRoomId)
// //         .collection('messages')
// //         .where('receiverEmail', isEqualTo: currentUserEmail)
// //         .where('isRead', isEqualTo: false)
// //         .get();

// //     for (var doc in messagesSnapshot.docs) {
// //       await doc.reference.update({'isRead': true});
// //     }
// //   }

// //   // Add this to the admin-side ChatServices class
// //   Future<void> debugUserStructure() async {
// //     try {
// //       // Check users collection
// //       final usersCollection = await _firestore.collection('users').get();
// //       print("Users collection count: ${usersCollection.docs.length}");
// //       if (usersCollection.docs.isNotEmpty) {
// //         print("Sample user data: ${usersCollection.docs.first.data()}");
// //       }

// //       // Check chat rooms
// //       final chatRoomsCollection =
// //           await _firestore.collection('chat_rooms').get();
// //       print("Chat rooms count: ${chatRoomsCollection.docs.length}");
// //       if (chatRoomsCollection.docs.isNotEmpty) {
// //         print("Sample chat room: ${chatRoomsCollection.docs.first.data()}");

// //         // Check messages in the first chat room
// //         final messages = await _firestore
// //             .collection('chat_rooms')
// //             .doc(chatRoomsCollection.docs.first.id)
// //             .collection('messages')
// //             .get();
// //         print("Messages in this room: ${messages.docs.length}");
// //       }
// //     } catch (e) {
// //       print("Error debugging user structure: $e");
// //     }
// //   }
// // }

// // // chat_list.dart (User side)

// // class ChatList extends StatelessWidget {
// //   ChatList({super.key});
// //   final ChatServices _chatServices = ChatServices();
// //   final FirebaseAuth _auth = FirebaseAuth.instance;

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text("Chat with Admin"),
// //         backgroundColor: Colors.pink[100],
// //       ),
// //       body: _buildUserList(),
// //     );
// //   }

// //   Widget _buildUserList() {
// //     return StreamBuilder(
// //       stream: _chatServices.getUserStream(),
// //       builder: (context, snapshot) {
// //         if (snapshot.hasError) {
// //           return const Center(child: Text("Error loading admins"));
// //         }
// //         if (snapshot.connectionState == ConnectionState.waiting) {
// //           return const Center(child: CircularProgressIndicator());
// //         }
// //         if (!snapshot.hasData || snapshot.data!.isEmpty) {
// //           return const Center(child: Text("No admins available"));
// //         }

// //         return ListView(
// //           children: snapshot.data!
// //               .map<Widget>((userData) => _buildUserListItem(userData, context))
// //               .toList(),
// //         );
// //       },
// //     );
// //   }

// //   Widget _buildUserListItem(
// //       Map<String, dynamic> userData, BuildContext context) {
// //     // Only show admins that aren't the current user
// //     if (_auth.currentUser?.email != userData["email"]) {
// //       return ListTile(
// //         leading: CircleAvatar(
// //           backgroundColor: Colors.pink[200],
// //           child: Icon(Icons.person, color: Colors.white),
// //         ),
// //         title: Text(userData["name"] ?? "Admin"),
// //         subtitle: Text(userData["email"]),
// //         onTap: () {
// //           Navigator.push(
// //             context,
// //             MaterialPageRoute(
// //               builder: (context) => ChatPage(
// //                 receiverEmail: userData["email"],
// //                 receiverName: userData["name"] ?? "Admin",
// //               ),
// //             ),
// //           );
// //         },
// //       );
// //     }
// //     return const SizedBox.shrink();
// //   }
// // }

// // // chat_page.dart (User side)

// // class ChatPage extends StatefulWidget {
// //   final String receiverEmail;
// //   final String receiverName;

// //   const ChatPage(
// //       {Key? key, required this.receiverEmail, required this.receiverName})
// //       : super(key: key);

// //   @override
// //   _ChatPageState createState() => _ChatPageState();
// // }

// // class _ChatPageState extends State<ChatPage> {
// //   final TextEditingController _messageController = TextEditingController();
// //   final ChatServices _chatServices = ChatServices();
// //   final FirebaseAuth _auth = FirebaseAuth.instance;

// //   @override
// //   void initState() {
// //     super.initState();
// //     // Mark messages as read when opening chat
// //     _chatServices.markMessagesAsRead(widget.receiverEmail);
// //   }

// //   void _sendMessage() async {
// //     if (_messageController.text.trim().isNotEmpty) {
// //       try {
// //         await _chatServices.sendMessage(
// //           widget.receiverEmail,
// //           _messageController.text.trim(),
// //         );
// //         _messageController.clear();
// //       } catch (e) {
// //         print("Error sending message: $e");
// //         // Show error to user
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(content: Text("Failed to send message: $e")),
// //         );
// //       }
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text(widget.receiverName),
// //         backgroundColor: Colors.pink[100],
// //       ),
// //       body: Column(
// //         children: [
// //           // Messages area
// //           Expanded(
// //             child: _buildMessageList(),
// //           ),
// //           // Input area
// //           _buildMessageInput(),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildMessageList() {
// //     return StreamBuilder(
// //       stream: _chatServices.getMessages(widget.receiverEmail),
// //       builder: (context, snapshot) {
// //         if (snapshot.hasError) {
// //           return const Center(child: Text("Error loading messages"));
// //         }
// //         if (snapshot.connectionState == ConnectionState.waiting) {
// //           return const Center(child: CircularProgressIndicator());
// //         }

// //         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
// //           return const Center(
// //             child: Text("Start a conversation!"),
// //           );
// //         }

// //         return ListView(
// //           padding: const EdgeInsets.all(10),
// //           children:
// //               snapshot.data!.docs.map((doc) => _buildMessageItem(doc)).toList(),
// //         );
// //       },
// //     );
// //   }

// //   Widget _buildMessageItem(DocumentSnapshot document) {
// //     Map<String, dynamic> data = document.data() as Map<String, dynamic>;
// //     bool isCurrentUser = data['senderEmail'] == _auth.currentUser!.email;

// //     // Format timestamp
// //     String formattedTime = '';
// //     if (data['timestamp'] != null) {
// //       DateTime messageTime = (data['timestamp'] as Timestamp).toDate();
// //       formattedTime = DateFormat.jm().format(messageTime);
// //     }

// //     return Padding(
// //       padding: const EdgeInsets.symmetric(vertical: 4),
// //       child: Align(
// //         alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
// //         child: Container(
// //           padding: const EdgeInsets.all(12),
// //           decoration: BoxDecoration(
// //             color: isCurrentUser ? Colors.pink[100] : Colors.grey[200],
// //             borderRadius: BorderRadius.circular(12),
// //           ),
// //           constraints: BoxConstraints(
// //             maxWidth: MediaQuery.of(context).size.width * 0.7,
// //           ),
// //           child: Column(
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             children: [
// //               Text(
// //                 data['message'] ?? '',
// //                 style: const TextStyle(fontSize: 16),
// //               ),
// //               const SizedBox(height: 4),
// //               Text(
// //                 formattedTime,
// //                 style: TextStyle(
// //                   fontSize: 12,
// //                   color: Colors.grey[600],
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildMessageInput() {
// //     return Container(
// //       padding: const EdgeInsets.all(12),
// //       color: Colors.white,
// //       child: Row(
// //         children: [
// //           // Text input
// //           Expanded(
// //             child: TextField(
// //               controller: _messageController,
// //               decoration: InputDecoration(
// //                 hintText: "Type a message...",
// //                 border: OutlineInputBorder(
// //                   borderRadius: BorderRadius.circular(24),
// //                   borderSide: BorderSide.none,
// //                 ),
// //                 filled: true,
// //                 fillColor: Colors.grey[200],
// //                 contentPadding: const EdgeInsets.symmetric(
// //                   horizontal: 16,
// //                   vertical: 12,
// //                 ),
// //               ),
// //               textCapitalization: TextCapitalization.sentences,
// //             ),
// //           ),
// //           // Send button
// //           const SizedBox(width: 8),
// //           CircleAvatar(
// //             backgroundColor: Colors.pink[300],
// //             child: IconButton(
// //               icon: const Icon(Icons.send, color: Colors.white),
// //               onPressed: _sendMessage,
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// // // Create a widget for displaying chat bubble
// // class MessageBubble extends StatelessWidget {
// //   final String message;
// //   final bool isCurrentUser;
// //   final String time;

// //   const MessageBubble({
// //     Key? key,
// //     required this.message,
// //     required this.isCurrentUser,
// //     required this.time,
// //   }) : super(key: key);

// //   @override
// //   Widget build(BuildContext context) {
// //     return Align(
// //       alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
// //       child: Container(
// //         margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
// //         padding: const EdgeInsets.all(12),
// //         decoration: BoxDecoration(
// //           color: isCurrentUser ? Colors.pink[100] : Colors.grey[200],
// //           borderRadius: BorderRadius.circular(12),
// //         ),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             Text(message, style: const TextStyle(fontSize: 16)),
// //             const SizedBox(height: 4),
// //             Text(
// //               time,
// //               style: TextStyle(fontSize: 12, color: Colors.grey[600]),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }

// // chat_services.dart (User side)
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';

// class ChatServices {
//   // Get instance of firestore
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   // Get current user email
//   String getCurrentUserEmail() {
//     if (_auth.currentUser == null || _auth.currentUser!.email == null) {
//       print("Warning: Current user or email is null");
//       return '';
//     }
//     return _auth.currentUser!.email!;
//   }

//   // Get admin stream (for displaying available admins to chat with)
//   Stream<List<Map<String, dynamic>>> getAdminStream() {
//     return _firestore.collection('admin').snapshots().map((snapshot) {
//       return snapshot.docs.map((doc) {
//         final data = doc.data();
//         return {
//           'uid': doc.id,
//           'email': data['email'] ?? '',
//           'name': data['name'] ?? 'Admin',
//         };
//       }).toList();
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
//   Future<void> sendMessage(String adminEmail, String message) async {
//     try {
//       // Get current user info
//       final String currentUserEmail = getCurrentUserEmail();
//       if (currentUserEmail.isEmpty) {
//         throw Exception("User not logged in or email not available");
//       }

//       final Timestamp timestamp = Timestamp.now();

//       // Create a new message
//       Map<String, dynamic> newMessage = {
//         'senderEmail': currentUserEmail,
//         'receiverEmail': adminEmail,
//         'message': message,
//         'timestamp': timestamp,
//         'isRead': false
//       };

//       // Construct chat room ID
//       final chatRoomId = getChatRoomId(currentUserEmail, adminEmail);

//       print("Sending message to room: $chatRoomId");

//       // Add the message to the database
//       await _firestore
//           .collection('chat_rooms')
//           .doc(chatRoomId)
//           .collection('messages')
//           .add(newMessage);

//       // Update the chat room info with last message
//       await _firestore.collection('chat_rooms').doc(chatRoomId).set({
//         'users': [currentUserEmail, adminEmail],
//         'lastMessage': message,
//         'lastMessageTimestamp': timestamp,
//         'lastMessageSender': currentUserEmail
//       });

//       print("Message sent successfully");
//     } catch (e) {
//       print("Error in sendMessage: $e");
//       throw e; // Re-throw to handle in UI
//     }
//   }

//   // Get messages
//   Stream<QuerySnapshot> getMessages(String adminEmail) {
//     final String currentUserEmail = getCurrentUserEmail();
//     final chatRoomId = getChatRoomId(currentUserEmail, adminEmail);

//     return _firestore
//         .collection('chat_rooms')
//         .doc(chatRoomId)
//         .collection('messages')
//         .orderBy('timestamp', descending: false)
//         .snapshots();
//   }

//   // Mark messages as read
//   Future<void> markMessagesAsRead(String adminEmail) async {
//     final String currentUserEmail = getCurrentUserEmail();
//     final chatRoomId = getChatRoomId(currentUserEmail, adminEmail);

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

//   // Get most recent chat with admin, if any
//   Future<Map<String, dynamic>?> getMostRecentAdminChat() async {
//     final currentUserEmail = getCurrentUserEmail();

//     try {
//       // Get chat rooms where this user is a participant
//       final chatRooms = await _firestore
//           .collection('chat_rooms')
//           .where('users', arrayContains: currentUserEmail)
//           .orderBy('lastMessageTimestamp', descending: true)
//           .limit(1)
//           .get();

//       if (chatRooms.docs.isEmpty) {
//         return null;
//       }

//       final chatRoomData = chatRooms.docs.first.data();
//       final List<dynamic> users = chatRoomData['users'];

//       // Get the admin email (the other user in the chat)
//       final String adminEmail = users.firstWhere(
//         (email) => email != currentUserEmail,
//         orElse: () => ''
//       );

//       if (adminEmail.isEmpty) {
//         return null;
//       }

//       // Get admin info
//       final adminSnapshot = await _firestore
//           .collection('admin')
//           .where('email', isEqualTo: adminEmail)
//           .limit(1)
//           .get();

//       if (adminSnapshot.docs.isEmpty) {
//         return null;
//       }

//       final adminData = adminSnapshot.docs.first.data();

//       return {
//         'adminEmail': adminEmail,
//         'adminName': adminData['name'] ?? 'Admin',
//         'lastMessage': chatRoomData['lastMessage'],
//         'timestamp': chatRoomData['lastMessageTimestamp'],
//       };
//     } catch (e) {
//       print("Error getting recent admin chat: $e");
//       return null;
//     }
//   }
// }

// // chat_list.dart (User side)
// class ChatList extends StatelessWidget {
//   ChatList({Key? key}) : super(key: key);
//   final ChatServices _chatServices = ChatServices();
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Contact Support"),
//         backgroundColor: Colors.pink[100],
//       ),
//       body: Column(
//         children: [
//           // Recent chat section (if any)
//           _buildRecentChat(),

//           // Divider
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             child: Row(
//               children: [
//                 Expanded(child: Divider()),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 16),
//                   child: Text(
//                     "Available Admins",
//                     style: TextStyle(
//                       color: Colors.grey[600],
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ),
//                 Expanded(child: Divider()),
//               ],
//             ),
//           ),

//           // Admin list
//           Expanded(
//             child: _buildAdminList(),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildRecentChat() {
//     return FutureBuilder<Map<String, dynamic>?>(
//       future: _chatServices.getMostRecentAdminChat(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const SizedBox(
//             height: 100,
//             child: Center(child: CircularProgressIndicator()),
//           );
//         }

//         if (!snapshot.hasData || snapshot.data == null) {
//           return const SizedBox(height: 0);
//         }

//         final recentChat = snapshot.data!;
//         String timeAgo = '';

//         if (recentChat['timestamp'] != null) {
//           final DateTime messageTime = (recentChat['timestamp'] as Timestamp).toDate();
//           final now = DateTime.now();
//           final difference = now.difference(messageTime);

//           if (difference.inMinutes < 1) {
//             timeAgo = 'Just now';
//           } else if (difference.inHours < 1) {
//             timeAgo = '${difference.inMinutes}m ago';
//           } else if (difference.inDays < 1) {
//             timeAgo = '${difference.inHours}h ago';
//           } else if (difference.inDays < 7) {
//             timeAgo = '${difference.inDays}d ago';
//           } else {
//             timeAgo = DateFormat.MMMd().format(messageTime);
//           }
//         }

//         return Card(
//           margin: const EdgeInsets.all(16),
//           elevation: 2,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   "Recent Conversation",
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 16,
//                     color: Colors.pink[800],
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 ListTile(
//                   contentPadding: EdgeInsets.zero,
//                   leading: CircleAvatar(
//                     backgroundColor: Colors.pink[200],
//                     child: Icon(Icons.support_agent, color: Colors.white),
//                   ),
//                   title: Text(recentChat['adminName'] ?? 'Admin'),
//                   subtitle: Row(
//                     children: [
//                       Expanded(
//                         child: Text(
//                           recentChat['lastMessage'] ?? '',
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                       Text(
//                         timeAgo,
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                     ],
//                   ),
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => ChatPage(
//                           receiverEmail: recentChat['adminEmail'],
//                           receiverName: recentChat['adminName'] ?? 'Admin',
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildAdminList() {
//     return StreamBuilder(
//       stream: _chatServices.getAdminStream(),
//       builder: (context, snapshot) {
//         if (snapshot.hasError) {
//           return Center(child: Text("Error loading admins: ${snapshot.error}"));
//         }
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }
//         if (!snapshot.hasData || snapshot.data!.isEmpty) {
//           return const Center(child: Text("No support staff available"));
//         }

//         return ListView(
//           children: snapshot.data!
//               .map<Widget>((adminData) => _buildAdminListItem(adminData, context))
//               .toList(),
//         );
//       },
//     );
//   }

//   Widget _buildAdminListItem(
//       Map<String, dynamic> adminData, BuildContext context) {
//     // Only show admins that aren't the current user
//     if (_auth.currentUser?.email != adminData["email"]) {
//       return ListTile(
//         leading: CircleAvatar(
//           backgroundColor: Colors.pink[200],
//           child: Icon(Icons.support_agent, color: Colors.white),
//         ),
//         title: Text(adminData["name"] ?? "Admin"),
//         subtitle: Text(adminData["email"]),
//         trailing: Icon(Icons.chat_bubble_outline, color: Colors.pink[300]),
//         onTap: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => ChatPage(
//                 receiverEmail: adminData["email"],
//                 receiverName: adminData["name"] ?? "Admin",
//               ),
//             ),
//           );
//         },
//       );
//     }
//     return const SizedBox.shrink();
//   }
// }

// // chat_page.dart (User side)
// class ChatPage extends StatefulWidget {
//   final String receiverEmail;
//   final String receiverName;

//   const ChatPage({
//     Key? key,
//     required this.receiverEmail,
//     required this

// chat_services.dart (User side)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserChatServices {
  // Get instance of firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user email
  String getCurrentUserEmail() {
    if (_auth.currentUser == null || _auth.currentUser!.email == null) {
      print("Warning: Current user or email is null");
      return '';
    }
    return _auth.currentUser!.email!;
  }

  // Get admin stream (for displaying available admins to chat with)
  Stream<List<Map<String, dynamic>>> getAdminStream() {
    return _firestore.collection('admin').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'uid': doc.id,
          'email': data['email'] ?? '',
          'name': data['name'] ?? 'Admin',
        };
      }).toList();
    });
  }

  // Get chat room ID
  String getChatRoomId(String user, String admin) {
    // Sort emails to ensure consistent chat room IDs regardless of who initiates
    List<String> ids = [user, admin];
    ids.sort();
    return '${ids[0]}_${ids[1]}';
  }

  // Send message to admin
  Future<void> sendMessage(String adminEmail, String message) async {
    try {
      // Get current user info
      final String userEmail = getCurrentUserEmail();
      if (userEmail.isEmpty) {
        throw Exception("User not logged in or email not available");
      }

      final Timestamp timestamp = Timestamp.now();

      // Create a new message
      Map<String, dynamic> newMessage = {
        'senderEmail': userEmail,
        'receiverEmail': adminEmail,
        'message': message,
        'timestamp': timestamp,
        'isRead': false
      };

      // Construct chat room ID
      final chatRoomId = getChatRoomId(userEmail, adminEmail);

      // Add the message to the database
      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .add(newMessage);

      // Update the chat room info with last message
      await _firestore.collection('chat_rooms').doc(chatRoomId).set({
        'users': [userEmail, adminEmail],
        'lastMessage': message,
        'lastMessageTimestamp': timestamp,
        'lastMessageSender': userEmail
      });
    } catch (e) {
      print("Error in sendMessage: $e");
      throw e; // Re-throw to handle in UI
    }
  }

  // Get messages with admin
  Stream<QuerySnapshot> getMessagesWithAdmin(String adminEmail) {
    final String userEmail = getCurrentUserEmail();
    final chatRoomId = getChatRoomId(userEmail, adminEmail);

    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String adminEmail) async {
    final String userEmail = getCurrentUserEmail();
    final chatRoomId = getChatRoomId(userEmail, adminEmail);

    final messagesSnapshot = await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .where('receiverEmail', isEqualTo: userEmail)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in messagesSnapshot.docs) {
      await doc.reference.update({'isRead': true});
    }
  }

  // Check if user has any existing chats with admins
  Future<String?> getExistingAdminChat() async {
    try {
      final String userEmail = getCurrentUserEmail();
      if (userEmail.isEmpty) return null;

      final chatsSnapshot = await _firestore
          .collection('chat_rooms')
          .where('users', arrayContains: userEmail)
          .orderBy('lastMessageTimestamp', descending: true)
          .limit(1)
          .get();

      if (chatsSnapshot.docs.isNotEmpty) {
        final data = chatsSnapshot.docs.first.data();
        final List<dynamic> users = data['users'];

        // Get the admin email (not the current user)
        final String adminEmail =
            users.firstWhere((email) => email != userEmail, orElse: () => '');

        if (adminEmail.isNotEmpty) {
          // Get admin info
          final adminSnapshot = await _firestore
              .collection('admin')
              .where('email', isEqualTo: adminEmail)
              .limit(1)
              .get();

          if (adminSnapshot.docs.isNotEmpty) {
            final adminData = adminSnapshot.docs.first.data();
            return adminEmail;
          }
        }
      }
      return null;
    } catch (e) {
      print("Error checking existing chats: $e");
      return null;
    }
  }
}

// user_chat_list.dart

class UserChatList extends StatefulWidget {
  const UserChatList({Key? key}) : super(key: key);

  @override
  _UserChatListState createState() => _UserChatListState();
}

class _UserChatListState extends State<UserChatList> {
  final UserChatServices _chatServices = UserChatServices();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  String? _existingAdminEmail;

  @override
  void initState() {
    super.initState();
    _checkExistingChats();
  }

  Future<void> _checkExistingChats() async {
    try {
      final adminEmail = await _chatServices.getExistingAdminChat();
      setState(() {
        _existingAdminEmail = adminEmail;
        _isLoading = false;
      });

      // If user already has a chat, navigate to it directly
      if (_existingAdminEmail != null) {
        _openExistingChat();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading chats: $e")),
      );
    }
  }

  void _openExistingChat() {
    if (_existingAdminEmail != null) {
      // Get admin name from database first
      _chatServices.getAdminStream().first.then((admins) {
        final adminInfo = admins.firstWhere(
            (admin) => admin['email'] == _existingAdminEmail,
            orElse: () => {'name': 'Admin', 'email': _existingAdminEmail!});

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => UserChatPage(
              adminEmail: _existingAdminEmail!,
              adminName: adminInfo['name'] ?? 'Admin',
            ),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Chat with Support"),
          backgroundColor: Colors.pink[100],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat with Support"),
        backgroundColor: Colors.pink[100],
      ),
      body: _buildAdminList(),
    );
  }

  Widget _buildAdminList() {
    return StreamBuilder(
      stream: _chatServices.getAdminStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text("Error: ${snapshot.error}"),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text("Retry"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink[300],
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.support_agent, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  "No support agents available",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Center(
              child: Text(
                "Select a support agent to chat with",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...snapshot.data!
                .map<Widget>((adminData) => _buildAdminListItem(adminData))
                .toList(),
          ],
        );
      },
    );
  }

  Widget _buildAdminListItem(Map<String, dynamic> adminData) {
    // Only show admins that aren't the current user
    if (_auth.currentUser?.email != adminData["email"]) {
      return Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.pink[200],
            child: const Icon(Icons.support_agent, color: Colors.white),
          ),
          title: Text(adminData["name"] ?? "Support Agent"),
          subtitle: Text(adminData["email"]),
          trailing: const Icon(Icons.chat_bubble_outline),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserChatPage(
                  adminEmail: adminData["email"],
                  adminName: adminData["name"] ?? "Support Agent",
                ),
              ),
            );
          },
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

// user_chat_page.dart
class UserChatPage extends StatefulWidget {
  final String adminEmail;
  final String adminName;

  const UserChatPage(
      {Key? key, required this.adminEmail, required this.adminName})
      : super(key: key);

  @override
  _UserChatPageState createState() => _UserChatPageState();
}

class _UserChatPageState extends State<UserChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final UserChatServices _chatServices = UserChatServices();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    // Mark messages as read when opening chat
    _chatServices.markMessagesAsRead(widget.adminEmail);
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isNotEmpty) {
      try {
        await _chatServices.sendMessage(
          widget.adminEmail,
          _messageController.text.trim(),
        );
        _messageController.clear();
      } catch (e) {
        print("Error sending message: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to send message: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.adminName),
            Text(
              "Support Agent",
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.pink[100],
      ),
      body: Column(
        children: [
          // Messages area
          Expanded(
            child: _buildMessageList(),
          ),
          // Input area
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder(
      stream: _chatServices.getMessagesWithAdmin(widget.adminEmail),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Error loading messages: ${snapshot.error}",
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat, size: 64, color: Colors.pink[100]),
                  const SizedBox(height: 16),
                  const Text(
                    "Send a message to start chatting with support",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Build message list
        return ListView(
          padding: const EdgeInsets.all(16),
          reverse: true,
          children: snapshot.data!.docs.reversed.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final isMe = data['senderEmail'] == _auth.currentUser?.email;

            return _buildMessageBubble(
              message: data['message'],
              isMe: isMe,
              timestamp: data['timestamp'],
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildMessageBubble({
    required String message,
    required bool isMe,
    required Timestamp timestamp,
  }) {
    final time = DateFormat('h:mm a').format(timestamp.toDate());

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isMe ? Colors.pink[200] : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft:
                isMe ? const Radius.circular(16) : const Radius.circular(0),
            bottomRight:
                isMe ? const Radius.circular(0) : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.black54,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: "Type a message...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.pink[300],
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
