import 'package:cakebliss_admin/category/category_screen/add_category.dart';
import 'package:cakebliss_admin/category/category_screen/view1_category.dart';
import 'package:cakebliss_admin/chat/chat.dart';
import 'package:cakebliss_admin/chatt/chat.dart';
import 'package:cakebliss_admin/customization/custamer_list_custamization.dart';
import 'package:cakebliss_admin/customization/customization_list.dart';
import 'package:cakebliss_admin/order/order.dart';
import 'package:cakebliss_admin/type/add_type.dart';
import 'package:flutter/material.dart';
import 'package:cakebliss_admin/Login/login.dart';
import 'package:cakebliss_admin/constants/appcolor.dart';
import 'package:cakebliss_admin/databaseservices/auth_service.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final AuthService _auth = AuthService();

  // Method to show a confirmation dialog
  Future<void> _showLogoutDialog() async {
    bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Don't logout
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _auth.signout();

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> cards = [
      {
        'title': 'Add Category',
        'route': AddCategoryScreen(),
        'image':
            'assets/Cute_adorable_kawaii_birthday_cake_sticker-removebg-preview.png',
      },
      {
        'title': 'View Category',
        'route': const CategoryViewPage(),
        'image':
            'assets/Wedding_Cake_Watercolor_Clipart_4_High_Quality_PNG__Digital_Download__Card_Making_Mixed_Media__Crafts_Clip_Art_-_394-removebg-preview (1).png',
      },
      {
        'title': 'Add Items',
        'route': const AddTypePage(),
        'image':
            'assets/_Pink_Cupcake_Gourmet__Sticker_for_Sale_by_SHADOWNB69-removebg-preview.png',
      },
      {
        'title': 'customization',
        'route': CustomerList(),
        'image':
            'assets/_Pink_Cupcake_Gourmet__Sticker_for_Sale_by_SHADOWNB69-removebg-preview.png',
      },
      {
        'title': 'order',
        'route': AdminOrdersPage(),
        'image':
            'assets/_Pink_Cupcake_Gourmet__Sticker_for_Sale_by_SHADOWNB69-removebg-preview.png',
      },
      {
        'title': 'chat',
        'route': AdminUserList(),
        'image':
            'assets/_Pink_Cupcake_Gourmet__Sticker_for_Sale_by_SHADOWNB69-removebg-preview.png',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        title: Center(
          child: Text(
            '       Cake Bliss',
            style: TextStyle(
                color: AppColors().subcolor,
                fontWeight: FontWeight.bold,
                fontSize: 35),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.exit_to_app,
              color: AppColors().subcolor,
            ),
            onPressed: _showLogoutDialog,
          ),
          const SizedBox(height: 30),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 30.0), // Add padding for gap
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: ClipPath(
              clipper:
                  CurvedBodyTopClipper(), // Custom clipper for the top curve
              child: Container(
                color: AppColors().mainColor, // Apply color to the body
                padding: const EdgeInsets.all(50),
                child: GridView.builder(
                  itemCount: cards.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final card = cards[index];
                    return Card(
                      color: Colors.white,
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => card['route']),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Image.asset(
                                  card['image'],
                                  height: 60,
                                  width: 60,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.broken_image,
                                      size: 60,
                                      color: Colors.white,
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                card['title'],
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Custom clipper for the top of the body container
class CurvedBodyTopClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, 0); // Starting from the top-left corner
    path.quadraticBezierTo(
        size.width / 2, 50, size.width, 0); // Create a curve at the top
    path.lineTo(size.width, size.height); // Move down the right side
    path.lineTo(0, size.height); // Move across the bottom
    path.close(); // Close the path
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}
