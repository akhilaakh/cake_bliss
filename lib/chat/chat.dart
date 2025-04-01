// //new one.

// // chat_services.dart (Admin side)
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';

// class ChatServices {
//   // Get instance of firestore
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   // Get current admin email
//   String getCurrentAdminEmail() {
//     if (_auth.currentUser == null || _auth.currentUser!.email == null) {
//       print("Warning: Current admin user or email is null");
//       return '';
//     }
//     return _auth.currentUser!.email!;
//   }

//   // Get recent chats stream (all chat rooms for current admin)
//   Stream<List<Map<String, dynamic>>> getRecentChats() {
//     final adminEmail = getCurrentAdminEmail();

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
//           // Get user information
//           final userSnapshot = await _firestore
//               .collection('users')
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
//     try {
//       // Get current user info
//       final String currentAdminEmail = getCurrentAdminEmail();
//       if (currentAdminEmail.isEmpty) {
//         throw Exception("Admin not logged in or email not available");
//       }

//       final Timestamp timestamp = Timestamp.now();

//       // Create a new message
//       Map<String, dynamic> newMessage = {
//         'senderEmail': currentAdminEmail,
//         'receiverEmail': receiverEmail,
//         'message': message,
//         'timestamp': timestamp,
//         'isRead': false
//       };

//       // Construct chat room ID
//       final chatRoomId = getChatRoomId(currentAdminEmail, receiverEmail);

//       // Add the message to the database
//       await _firestore
//           .collection('chat_rooms')
//           .doc(chatRoomId)
//           .collection('messages')
//           .add(newMessage);

//       // Update the chat room info with last message
//       await _firestore.collection('chat_rooms').doc(chatRoomId).set({
//         'users': [currentAdminEmail, receiverEmail],
//         'lastMessage': message,
//         'lastMessageTimestamp': timestamp,
//         'lastMessageSender': currentAdminEmail
//       });
//     } catch (e) {
//       print("Error in sendMessage: $e");
//       throw e; // Re-throw to handle in UI
//     }
//   }

//   // Get messages
//   Stream<QuerySnapshot> getMessages(String userEmail) {
//     final String currentAdminEmail = getCurrentAdminEmail();
//     final chatRoomId = getChatRoomId(currentAdminEmail, userEmail);

//     return _firestore
//         .collection('chat_rooms')
//         .doc(chatRoomId)
//         .collection('messages')
//         .orderBy('timestamp', descending: false)
//         .snapshots();
//   }

//   // Mark messages as read
//   Future<void> markMessagesAsRead(String userEmail) async {
//     final String currentAdminEmail = getCurrentAdminEmail();
//     final chatRoomId = getChatRoomId(currentAdminEmail, userEmail);

//     final messagesSnapshot = await _firestore
//         .collection('chat_rooms')
//         .doc(chatRoomId)
//         .collection('messages')
//         .where('receiverEmail', isEqualTo: currentAdminEmail)
//         .where('isRead', isEqualTo: false)
//         .get();

//     for (var doc in messagesSnapshot.docs) {
//       await doc.reference.update({'isRead': true});
//     }
//   }
// }

// // chat_list.dart (Admin side)
// class ChatList extends StatelessWidget {
//   ChatList({Key? key}) : super(key: key);
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
//               "Customer Conversations",
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
//           return Center(child: Text("Error loading conversations: ${snapshot.error}"));
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
//                   "No customer messages yet",
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

//   const ChatPage({
//     Key? key,
//     required this.receiverEmail,
//     required this.receiverName
//   }) : super(key: key);

//   @override
//   _ChatPageState createState() => _ChatPageState();
// }

// class _ChatPageState extends State<ChatPage> {
//   final TextEditingController _messageController = TextEditingController();
//   final ChatServices _chatServices = ChatServices();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   bool _isSending = false;

//   @override
//   void initState() {
//     super.initState();
//     // Mark messages as read when opening chat
//     _chatServices.markMessagesAsRead(widget.receiverEmail);
//   }

//   void _sendMessage() async {
//     if (_messageController.text.trim().isNotEmpty) {
//       setState(() {
//         _isSending = true;
//       });

