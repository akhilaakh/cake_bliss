// import 'dart:js';

// import 'package:cake_bliss/chat/chat.dart';
// import 'package:cake_bliss/chat/chat_services.dart';
// import 'package:cake_bliss/services/auth_service.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_chat_ui/flutter_chat_ui.dart';

// class ChatList extends StatelessWidget {
//   ChatList({super.key});
//   final ChatServices _chatServices = ChatServices();
//   final AuthService _authService = AuthService();
  

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("chatlist"),
//       ),
//       drawer: MyDrawer(),
//       body: _buildUserList(),
//     );
//   }

//   Widget _buildUserList() {
//     return StreamBuilder(
//       stream: _chatServices.getUserStream(),
//       builder: (context, snapshot) {
//         if (snapshot.hasError) {
//           return Text("error");
//         }
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Text("loading");
//         }
//         return ListView(
//           children: snapshot.data!
//               .map<Widget>((userData) => _buildUserListItem(userData, context))
//               .toList(),
//         );
//       },
//     );
//   }

//   Widget _buildUserListItem(
//       Map<String, dynamic> userData, BuildContext context) {
//     if (userData["email"] != _authService.getCurrentUser())
//       return userTile(
//           Text: userData["email"],
//           onTap: () {
//             Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => ChatPage(
//                     receiverEmail: userData["email"],
//                   ),
//                 ));
//           });
//   }
// }
