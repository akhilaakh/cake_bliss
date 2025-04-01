import 'dart:io';
import 'package:cakebliss_admin/Screen/homepage.dart';
import 'package:cakebliss_admin/bloc/signin/bloc.dart';
import 'package:cakebliss_admin/bloc/signin/event.dart';
import 'package:cakebliss_admin/bloc/signin/state.dart';
import 'package:cakebliss_admin/constants/appcolor.dart';
import 'package:cakebliss_admin/databaseservices/auth_service.dart';
import 'package:cakebliss_admin/databaseservices/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

final _auth = AuthService();

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  // Services and Controllers
  final _dbService = DatabaseService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // Regular Expressions
  final RegExp nameRegExp = RegExp(r'^[a-zA-Z]+$'); // Alphabets only

  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Image Picker Variables
  XFile? _selectedImage;

  // Image Picker Functionality
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  // Snackbar Utility
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color.fromARGB(255, 15, 6, 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildProfileImagePicker(),
              const SizedBox(height: 10),
              _buildHeader(),
              const SizedBox(height: 20),
              _buildFormFields(),
              const SizedBox(height: 16),
              _buildSignUpButton(),
            ],
          ),
        ),
      ),
    );
  }

  // Header Section
  Widget _buildHeader() {
    return const Column(
      children: [
        Text(
          'Sign Up',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 7),
        Text('Please sign up to get started'),
      ],
    );
  }

  // Profile Image Picker
  Widget _buildProfileImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: CircleAvatar(
        radius: 50,
        backgroundColor: Colors.grey[200],
        backgroundImage: _selectedImage != null
            ? FileImage(File(_selectedImage!.path))
            : null,
        child: _selectedImage == null
            ? const Icon(Icons.camera_alt, size: 40, color: Colors.grey)
            : null,
      ),
    );
  }

  // Form Fields Section
  Widget _buildFormFields() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildTextField(
            controller: _nameController,
            labelText: 'Name',
            keyboardType: TextInputType.text,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Name is required';
              } else if (!nameRegExp.hasMatch(value)) {
                return 'Name can only contain alphabets';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _addressController,
            labelText: 'Address',
            keyboardType: TextInputType.text,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Address is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _emailController,
            labelText: 'Email',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email is required';
              } else if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _passwordController,
            labelText: 'Password',
            keyboardType: TextInputType.text,
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              } else if (value.length < 8) {
                return 'Password must be at least 8 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _phoneController,
            labelText: 'Phone',
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Phone number is required';
              } else if (value.length != 10) {
                return 'Phone number must be 10 digits';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  // Generic TextField Builder with Validation
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required TextInputType keyboardType,
    bool obscureText = false,
    required String? Function(String?) validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
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

  // Sign Up Button with BLoC Integration
  Widget _buildSignUpButton() {
    return BlocConsumer<Signinbloc, SigninState>(
      listener: (context, state) {
        if (state is SigninSuccess) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Homepage(),
            ),
          );
        } else if (state is SigninFailure) {
          _showSnackBar(state.errormessage);
        }
      },
      builder: (context, state) {
        return ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              _onSignUpButtonPressed(context);
            }
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 150),
            backgroundColor: AppColors().mainColor,
          ),
          child: state is SigninLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  'SIGN UP',
                  style: TextStyle(color: Colors.white),
                ),
        );
      },
    );
  }

  // Sign Up Button Handler
  void _onSignUpButtonPressed(BuildContext context) {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();

    // Trigger BLoC Event
    context.read<Signinbloc>().add(
          SignButtonClick(
            name: name,
            email: email,
            password: password,
            phone: phone,
            address: address,
            context: context,
          ),
        );
  }
}