//       try {
//         await _chatServices.sendMessage(
//           widget.receiverEmail,
//           _messageController.text.trim(),
//         );
//         _messageController.clear();
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Failed to send message: $e")),
//         );
//       } finally {
//         setState(() {
//           _isSending = false;
//         });
//       }
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
//           return Center(child: Text("Error loading messages: ${snapshot.error}"));
//         }
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(child: CircularProgressIndicator());
//         }

//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(Icons.chat_bubble_outline,
//                      size: 64,
//                      color: Colors.grey[400]),
//                 const SizedBox(height: 16),
//                 const Text(
//                   "No messages yet. Start the conversation!",
//                   style: TextStyle(
//                     fontSize: 16,
//                     color: Colors.grey,
//                   ),
//                 ),
//               ],
//             ),
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
//               enabled: !_isSending,
//             ),
//           ),
//           // Send button
//           const SizedBox(width: 8),
//           CircleAvatar(
//             backgroundColor: Colors.pink[300],
//             child: _isSending
//                 ? SizedBox(
//                     width: 20,
//                     height: 20,
//                     child: CircularProgressIndicator(
//                       color: Colors.white,
//                       strokeWidth: 2,
//                     ),
//                   )
//                 : IconButton(
//                     icon: const Icon(Icons.send, color: Colors.white),
//                     onPressed: _sendMessage,
//                   ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// chat_services.dart (Admin side)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Your user model for reference
class UserModel {
  final String id;
  final String name;
  final String address;
  final String email;
  final String password;
  final String phone;
  final String? imageUrl;

  UserModel({
    required this.id,
    required this.name,
    required this.address,
    required this.email,
    required this.password,
    required this.phone,
    this.imageUrl,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      phone: map['phone'] ?? '',
      imageUrl: map['imageUrl'],
    );
  }
}

// Service class for admin chat functionality
class AdminChatServices {
  // Get instance of firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current admin email
  String getCurrentAdminEmail() {
    return _auth.currentUser?.email ?? '';
  }

  // Get users who have conversations with this admin or all users
  Stream<List<Map<String, dynamic>>> getUsersWithChats() {
    final adminEmail = getCurrentAdminEmail();

    return _firestore
        .collection('chat_rooms')
        .where('users', arrayContains: adminEmail)
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots()
        .asyncMap((querySnapshot) async {
      List<Map<String, dynamic>> userChats = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final List<dynamic> users = data['users'];

        // Get the user's email (not the admin)
        final String userEmail =
            users.firstWhere((email) => email != adminEmail, orElse: () => '');

        if (userEmail.isNotEmpty) {
          // Get user information
          final userSnapshot = await _firestore
              .collection('users')
              .where('email', isEqualTo: userEmail)
              .limit(1)
              .get();

          String userName = 'User';
          String userImage = '';
          String userId = '';

          if (userSnapshot.docs.isNotEmpty) {
            userId = userSnapshot.docs.first.id;
            final userData = userSnapshot.docs.first.data();
            userName = userData['name'] ?? 'User';
            userImage = userData['imageUrl'] ?? '';
          }

          // Count unread messages
          final unreadSnapshot = await _firestore
              .collection('chat_rooms')
              .doc(doc.id)
              .collection('messages')
              .where('receiverEmail', isEqualTo: adminEmail)
              .where('isRead', isEqualTo: false)
              .count()
              .get();

          userChats.add({
            'roomId': doc.id,
            'userEmail': userEmail,
            'userId': userId,
            'userName': userName,
            'userImage': userImage,
            'lastMessage': data['lastMessage'] ?? '',
            'lastMessageTimestamp': data['lastMessageTimestamp'],
            'lastMessageSender': data['lastMessageSender'] ?? '',
            'unreadCount': unreadSnapshot.count,
          });
        }
      }

      return userChats;
    });
  }

  // Get chat room ID
  String getChatRoomId(String admin, String user) {
    // Sort emails to ensure consistent chat room IDs regardless of who initiates
    List<String> ids = [admin, user];
    ids.sort();
    return '${ids[0]}_${ids[1]}';
  }

  // Send message to user
  Future<void> sendMessage(String userEmail, String message) async {
    // Get current admin info
    final String adminEmail = getCurrentAdminEmail();
    final Timestamp timestamp = Timestamp.now();

    // Create a new message
    Map<String, dynamic> newMessage = {
      'senderEmail': adminEmail,
      'receiverEmail': userEmail,
      'message': message,
      'timestamp': timestamp,
      'isRead': false
    };

    // Construct chat room ID
    final chatRoomId = getChatRoomId(adminEmail, userEmail);

    // Add the message to the database
    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add(newMessage);

    // Update the chat room info with last message
    await _firestore.collection('chat_rooms').doc(chatRoomId).set({
      'users': [adminEmail, userEmail],
      'lastMessage': message,
      'lastMessageTimestamp': timestamp,
      'lastMessageSender': adminEmail
    }, SetOptions(merge: true));
  }

  // Get messages with a specific user
  Stream<QuerySnapshot> getMessagesWithUser(String userEmail) {
    final String adminEmail = getCurrentAdminEmail();
    final chatRoomId = getChatRoomId(adminEmail, userEmail);

    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String userEmail) async {
    final String adminEmail = getCurrentAdminEmail();
    final chatRoomId = getChatRoomId(adminEmail, userEmail);

    final messagesSnapshot = await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .where('receiverEmail', isEqualTo: adminEmail)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in messagesSnapshot.docs) {
      await doc.reference.update({'isRead': true});
    }
  }

  // Get all users who might not have started a chat yet
  Stream<List<UserModel>> getAllUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }
}

