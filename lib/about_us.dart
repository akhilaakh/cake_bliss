import 'package:cake_bliss/constants/app_colors.dart';
import 'package:flutter/material.dart';

class AboutUs extends StatelessWidget {
  const AboutUs({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        backgroundColor: AppColors().mainColor,
        title: const Text(
          'About Us',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  const Text(
                    'Cake Bliss 🍰✨',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.pink[50],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Text(
                      'Welcome to Cake Bliss, your one-stop destination for delightful and customized cakes! Whether you\'re celebrating a birthday, anniversary, or any special occasion, we bring you the perfect cake that suits your taste and style.',
                      style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Why Choose Cake Bliss Section
            const Text(
              'Why Choose Cake Bliss?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 15),

            // Features List
            _buildFeatureItem(
              icon: Icons.cake,
              title: 'Personalized Creations 🎨',
              description:
                  'Have a cake idea in mind? Share your vision, and we\'ll bring it to life! Our customization feature lets you request unique cakes tailored to your imagination.',
            ),
            _buildFeatureItem(
              icon: Icons.favorite,
              title: 'Favorite & Cart Features ❤️🛒',
              description:
                  'Easily add cakes to your Favorites or Cart for a seamless shopping experience.',
            ),
            _buildFeatureItem(
              icon: Icons.security,
              title: 'Secure Payments 🔒',
              description:
                  'We prioritize your safety with Razorpay, ensuring a 100% secure payment experience without storing any of your bank details.',
            ),
            _buildFeatureItem(
              icon: Icons.local_offer,
              title: 'Exclusive Offers 🎉',
              description:
                  'Our admin regularly updates special offers, so you can enjoy your favorite cakes at the best prices.',
            ),
            _buildFeatureItem(
              icon: Icons.chat,
              title: 'Chat with Us 💬',
              description:
                  'Have questions or special requests? Our in-app chat allows smooth communication between users and the admin.',
            ),

            // Footer
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.pink[100]!, Colors.pink[50]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Text(
                'At Cake Bliss, we believe that every cake tells a story. Let us be a part of your celebrations and make your moments sweeter!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.pink[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.pink[700]),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
