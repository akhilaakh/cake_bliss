import 'package:cake_bliss/constants/app_colors.dart';
import 'package:cake_bliss/services/auth_service.dart';
import 'package:cake_bliss/Login/loginpage.dart';
import 'package:flutter/material.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final AuthService _auth = AuthService();
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    // Dispose of the email controller to avoid memory leaks
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: SingleChildScrollView(
          // Prevent overflow on smaller screens
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Display an image at the top
              Image.asset(
                'asset/image.png',
                height: 200,
              ),
              const SizedBox(height: 8),

              // Title with navigation to login page
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginPage(),
                    ),
                  );
                },
                child: const Text(
                  'Forgot Password',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
              const Text(
                'Please sign in to your existing account',
                style: TextStyle(fontWeight: FontWeight.w200),
              ),
              const SizedBox(height: 20),

              // Email input field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    enabledBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      borderSide: BorderSide(
                        color: Colors.transparent, // No visible border
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: const BorderRadius.all(Radius.circular(20)),
                      borderSide: BorderSide(
                        color:
                            AppColors().mainColor, // Border color when focused
                      ),
                    ),
                    labelText: 'Email',
                    fillColor: AppColors().subcolor, // Background color
                    filled: true,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Submit button for sending reset code
              ElevatedButton(
                onPressed: () async {
                  await _auth.sendPassWordResetLink(_emailController.text);

                  // Display confirmation message
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "An email for password reset has been sent to your email.",
                      ),
                    ),
                  );

                  // Navigate back to the previous screen
                  if (mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: AppColors().mainColor,
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 140,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 5,
                  shadowColor: Colors.black.withOpacity(0.5),
                ),
                child: const Text(
                  'SEND CODE',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
