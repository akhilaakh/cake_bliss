import 'dart:developer';

import 'package:cake_bliss/Bloc/login/bloc.dart';
import 'package:cake_bliss/Bloc/login/event.dart';
import 'package:cake_bliss/Bloc/login/state.dart';
import 'package:cake_bliss/services/auth_service.dart';
import 'package:cake_bliss/bottomnavigation.dart/bottom.dart';
import 'package:cake_bliss/Login/forgot_password.dart';
import 'package:cake_bliss/screen/home_page.dart';
import 'package:cake_bliss/Login/sign_up.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final _auth = AuthService();

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isLoading = false;
  // TextEditingControllers for input fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    // Dispose controllers to avoid memory leaks

    _passwordController.dispose();
    _emailController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          // Prevent overflow on smaller screens
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'asset/image.png',
                height: 200,
              ),
              const SizedBox(height: 8),
              const Text(
                'LOGINN',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              // TextField 1: Username
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      borderSide: BorderSide(
                          color: Colors
                              .transparent), // Optional: No visible border
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      borderSide: BorderSide(
                        color: Color(0xFF6F2E00),
                      ), // Border color when focused
                    ),
                    labelText: 'Email',
                    fillColor: Color.fromARGB(
                        255, 245, 219, 199), // Adding the background color
                    filled: true,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _passwordController,
                  obscureText: true, // To hide the password
                  decoration: const InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                          Radius.circular(20)), // Rounded corners
                      borderSide: BorderSide(
                          color: Colors.transparent), // No visible border
                    ),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                            Radius.circular(20)), // Rounded corners
                        borderSide: BorderSide(
                          color: Color(0xFF6F2E00),
                        )
                        // Border color when focused
                        ),
                    labelText: 'Password',
                    fillColor: Color.fromARGB(
                        255, 245, 219, 199), // Adding the background color
                    filled: true,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ForgotPassword()));
                },
                child: const Text(
                  'Forgot Password',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              const SizedBox(height: 15),
              BlocConsumer<Loginbloc, LoginState>(
                listener: (context, state) {
                  if (state is LoginSuccess) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const BottomNavigationScreen()),
                    );
                  } else if (state is LoginFailure) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.errormessage)),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is LoginLoading) {
                    return const CircularProgressIndicator();
                  }
                  return ElevatedButton(
                    onPressed: () {
                      final email = _emailController.text.trim();
                      final password = _passwordController.text.trim();
                      context.read<Loginbloc>().add(
                            LoginButtonClick(
                                email: email,
                                password: password,
                                context: context),
                          );
                    },
                    style: ElevatedButton.styleFrom(
                      primary: Color.fromARGB(255, 18, 16, 14),
                      onPrimary: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 150),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Login',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
              // Login Button
              // Spacing between buttons
              const SizedBox(height: 16), // Spacing between buttons
              isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          isLoading = true;
                        });
                        await _auth.loginWithGoogle(context);
                        setState(() {
                          isLoading = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                          primary: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 15, horizontal: 90),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 5,
                          shadowColor: Color.fromARGB(255, 248, 246, 246)
                              .withOpacity(0.1),
                          backgroundColor: Colors.white),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'asset/985_google_g_icon.jpg',
                            height: 20,
                          ),
                          const SizedBox(
                              width: 8), // Add spacing between image and text
                          const Text(
                            'Login with Google',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6F2E00)),
                          ),
                        ],
                      ),
                    ),
              const SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Don’t have an account?',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SignUp(),
                          ));
                    },
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

loginn(String email, String password, BuildContext context) async {
  final user = await _auth.loginUserWithEmailAndPassword(email, password);
  if (user != null) {
    log("user logged in");
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(),
        ));
  }
}