// Admin Dashboard - Entry point for admin features
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: Colors.pink[100],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Admin welcome section
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.pink[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome, Admin",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Manage customer conversations and support",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.pink[600],
                  ),
                ),
              ],
            ),
          ),
          // Admin menu options
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(16),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildMenuCard(
                  context,
                  "Customer Chats",
                  Icons.chat,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminChatList(),
                      ),
                    );
                  },
                ),
                _buildMenuCard(
                  context,
                  "All Users",
                  Icons.people,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminUserList(),
                      ),
                    );
                  },
                ),
                // Add more menu items as needed
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: Colors.pink[400],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink[800],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Admin Chat List - Shows all users with active conversations
class AdminChatList extends StatelessWidget {
  AdminChatList({Key? key}) : super(key: key);

  final AdminChatServices _chatServices = AdminChatServices();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Customer Chats"),
        backgroundColor: Colors.pink[100],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Customer Conversations",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink[800]),
            ),
          ),
          Expanded(
            child: _buildUserList(),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder(
      stream: _chatServices.getUsersWithChats(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
              child: Text("Error loading conversations: ${snapshot.error}"));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline,
                    size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  "No customer conversations yet",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminUserList(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink[300],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text("View All Users"),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: snapshot.data!.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final chatData = snapshot.data![index];
            return _buildUserListItem(chatData, context);
          },
        );
      },
    );
  }

  Widget _buildUserListItem(
      Map<String, dynamic> userData, BuildContext context) {
    final bool isUnread = userData['unreadCount'] > 0;
    final bool isFromUser =
        userData['lastMessageSender'] != _auth.currentUser!.email;

    // Format timestamp
    String formattedTime = '';
    if (userData['lastMessageTimestamp'] != null) {
      DateTime messageTime =
          (userData['lastMessageTimestamp'] as Timestamp).toDate();

      // If today, show time, otherwise show date
      final now = DateTime.now();
      if (messageTime.day == now.day &&
          messageTime.month == now.month &&
          messageTime.year == now.year) {
        formattedTime = DateFormat.jm().format(messageTime);
      } else {
        formattedTime = DateFormat.MMMd().format(messageTime);
      }
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.pink[200],
        backgroundImage:
            userData['userImage'] != null && userData['userImage'].isNotEmpty
                ? NetworkImage(userData['userImage'])
                : null,
        child: userData['userImage'] == null || userData['userImage'].isEmpty
            ? Icon(Icons.person, color: Colors.white)
            : null,
      ),
      title: Text(
        userData['userName'] ?? "User",
        style: TextStyle(
          fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            userData['userEmail'] ?? "",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Row(
            children: [
              if (isFromUser && isUnread)
                Icon(Icons.circle, size: 8, color: Colors.pink[400]),
              if (isFromUser && isUnread) const SizedBox(width: 4),
              Expanded(
                child: Text(
                  userData['lastMessage'] ?? "",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isUnread ? Colors.black87 : Colors.grey[600],
                    fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formattedTime,
            style: TextStyle(
              fontSize: 12,
              color: isUnread ? Colors.pink[400] : Colors.grey[500],
            ),
          ),
          const SizedBox(height: 4),
          if (isUnread)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.pink[400],
                shape: BoxShape.circle,
              ),
              child: Text(
                userData['unreadCount'].toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminChatPage(
              userEmail: userData['userEmail'],
              userName: userData['userName'] ?? "User",
            ),
          ),
        );
      },
    );
  }
}

