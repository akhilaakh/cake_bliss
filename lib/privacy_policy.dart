import 'package:cake_bliss/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class Privacypolicy extends StatefulWidget {
  const Privacypolicy({super.key});

  @override
  State<Privacypolicy> createState() => _PrivacypolicyState();
}

class _PrivacypolicyState extends State<Privacypolicy> {
  // Your specific email address
  final String contactEmail = 'akhilaakhipkd@gmail.com';

  // Method to launch email
  Future<void> _launchEmail() async {
    final Uri emailUri = Uri.parse(
        'mailto:$contactEmail?subject=CakeBliss App Inquiry&body=Dear CakeBliss Team,\n\n');

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        // Fallback if email client can't be launched
        _showEmailCopyDialog();
      }
    } catch (e) {
      // Show dialog if there's an error
      _showEmailCopyDialog();
    }
  }

  // Dialog to show when email can't be launched
  void _showEmailCopyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Contact Email'),
          content: Text(
              'Unable to open email client. Please copy the email:\n\n$contactEmail'),
          actions: <Widget>[
            TextButton(
              child: Text('Copy'),
              onPressed: () {
                // Implement copy to clipboard logic if needed
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors().mainColor,
        toolbarHeight: 100,
        title: Center(
          child: const Text(
            'Privacy Policy',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Policy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Effective Date: [Insert Date]',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Welcome to CakeBliss! Your privacy is important to us, and we are committed to protecting your personal information. This Privacy Policy explains how we collect, use, and protect your data when you use our app.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('1. Information We Collect'),
            _buildBulletPoint(
                'Personal Details: Name, Address, Phone Number, Email'),
            _buildBulletPoint('Profile Information: Profile Image'),
            _buildBulletPoint(
                'Payment Details: Razorpay is used for transactions, but we do not store your card or banking details'),
            const SizedBox(height: 16),
            _buildSectionTitle('2. How We Use Your Information'),
            _buildCheckPoint(
                'Order Processing: To process and deliver your cake orders'),
            _buildCheckPoint(
                'User Account Management: To create and manage your account'),
            _buildCheckPoint(
                'Payments: To facilitate secure transactions through Razorpay'),
            _buildCheckPoint(
                'Customer Support: To respond to your queries and provide assistance'),
            _buildCheckPoint(
                'Chat with baker: To respond to your queries and provide assistance'),
            _buildCheckPoint(
                'App Improvement: To enhance user experience and add new features'),
            const SizedBox(height: 16),
            _buildSectionTitle('3. Data Security'),
            _buildSecurityPoint(
                'We take necessary security measures to protect your data from unauthorized access'),
            _buildSecurityPoint(
                'Payment transactions are securely processed through Razorpay; we do not store your payment details'),
            _buildSecurityPoint(
                'While we strive to safeguard your information, we recommend keeping your login credentials secure'),
            const SizedBox(height: 16),
            _buildSectionTitle('4. Third-Party Services'),
            const Text(
              'We may use trusted third-party services to enhance our app experience, including:',
              style: TextStyle(fontSize: 16),
            ),
            _buildBulletPoint('Razorpay: For secure payment processing'),
            _buildBulletPoint(
                'Cloud Storage & Analytics Providers: For app performance improvements'),
            const Text(
              'These services have their own privacy policies, and we recommend reviewing them.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('5. Your Rights'),
            _buildCheckPoint('Access and update your personal information'),
            _buildCheckPoint('Request the deletion of your account and data'),
            _buildCheckPoint(
                'Withdraw consent for data processing (this may affect your ability to use some features)'),
            const Text(
              'For any data-related requests, contact us at [Your Email].',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('6. Changes to This Privacy Policy'),
            const Text(
              'We may update this Privacy Policy from time to time. Changes will be notified via in-app notifications or email. We encourage users to review this page periodically.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('7. Contact Us'),
            const Text(
              'If you have any questions or concerns about this Privacy Policy, please reach out to us at:',
              style: TextStyle(fontSize: 16),
            ),
            GestureDetector(
              onTap: _launchEmail,
              child: Text(
                'akhilaakhipkd@gmail.com',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const Text(
              '📍 [Your Business Address]',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🔹 ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('✅ ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🔒 ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
