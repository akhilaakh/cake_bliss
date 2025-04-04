// chat_services.dart (User side)
import 'dart:io';

import 'package:cake_bliss/constants/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;

class UserChatServices {
  // Get instance of firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

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

  Future<void> sendImageMessage(String adminEmail, File imageFile) async {
    try {
      // Get current user info
      final String userEmail = getCurrentUserEmail();
      if (userEmail.isEmpty) {
        throw Exception("User not logged in or email not available");
      }

      final Timestamp timestamp = Timestamp.now();
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      final Reference storageRef =
          _storage.ref().child('chat_images/$fileName');

      // Upload image to Firebase Storage
      final UploadTask uploadTask = storageRef.putFile(imageFile);
      final TaskSnapshot taskSnapshot = await uploadTask;
      final String imageUrl = await taskSnapshot.ref.getDownloadURL();

      // Create a new message with image URL
      Map<String, dynamic> newMessage = {
        'senderEmail': userEmail,
        'receiverEmail': adminEmail,
        'message': '', // Empty message for image
        'imageUrl': imageUrl,
        'timestamp': timestamp,
        'isRead': false,
        'isImage': true,
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
        'lastMessage': '📷 Image',
        'lastMessageTimestamp': timestamp,
        'lastMessageSender': userEmail
      });
    } catch (e) {
      print("Error in sendImageMessage: $e");
      throw e; // Re-throw to handle in UI
    }
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
  final ImagePicker _imagePicker = ImagePicker();
  String? adminImageUrl;
  bool isLoading = true;
  bool _isSendingImage = false;

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

  Future<void> _pickImage() async {
    try {
      final XFile? pickedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // Compress image for faster upload
      );

      if (pickedImage != null) {
        setState(() {
          _isSendingImage = true;
        });

        // Convert XFile to File
        File imageFile = File(pickedImage.path);

        // Send image
        await _chatServices.sendImageMessage(widget.adminEmail, imageFile);

        setState(() {
          _isSendingImage = false;
        });
      }
    } catch (e) {
      setState(() {
        _isSendingImage = false;
      });
      print("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send image: $e")),
      );
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

        // Process messages to group by date
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = today.subtract(const Duration(days: 1));

        // Get all messages and sort them chronologically (oldest to newest)
        final List<QueryDocumentSnapshot> messages =
            snapshot.data!.docs.toList();

        // Group messages by date
        final Map<String, List<QueryDocumentSnapshot>> messagesByDate = {};

        for (final doc in messages) {
          final data = doc.data() as Map<String, dynamic>;
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

        // Build the list of widgets with date headers and messages
        final List<Widget> messageWidgets = [];

        // Sort the date keys in chronological order (oldest to newest)
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

        // Build the final list in reverse order (for the reversed ListView)
        for (int i = sortedDates.length - 1; i >= 0; i--) {
          final dateString = sortedDates[i];
          final messagesForDate = messagesByDate[dateString]!;

          // Add all messages for this date in reverse order
          // Inside _buildMessageList() where you handle different message types:
          for (int j = messagesForDate.length - 1; j >= 0; j--) {
            final data = messagesForDate[j].data() as Map<String, dynamic>;
            // Check if message is an image or text
            final bool isImage = data['isImage'] == true;
            if (isImage) {
              messageWidgets.add(
                _buildImageBubble(
                  // Use image bubble for images
                  imageUrl: data['imageUrl'],
                  isMe: data['senderEmail'] == _auth.currentUser?.email,
                  timestamp: data['timestamp'],
                  message:
                      data['message'] ?? '', // Provide empty string as fallback
                ),
              );
            } else {
              messageWidgets.add(
                _buildMessageBubble(
                  message: data['message'] ?? '',
                  isMe: data['senderEmail'] == _auth.currentUser?.email,
                  timestamp: data['timestamp'],
                  imageUrl: null, // Pass null for non-image messages
                ),
              );
            }
          }

          // Add date header
          messageWidgets.add(
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
        }

        // Build message list with the correctly ordered widgets
        return ListView(
          padding: const EdgeInsets.all(16),
          reverse: true,
          children: messageWidgets,
        );
      },
    );
  }

  // New widget for image bubble
  Widget _buildImageBubble({
    required imageUrl,
    required bool isMe,
    required Timestamp timestamp,
    required String message,
  }) {
    final time = DateFormat('h:mm a').format(timestamp.toDate());

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth:
              MediaQuery.of(context).size.width * 0.7, // 70% of screen width
          maxHeight: 200, // Maximum height for images
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image with loading indicator
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GestureDetector(
                onTap: () {
                  // View image in full screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullScreenImage(imageUrl: imageUrl),
                    ),
                  );
                },
                child: ConstrainedBox(
                  // Add this to limit image size
                  constraints: BoxConstraints(
                    maxHeight: 150, // Limit image height
                  ),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 200,
                        height: 150,
                        padding: EdgeInsets.all(8),
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: isMe ? Colors.white : AppColors().mainColor,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 200,
                        height: 150,
                        padding: EdgeInsets.all(8),
                        child: Center(
                          child: Icon(
                            Icons.error_outline,
                            color: isMe ? Colors.white70 : Colors.red[300],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            // Timestamp
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                time,
                style: TextStyle(
                  color: isMe ? Colors.white70 : Colors.black54,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble({
    required String message,
    required bool isMe,
    required Timestamp timestamp,
    required imageUrl,
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
          IconButton(
            icon: Icon(
              Icons.photo_library,
              color: AppColors().mainColor,
            ),
            onPressed: _isSendingImage ? null : _pickImage,
          ),
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
          _isSendingImage
              ? CircleAvatar(
                  backgroundColor: AppColors().mainColor.withOpacity(0.7),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                )
              : CircleAvatar(
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

class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImage({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 3,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  color: Colors.white,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
