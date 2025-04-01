import 'dart:developer';

import 'package:cakebliss_admin/Login/signup.dart';
import 'package:cakebliss_admin/Screen/homepage.dart';
import 'package:cakebliss_admin/bloc/login/bloc.dart';
import 'package:cakebliss_admin/bloc/login/event.dart';
import 'package:cakebliss_admin/bloc/login/state.dart';
import 'package:cakebliss_admin/constants/appcolor.dart';
import 'package:cakebliss_admin/databaseservices/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final _auth = AuthService();

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLogo(),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _emailController,
                labelText: 'Email',
                isPassword: false,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _passwordController,
                labelText: 'Password',
                isPassword: true,
              ),
              const SizedBox(height: 15),
              _buildForgotPasswordButton(context),
              const SizedBox(height: 15),
              _buildLoginButton(context),
              const SizedBox(height: 16),
              _buildSignUpSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Image.asset(
          'assets/964c04ab-bc2f-431f-a575-0c1f5580d38f.jpg',
          height: 200,
        ),
        const SizedBox(height: 8),
        const Text(
          'ADMIN LOGIN',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required bool isPassword,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: isPassword
            ? TextInputType.visiblePassword
            : TextInputType.emailAddress,
        decoration: InputDecoration(
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
            borderSide: BorderSide(color: Colors.transparent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            borderSide: BorderSide(color: AppColors().mainColor),
          ),
          labelText: labelText,
          fillColor: AppColors().subcolor,
          filled: true,
        ),
      ),
    );
  }

  Widget _buildForgotPasswordButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Homepage()),
        );
      },
      child: const Text(
        'Forgot Password',
        style: TextStyle(color: Colors.red),
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return BlocConsumer<Loginbloc, LoginState>(
      listener: (context, state) {
        if (state is LoginSuccess) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Homepage()),
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
                    context: context,
                  ),
                );
          },
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: AppColors().mainColor,
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 150),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text(
            'Login',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }

  Widget _buildSignUpSection(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Don’t have an account?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SignUp()),
            );
          },
          child: const Text(
            'Sign Up',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }
}

Future<void> loginn(String email, String password, BuildContext context) async {
  final admin = await _auth.loginUserWithEmailAndPassword(email, password);
  if (admin != null) {
    log("User logged in");
    // ignore: use_build_context_synchronously
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Homepage()),
    );
  }
}
