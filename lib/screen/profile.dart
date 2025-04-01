import 'package:cake_bliss/Bloc/image/bloc.dart';
import 'package:cake_bliss/Login/loginpage.dart';
import 'package:cake_bliss/constants/app_colors.dart';
import 'package:cake_bliss/storage/services/storage_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cake_bliss/Bloc/profile/bloc.dart';
import 'package:cake_bliss/Bloc/profile/event.dart';
import 'package:cake_bliss/Bloc/profile/state.dart';
import 'package:cake_bliss/screen/profile_edit.dart';
import 'package:cake_bliss/services/auth_service.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfileBloc()..add(const FetchProfileEvent()),
      child: const ProfileForm(),
    );
  }
}

class ProfileForm extends StatefulWidget {
  const ProfileForm({super.key});

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? _currentImageUrl;
  final AuthService _auth = AuthService();

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Widget _buildProfileImage(String? imageUrl) {
    return Container(
      alignment: Alignment.center,
      margin: const EdgeInsets.only(bottom: 20),
      child: CircleAvatar(
        radius: 60,
        backgroundColor: AppColors().subcolor,
        backgroundImage: imageUrl != null && imageUrl.isNotEmpty
            ? NetworkImage(imageUrl)
            : null,
        child: (imageUrl == null || imageUrl.isEmpty)
            ? const Icon(Icons.person, size: 60, color: Colors.grey)
            : null,
      ),
    );
  }

  Widget _buildInfoContainer(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      height: 56,
      decoration: BoxDecoration(
        color: AppColors().subcolor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Logout Confirmation"),
          content: const Text("Are you sure you want to logout?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _auth.signout();
                if (!context.mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              child: const Text("Logout"),
            ),
          ],
        );
      },
    );
  }

  void _navigateToEditProfile(BuildContext context) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MultiBlocProvider(
          providers: [
            BlocProvider.value(
              value: context.read<ProfileBloc>(),
            ),
            BlocProvider(
              create: (context) => StorageBloc(
                storageService: StorageService(),
              ),
            ),
          ],
          child: const ProfileEditPage(),
        ),
      ),
    );

    if (updated == true && context.mounted) {
      context.read<ProfileBloc>().add(const FetchProfileEvent());
    }
  }

  Widget _buildBody(ProfileState state) {
    if (state is ProfileLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is ProfileError) {
      return Center(child: Text(state.message));
    }
    if (state is ProfileLoaded) {
      return RefreshIndicator(
        onRefresh: () async {
          context.read<ProfileBloc>().add(const FetchProfileEvent());
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildProfileImage(state.user.imageUrl),
                const SizedBox(height: 150),
                _buildInfoContainer(state.user.name),
                const SizedBox(height: 20),
                _buildInfoContainer(state.user.address),
                const SizedBox(height: 20),
                _buildInfoContainer(state.user.phone),
              ],
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors().mainColor,
        toolbarHeight: 100,
        title: const Center(
          child: Text(
            'Cake Bliss',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () => _navigateToEditProfile(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileLoaded) {
            setState(() {
              _nameController.text = state.user.name;
              _addressController.text = state.user.address;
              _phoneController.text = state.user.phone;
              _currentImageUrl = state.user.imageUrl;
              print("Profile loaded with image URL: ${state.user.imageUrl}");
            });
          }
        },
        builder: (context, state) => _buildBody(state),
      ),
    );
  }
}
