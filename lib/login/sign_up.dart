import 'dart:io';
import 'package:cake_bliss/Bloc/image/bloc.dart';
import 'package:cake_bliss/Bloc/image/event.dart';
import 'package:cake_bliss/Bloc/image/state.dart';
import 'package:cake_bliss/Bloc/signup/bloc.dart';
import 'package:cake_bliss/Bloc/signup/event.dart';
import 'package:cake_bliss/Bloc/signup/state.dart';
import 'package:cake_bliss/constants/app_colors.dart';
import 'package:cake_bliss/databaseServices/database_service.dart';
import 'package:cake_bliss/services/auth_service.dart';
import 'package:cake_bliss/bottomnavigation.dart/bottom.dart';
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
  String? _selectedImagePath;
  String? _uploadedImageUrl;

  Widget _buildProfileImage() {
    return BlocListener<StorageBloc, StorageState>(
      listener: (context, state) {
        if (state is StorageSuccess) {
          setState(() {
            _uploadedImageUrl = state.lastUploadedUrl;
          });
        } else if (state is StorageFailure) {
          _showSnackBar(state.error);
        }
      },
      child: Center(
        // Wrap CircleAvatar inside Center widget
        child: Stack(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors().subcolor,
              backgroundImage: _selectedImagePath != null
                  ? FileImage(File(_selectedImagePath!))
                  : null,
              child: _selectedImagePath == null
                  ? const Icon(Icons.person, size: 50, color: Colors.grey)
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors().mainColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImagePath = image.path;
      });

      // Trigger image upload to storage
      // context.read<StorageBloc>().add(UploadImageEvent(
      //     imagepath: image.path,
      //     filePath:
      //         'profile_images/${DateTime.now().millisecondsSinceEpoch}.png',
      //     storagePath: 'profile_images/'));
      context.read<StorageBloc>().add(UploadImageEvent(
          filePath: image.path,
          storagePath:
              'profile_images/${DateTime.now().millisecondsSinceEpoch}.png',
          imagepath: image.path,
          imagePath: ''));
    }
  }

  // Services and Controllers
  final _dbService = DatabaseService();
  // ... rest of the code ...

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // Regular Expressions
  final RegExp nameRegExp = RegExp(r'^[a-zA-Z]+$'); // Alphabets only

  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Image Picker Functionality

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
      body: BlocListener<StorageBloc, StorageState>(
        listener: (context, state) {
          if (state is StorageSuccess) {
            setState(() {
              _uploadedImageUrl = state.lastUploadedUrl;
            });
          } else if (state is StorageFailure) {
            _showSnackBar(state.error);
          }
        },
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildProfileImage(),
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
              builder: (context) => const BottomNavigationScreen(),
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
    final imageUrl = _uploadedImageUrl;
    print("Uploading with image URL: $_uploadedImageUrl");

    // Trigger BLoC Event
    context.read<Signinbloc>().add(
          SignButtonClick(
            name: name,
            email: email,
            password: password,
            phone: phone,
            address: address,
            imageUrl: imageUrl,
            context: context,
          ),
        );
  }
}
