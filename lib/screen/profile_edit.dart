import 'dart:io';
import 'package:cake_bliss/model/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cake_bliss/Bloc/image/bloc.dart';
import 'package:cake_bliss/Bloc/image/event.dart';
import 'package:cake_bliss/Bloc/image/state.dart';
import 'package:cake_bliss/Bloc/profile/bloc.dart';
import 'package:cake_bliss/Bloc/profile/event.dart';
import 'package:cake_bliss/Bloc/profile/state.dart';
import 'package:cake_bliss/constants/app_colors.dart';
import 'package:cake_bliss/databaseServices/database_service.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();
  String? _currentImageUrl;
  String? _selectedImagePath;
  String? _uploadedImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Fetch current profile data
    context.read<ProfileBloc>().add(const FetchProfileEvent());
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImagePath = image.path;
        });

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId == null) {
          _showSnackBar('User not logged in');
          return;
        }

        final filePath = 'profile_images/${userId}_$timestamp.png';

        context.read<StorageBloc>().add(UploadImageEvent(
              imagePath: image.path,
              filePath: filePath,
              storagePath: 'profile_images/',
              imagepath: '',
            ));
      }
    } catch (e) {
      print('Error picking image: $e');
      _showSnackBar('Failed to pick image: ${e.toString()}');
    }
  }

  Widget _getImageWidget() {
    print('Selected Image Path: $_selectedImagePath');
    print('Current Image URL: $_currentImageUrl');
    print('Uploaded Image URL: $_uploadedImageUrl');

    if (_selectedImagePath != null) {
      return Image.file(
        File(_selectedImagePath!),
        fit: BoxFit.cover,
        width: 120,
        height: 120,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading local image: $error');
          return _defaultImageWidget();
        },
      );
    } else if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
      return Image.network(
        _currentImageUrl!,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) {
          print('Error loading network image: $error');
          return _defaultImageWidget();
        },
      );
    }

    return _defaultImageWidget();
  }

  Widget _defaultImageWidget() {
    return const Icon(
      Icons.person,
      size: 60,
      color: Colors.grey,
    );
  }

  Widget _buildProfileImage() {
    return BlocConsumer<StorageBloc, StorageState>(
      listener: (context, state) {
        if (state is StorageSuccess) {
          setState(() {
            _uploadedImageUrl = state.lastUploadedUrl;
            _currentImageUrl = state.lastUploadedUrl;
            print('Image uploaded successfully. URL: $_uploadedImageUrl');
          });
        } else if (state is StorageFailure) {
          _showSnackBar('Failed to upload image: ${state.error}');
        }
      },
      builder: (context, state) {
        return Center(
          child: Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors().subcolor,
                ),
                child: ClipOval(
                  child: state is StorageLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _getImageWidget(),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: state is StorageLoading ? null : _pickImage,
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
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: AppColors().subcolor,
        ),
      ),
    );
  }

  Future<void> _handleSubmit(UserModel currentUser) async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final updatedUser = UserModel(
          id: currentUser.id,
          name: _nameController.text.trim(),
          email: currentUser.email,
          password: currentUser.password,
          address: _addressController.text.trim(),
          phone: _phoneController.text.trim(),
          imageUrl: _uploadedImageUrl ?? _currentImageUrl ?? '',
        );

        print('Updating user with image URL: ${updatedUser.imageUrl}');
        context.read<ProfileBloc>().add(UpdateProfileEvent(updatedUser));
      } catch (e) {
        _showSnackBar('Failed to update profile: ${e.toString()}');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors().mainColor,
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileLoaded) {
            setState(() {
              _nameController.text = state.user.name;
              _addressController.text = state.user.address;
              _phoneController.text = state.user.phone;
              _currentImageUrl = state.user.imageUrl;
              print('Profile loaded with image URL: ${state.user.imageUrl}');
            });
          } else if (state is ProfileUpdateSuccess) {
            _showSnackBar('Profile updated successfully');
            Navigator.pop(context, true);
          } else if (state is ProfileError) {
            _showSnackBar(state.message);
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProfileLoaded) {
            return SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildProfileImage(),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _nameController,
                      labelText: 'Name',
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Name is required' : null,
                    ),
                    _buildTextField(
                      controller: _addressController,
                      labelText: 'Address',
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Address is required' : null,
                    ),
                    _buildTextField(
                      controller: _phoneController,
                      labelText: 'Phone',
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Phone number is required';
                        }
                        if (value!.length != 10) {
                          return 'Phone number must be 10 digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors().mainColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 50,
                          vertical: 15,
                        ),
                      ),
                      onPressed:
                          _isLoading ? null : () => _handleSubmit(state.user),
                      child: Text(
                        _isLoading ? 'Updating...' : 'Update Profile',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          }

          return const Center(child: Text('Something went wrong'));
        },
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
