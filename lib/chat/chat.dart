// chat_services.dart (User side)
import 'package:cake_bliss/constants/app_colors.dart';
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
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _openExistingChat();
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        // Check if widget is still in the tree
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading chats: $e")),
        );
      }
    }
  }

  void _openExistingChat() {
    if (_existingAdminEmail != null) {
      // Get admin name from database first
      _chatServices.getAdminStream().first.then((admins) {
        final adminInfo = admins.firstWhere(
            (admin) => admin['email'] == _existingAdminEmail,
            orElse: () => {'name': 'Admin', 'email': _existingAdminEmail!});

        Navigator.push(
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
          toolbarHeight: 100,
          title: Center(
              child: const Text(
            "Chat with Support",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          )),
          backgroundColor: Colors.pink[100],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        title: Center(
            child: const Text(
          "Chat with Support",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        )),
        backgroundColor: AppColors().mainColor,
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
                '',
                // "Select a support agent to chat with",
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
  String? adminImageUrl;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Mark messages as read when opening chat
    _chatServices.markMessagesAsRead(widget.adminEmail);
    _fetchAdminImage();
  }

  void _fetchAdminImage() async {
    try {
      final adminDoc = await FirebaseFirestore.instance
          .collection("admin")
          .where("email", isEqualTo: widget.adminEmail)
          .get();

      if (adminDoc.docs.isNotEmpty) {
        final adminData = adminDoc.docs.first.data();
        setState(() {
          adminImageUrl = adminData['image'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching admin image: $e");
      setState(() {
        isLoading = false;
      });
    }
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
        toolbarHeight: 100,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Row(children: [
          // Admin Profile Image
          isLoading
              ? CircleAvatar(
                  backgroundColor: Colors.grey[300],
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors().mainColor,
                  ),
                )
              : CircleAvatar(
                  backgroundColor: Colors.grey[300],
                  backgroundImage:
                      adminImageUrl != null && adminImageUrl!.isNotEmpty
                          ? NetworkImage(adminImageUrl!)
                          : null,
                  child: adminImageUrl == null || adminImageUrl!.isEmpty
                      ? Text(
                          widget.adminName.isNotEmpty
                              ? widget.adminName[0].toUpperCase()
                              : " ",
                          style: TextStyle(
                            color: AppColors().mainColor,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),

          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.adminName,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          )
        ]),
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
        // Add constraints to limit the width
        constraints: BoxConstraints(
          maxWidth:
              MediaQuery.of(context).size.width * 0.7, // 70% of screen width
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppColors().mainColor : AppColors().subcolor,
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
    print("UserChatPage dispose called");
    _messageController.dispose();
    super.dispose();
  }
}
