import 'dart:io';
import 'package:cakebliss_admin/constants/appcolor.dart';
import 'package:cakebliss_admin/databaseservices/database.dart';
import 'package:cakebliss_admin/model/usermodel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Services
  final _dbService = DatabaseService();
  final _auth = FirebaseAuth.instance;

  // User data
  AdminModel? _userProfile;
  bool _isLoading = true;

  // Edit mode
  bool _isEditing = false;

  // Controllers for editing
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Image picker
  XFile? _newProfileImage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.email != null) {
        final profile = await _dbService.readUserProfile(currentUser.email!);

        setState(() {
          _userProfile = profile;
          _isLoading = false;

          // Initialize controllers with current values
          _nameController.text = profile?.name ?? '';
          _addressController.text = profile?.address ?? '';
          _phoneController.text = profile?.phone ?? '';
        });
      } else {
        _showSnackBar('User not logged in');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      _showSnackBar('Error loading profile: ${e.toString()}');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String?> _uploadProfileImage() async {
    if (_newProfileImage == null) return null;

    try {
      final fileName = '${_auth.currentUser!.uid}_profile.jpg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child(fileName);

      // Upload the file
      await ref.putFile(File(_newProfileImage!.path));

      // Get download URL
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      _showSnackBar('Error uploading image: ${e.toString()}');
      return null;
    }
  }

  Future<void> _updateProfile() async {
    if (_userProfile == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload image if a new one was selected
      String? imageUrl = _userProfile!.imageUrl;
      if (_newProfileImage != null) {
        final newImageUrl = await _uploadProfileImage();
        if (newImageUrl != null) {
          imageUrl = newImageUrl;
        }
      }

      final updatedProfile = _userProfile!.copyWith(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        imageUrl: imageUrl, // Add the image URL here
      );

      await _dbService.updateUserProfile(updatedProfile);

      // Reload the profile to get the updated data
      await _loadUserProfile();

      setState(() {
        _isEditing = false;
        _newProfileImage = null; // Reset the selected image
      });

      _showSnackBar('Profile updated successfully');
    } catch (e) {
      _showSnackBar('Error updating profile: ${e.toString()}');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _newProfileImage = image;
      });
    }
  }

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
      appBar: AppBar(
        toolbarHeight: 100,
        title: Padding(
          padding: const EdgeInsets.all(85.0),
          child: const Text(
            'Profile',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: AppColors().mainColor,
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  // Reset controllers to original values
                  _nameController.text = _userProfile?.name ?? '';
                  _addressController.text = _userProfile?.address ?? '';
                  _phoneController.text = _userProfile?.phone ?? '';
                  _newProfileImage = null;
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userProfile == null
              ? const Center(child: Text('No profile data found'))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildProfileImage(),
                        const SizedBox(height: 24),
                        _isEditing ? _buildEditForm() : _buildProfileDetails(),
                        const SizedBox(height: 24),
                        if (_isEditing) _buildSaveButton(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildProfileImage() {
    return GestureDetector(
      onTap: _isEditing ? _pickImage : null,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey[200],
            backgroundImage: _getProfileImage(),
            child: _getProfileImagePlaceholder(),
          ),
          if (_isEditing)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
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
        ],
      ),
    );
  }

  ImageProvider? _getProfileImage() {
    if (_newProfileImage != null) {
      return FileImage(File(_newProfileImage!.path));
    } else if (_userProfile?.imageUrl != null &&
        _userProfile!.imageUrl!.isNotEmpty) {
      return NetworkImage(_userProfile!.imageUrl!);
    }
    return null;
  }

  Widget? _getProfileImagePlaceholder() {
    if (_newProfileImage == null &&
        (_userProfile?.imageUrl == null || _userProfile!.imageUrl!.isEmpty)) {
      return const Icon(Icons.person, size: 60, color: Colors.grey);
    }
    return null;
  }

  Widget _buildProfileDetails() {
    return Column(
      children: [
        _buildProfileDetailItem(
          icon: Icons.person,
          title: 'Name',
          value: _userProfile?.name ?? 'N/A',
        ),
        const Divider(),
        _buildProfileDetailItem(
          icon: Icons.email,
          title: 'Email',
          value: _userProfile?.email ?? 'N/A',
        ),
        const Divider(),
        _buildProfileDetailItem(
          icon: Icons.phone,
          title: 'Phone',
          value: _userProfile?.phone ?? 'N/A',
        ),
        const Divider(),
        _buildProfileDetailItem(
          icon: Icons.location_on,
          title: 'Address',
          value: _userProfile?.address ?? 'N/A',
        ),
      ],
    );
  }

  Widget _buildProfileDetailItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors().mainColor, size: 28),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Column(
      children: [
        _buildEditField(
          controller: _nameController,
          labelText: 'Name',
          icon: Icons.person,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Name is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        // Email field (readonly)
        _buildProfileDetailItem(
          icon: Icons.email,
          title: 'Email',
          value: _userProfile?.email ?? 'N/A',
        ),
        const SizedBox(height: 16),
        _buildEditField(
          controller: _phoneController,
          labelText: 'Phone',
          icon: Icons.phone,
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
        const SizedBox(height: 16),
        _buildEditField(
          controller: _addressController,
          labelText: 'Address',
          icon: Icons.location_on,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Address is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildEditField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon, color: AppColors().mainColor),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: AppColors().mainColor),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: Colors.grey[100],
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _updateProfile,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: AppColors().mainColor,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Text(
        'Save Changes',
        style: TextStyle(fontSize: 16),
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
