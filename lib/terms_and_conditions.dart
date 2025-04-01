import 'package:cake_bliss/constants/app_colors.dart';
import 'package:flutter/material.dart';

class TermsAndCondition extends StatefulWidget {
  const TermsAndCondition({super.key});

  @override
  State<TermsAndCondition> createState() => _TermsAndConditionState();
}

class _TermsAndConditionState extends State<TermsAndCondition> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        backgroundColor: AppColors().mainColor,
        title: Center(
          child: const Text(
            'Terms and Conditions',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('1. Introduction',
                'Welcome to CakeBliss! By using our app, you agree to comply with these Terms and Conditions. If you do not agree, please refrain from using the app.'),
            _buildSection(
                '2. Account Registration',
                'Users must register using their name, phone number, email, and password. Google login is available for a quick sign-in experience.\n\n'
                    'Users are responsible for maintaining account security. Any suspicious activity must be reported immediately.'),
            _buildSection(
                '3. User Information Collection',
                'We collect and store user details, including:\n'
                    '• Name\n'
                    '• Phone Number\n'
                    '• Address\n'
                    '• Profile Image\n'
                    '• Email\n\n'
                    'Your data is protected and used solely for improving our services.'),
            _buildSection(
                '4. Features and Services',
                'Users can access various features, including:\n'
                    '• Adding items to the Cart\n'
                    '• Marking products as Favourite\n'
                    '• Placing Orders\n'
                    '• Customization options for cakes\n\n'
                    'CakeBliss reserves the right to modify, add, or remove features at any time.'),
            _buildSection(
                '5. Payments',
                'Payments are processed securely via Razorpay.\n\n'
                    'We do not store your payment details.\n\n'
                    'All transactions are final, and refunds are subject to our refund policy.'),
            _buildSection(
                '6. Order and Delivery',
                'Orders once placed cannot be canceled if they are already in processing.\n\n'
                    'Delivery times may vary based on location and availability.\n\n'
                    'Users must provide accurate address details for seamless delivery.'),
            _buildSection(
                '7. User Conduct',
                'Users must not:\n'
                    '• Misuse or exploit any features of the app\n'
                    '• Provide false information during registration or orders\n'
                    '• Engage in fraudulent activities or abuse payment methods\n\n'
                    'Violation of these rules may result in account suspension or termination.'),
            _buildSection(
                '8. Privacy Policy',
                'Your personal information is handled as per our Privacy Policy.\n\n'
                    'We do not sell or share your data with third parties except for order processing.'),
            _buildSection(
                '9. Limitation of Liability',
                'CakeBliss is not responsible for:\n'
                    '• Any losses due to incorrect user-provided details\n'
                    '• Delays caused by unforeseen circumstances\n'
                    '• Issues with third-party payment providers'),
            _buildSection(
                '10. Changes to Terms & Conditions',
                'CakeBliss reserves the right to update these terms at any time.\n\n'
                    'Users will be notified of significant changes.'),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
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
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
