// import 'package:cake_bliss/chat/chat.dart';
// import 'package:cake_bliss/favourite/favourite.dart';
// import 'package:flutter/material.dart';
// import 'package:curved_navigation_bar/curved_navigation_bar.dart';

// // Screens imports
// import 'package:cake_bliss/screen/home_page.dart';
// import 'package:cake_bliss/screen/cart.dart';
// import 'package:cake_bliss/screen/chat.dart';
// import 'package:cake_bliss/screen/favorite.dart';
// import 'package:cake_bliss/screen/profile.dart';

// class BottomNavigationScreen extends StatefulWidget {
//   const BottomNavigationScreen({Key? key}) : super(key: key);

//   @override
//   State<BottomNavigationScreen> createState() => _BottomNavigationScreenState();
// }

// class _BottomNavigationScreenState extends State<BottomNavigationScreen> {
//   int currentIndex = 0;

//   final List<Widget> _screens = [
//     const HomePage(),
//     const FavouritesPage(),

//     const CartPage(),
//     UserChatList(),
//     // Uncomment or create this screen
//     const Profile(),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: IndexedStack(
//         // Use IndexedStack to preserve state
//         index: currentIndex,
//         children: _screens,
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: currentIndex,
//         onTap: (index) {
//           setState(() {
//             currentIndex = index;
//           });
//         },
//         type: BottomNavigationBarType.fixed, // Important for multiple items
//         backgroundColor: const Color(0xFF6F2E00),
//         selectedItemColor: Colors.white,
//         unselectedItemColor: Colors.white54,
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home),
//             label: 'Home',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.favorite_border_outlined),
//             label: 'Favorites',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.shopping_cart),
//             label: 'Cart',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.chat_bubble_outline_rounded),
//             label: 'Chat',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.person),
//             label: 'Profile',
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:cake_bliss/chat/chat.dart';
import 'package:cake_bliss/favourite/favourite.dart';
import 'package:cake_bliss/screen/cart.dart';
import 'package:cake_bliss/screen/home_page.dart';
import 'package:cake_bliss/screen/profile.dart';
import 'package:flutter/material.dart';

class BottomNavigationScreen extends StatefulWidget {
  const BottomNavigationScreen({Key? key}) : super(key: key);

  @override
  State<BottomNavigationScreen> createState() => _BottomNavigationScreenState();
}

class _BottomNavigationScreenState extends State<BottomNavigationScreen> {
  int currentIndex = 0;
  final UserChatServices _chatServices = UserChatServices();

  final List<Widget> _screens = [
    const HomePage(),
    const FavouritesPage(),
    const CartPage(),
    const Center(child: CircularProgressIndicator()), // Placeholder for chat
    const Profile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (index == 3) {
            // Chat tab index
            _handleChatNavigation(context);
          } else {
            setState(() {
              currentIndex = index;
            });
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF6F2E00),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border_outlined),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _handleChatNavigation(BuildContext context) async {
    setState(() {
      currentIndex = 3; // Set to chat tab
    });

    try {
      // Show loading while checking for existing chats
      final existingAdminEmail = await _chatServices.getExistingAdminChat();

      if (existingAdminEmail != null) {
        // User has an existing chat, navigate directly to it
        _chatServices.getAdminStream().first.then((admins) {
          final adminInfo = admins.firstWhere(
              (admin) => admin['email'] == existingAdminEmail,
              orElse: () => {'name': 'Admin', 'email': existingAdminEmail});

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserChatPage(
                adminEmail: existingAdminEmail,
                adminName: adminInfo['name'] ?? 'Admin',
              ),
            ),
          );
        });
      } else {
        // No existing chat, show the admin list
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserChatList(),
          ),
        );
      }
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading chats: $e")),
      );

      // Show admin list on error
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserChatList(),
        ),
      );
    }
  }
}
