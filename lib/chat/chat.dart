import 'package:cakebliss_admin/constants/appcolor.dart';
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

  // Get users who have conversations with this admin
  Stream<List<Map<String, dynamic>>> getUsersWithChats() {
    final adminEmail = getCurrentAdminEmail();

    // This query requires a composite index - follow the error URL to create it
    try {
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
          final String userEmail = users
              .firstWhere((email) => email != adminEmail, orElse: () => '');

          if (userEmail.isNotEmpty) {
            // Get user information
            try {
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
                print('Found user: $userName with image: $userImage');
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
            } catch (e) {
              print('Error fetching user info: $e');
              // Add basic info even if detailed user fetch fails
              userChats.add({
                'roomId': doc.id,
                'userEmail': userEmail,
                'userName': 'User',
                'userImage': '',
                'lastMessage': data['lastMessage'] ?? '',
                'lastMessageTimestamp': data['lastMessageTimestamp'],
                'lastMessageSender': data['lastMessageSender'] ?? '',
                'unreadCount': 0,
              });
            }
          }
        }

        return userChats;
      });
    } catch (e) {
      print('Error in getUsersWithChats: $e');
      // Return an empty stream in case of error
      return Stream.value([]);
    }
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
  // getMessagesWithUser

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
          // Admin menu options - Now only shows Customer Chats
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
                // Removed "All Users" card as requested
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

// Admin Chat List - Shows only users with active conversations
class AdminChatList extends StatelessWidget {
  AdminChatList({Key? key}) : super(key: key);

  final AdminChatServices _chatServices = AdminChatServices();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          toolbarHeight: 100,
          title: Padding(
            padding: const EdgeInsets.all(50.0),
            child: Text(
              "Customer Chats",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
          ),
          backgroundColor: AppColors().mainColor),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            // child: Text(
            //   '',
            //   // "Customer Conversations"',
            //   style: TextStyle(
            //       fontSize: 18,
            //       fontWeight: FontWeight.bold,
            //       color: Colors.pink[800]),
            // ),
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
        backgroundColor: AppColors().mainColor,
        backgroundImage:
            userData['imageUrl'] != null && userData['imageUrl'].isNotEmpty
                ? NetworkImage(userData['imageUrl'])
                : null,
        child: userData['imageUrl'] == null || userData['imageUrl'].isEmpty
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
        toolbarHeight: 100,
        title: Padding(
          padding: const EdgeInsets.all(80.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.userName,
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 23),
              ),
              Text(
                widget.userEmail,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: AppColors().mainColor,
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
        } // Process messages to group by date
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = today.subtract(const Duration(days: 1));

        // Get all messages
        final List<QueryDocumentSnapshot> messages =
            snapshot.data!.docs.toList();

        // Group messages by date
        final Map<String, List<QueryDocumentSnapshot>> messagesByDate = {};

        for (final doc in messages) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['timestamp'] == null) continue;

          final messageDate = (data['timestamp'] as Timestamp).toDate();
          final messageDateOnly =
              DateTime(messageDate.year, messageDate.month, messageDate.day);

          // Determine date string for header
          String dateString;
          if (messageDateOnly == today) {
            dateString = "Today";
          } else if (messageDateOnly == yesterday) {
            dateString = "Yesterday";
          } else if (now.difference(messageDateOnly).inDays < 7) {
            dateString = DateFormat('EEEE').format(messageDate); // day name
          } else {
            dateString = DateFormat('MMMM d, yyyy').format(messageDate);
          }

          if (!messagesByDate.containsKey(dateString)) {
            messagesByDate[dateString] = [];
          }

          messagesByDate[dateString]!.add(doc);
        }

        // Sort date keys chronologically
        final List<String> sortedDates = messagesByDate.keys.toList();
        sortedDates.sort((a, b) {
          // Special handling for "Today" and "Yesterday"
          if (a == "Today") return 1;
          if (b == "Today") return -1;
          if (a == "Yesterday") return 1;
          if (b == "Yesterday") return -1;

          // For other dates, parse and compare
          DateTime? dateA, dateB;
          try {
            if (!a.contains(",")) {
              // It's a day name
              final daysOfWeek = [
                "Monday",
                "Tuesday",
                "Wednesday",
                "Thursday",
                "Friday",
                "Saturday",
                "Sunday"
              ];
              final dayIndex = daysOfWeek.indexOf(a);
              if (dayIndex != -1) {
                dateA = today
                    .subtract(Duration(days: today.weekday - 1 - dayIndex));
              }
            } else {
              dateA = DateFormat('MMMM d, yyyy').parse(a);
            }

            if (!b.contains(",")) {
              // It's a day name
              final daysOfWeek = [
                "Monday",
                "Tuesday",
                "Wednesday",
                "Thursday",
                "Friday",
                "Saturday",
                "Sunday"
              ];
              final dayIndex = daysOfWeek.indexOf(b);
              if (dayIndex != -1) {
                dateB = today
                    .subtract(Duration(days: today.weekday - 1 - dayIndex));
              }
            } else {
              dateB = DateFormat('MMMM d, yyyy').parse(b);
            }

            if (dateA != null && dateB != null) {
              return dateA.compareTo(dateB);
            }
          } catch (e) {
            print("Error parsing dates: $e");
          }

          return a.compareTo(b);
        });

        // Build the final list with message groups
        List<Widget> allWidgets = [];

        for (final dateString in sortedDates) {
          // Add date header
          allWidgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    dateString,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),
            ),
          );

          // Add messages for this date
          final messagesForDate = messagesByDate[dateString]!;
          for (final doc in messagesForDate) {
            allWidgets.add(_buildMessageItem(doc));
          }
        }

        // Scroll to bottom on new messages
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
          children: allWidgets,
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
            color: isAdmin ? AppColors().mainColor : Colors.grey[200],
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
            backgroundColor: AppColors().mainColor,
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