// Admin User List - Shows all registered users
class AdminUserList extends StatelessWidget {
  AdminUserList({Key? key}) : super(key: key);

  final AdminChatServices _chatServices = AdminChatServices();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Users"),
        backgroundColor: Colors.pink[100],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Customer Directory",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink[800]),
            ),
          ),
          Expanded(
            child: _buildUserList(),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder(
      stream: _chatServices.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error loading users: ${snapshot.error}"));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  "No registered users found",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: snapshot.data!.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final user = snapshot.data![index];
            return _buildUserListItem(user, context);
          },
        );
      },
    );
  }

  Widget _buildUserListItem(UserModel user, BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.pink[200],
        backgroundImage: user.imageUrl != null && user.imageUrl!.isNotEmpty
            ? NetworkImage(user.imageUrl!)
            : null,
        child: user.imageUrl == null || user.imageUrl!.isEmpty
            ? Icon(Icons.person, color: Colors.white)
            : null,
      ),
      title: Text(
        user.name,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            user.email,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Text(
            user.phone,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      trailing: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminChatPage(
                userEmail: user.email,
                userName: user.name,
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.pink[300],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: const Text("Chat"),
      ),
      onTap: () {
        // You can add user details view here if needed
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminChatPage(
              userEmail: user.email,
              userName: user.name,
            ),
          ),
        );
      },
    );
  }
}

// Admin Chat Page - For chatting with a specific user
class AdminChatPage extends StatefulWidget {
  final String userEmail;
  final String userName;

  const AdminChatPage(
      {Key? key, required this.userEmail, required this.userName})
      : super(key: key);

  @override
  _AdminChatPageState createState() => _AdminChatPageState();
}

class _AdminChatPageState extends State<AdminChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final AdminChatServices _chatServices = AdminChatServices();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Mark messages as read when opening chat
    _chatServices.markMessagesAsRead(widget.userEmail);
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isNotEmpty) {
      await _chatServices.sendMessage(
        widget.userEmail,
        _messageController.text.trim(),
      );
      _messageController.clear();

      // Scroll to bottom after sending message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.userName),
            Text(
              widget.userEmail,
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
      stream: _chatServices.getMessagesWithUser(widget.userEmail),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Error loading messages"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "No messages yet. Send a message to start the conversation!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        // Scroll to bottom on new messages
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController
                .jumpTo(_scrollController.position.maxScrollExtent);
          }
        });

        return ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(10),
          children:
              snapshot.data!.docs.map((doc) => _buildMessageItem(doc)).toList(),
        );
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
    bool isAdmin = data['senderEmail'] == _auth.currentUser!.email;

    // Format timestamp
    String formattedTime = '';
    if (data['timestamp'] != null) {
      DateTime messageTime = (data['timestamp'] as Timestamp).toDate();
      formattedTime = DateFormat.jm().format(messageTime);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isAdmin ? Colors.pink[100] : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data['message'] ?? '',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                formattedTime,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Row(
        children: [
          // Text input
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: "Type a message to ${widget.userName}...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          // Send button
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
    _scrollController.dispose();
    super.dispose();
  }
}
