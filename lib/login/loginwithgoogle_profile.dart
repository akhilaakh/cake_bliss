// import 'package:cake_bliss/Bloc/googleloginprofile/bloc.dart';
// import 'package:cake_bliss/Bloc/googleloginprofile/event.dart';
// import 'package:cake_bliss/Bloc/googleloginprofile/state.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:cake_bliss/bottomnavigation.dart/bottom.dart';
// import 'package:cake_bliss/constants/app_colors.dart';

// class Loginwithgoogleprofile extends StatelessWidget {
//   const Loginwithgoogleprofile({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider(
//       create: (_) => LoginProfileBloc(),
//       child: Scaffold(
//         appBar: AppBar(
//           toolbarHeight: 100,
//           backgroundColor: AppColors().mainColor,
//           title: const Center(
//             child: Text(
//               "Create Profile",
//               style: TextStyle(fontWeight: FontWeight.bold),
//             ),
//           ),
//         ),
//         body: const Padding(
//           padding: EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               ProfileForm(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class ProfileForm extends StatefulWidget {
//   const ProfileForm({super.key});

//   @override
//   State<ProfileForm> createState() => _ProfileFormState();
// }

// class _ProfileFormState extends State<ProfileForm> {
//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _addressController = TextEditingController();
//   final TextEditingController _phoneNumberController = TextEditingController();

//   @override
//   Widget build(BuildContext context) {
//     return BlocListener<LoginProfileBloc, LoginProfileState>(
//       listener: (context, state) {
//         if (state is LoginProfileError) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text(state.message)),
//           );
//         } else if (state is LoginProfileSuccess) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Profile saved successfully!')),
//           );
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (_) => const BottomNavigationScreen()),
//           );
//         }
//       },
//       child: Column(
//         children: [
//           TextField(
//             controller: _nameController,
//             decoration: const InputDecoration(
//               labelText: 'Name',
//               border: OutlineInputBorder(),
//             ),
//           ),
//           const SizedBox(height: 16),
//           TextField(
//             controller: _addressController,
//             decoration: const InputDecoration(
//               labelText: 'Address',
//               border: OutlineInputBorder(),
//             ),
//           ),
//           const SizedBox(height: 16),
//           TextField(
//             controller: _phoneNumberController,
//             keyboardType: TextInputType.phone,
//             decoration: const InputDecoration(
//               labelText: 'Phone Number',
//               border: OutlineInputBorder(),
//             ),
//           ),
//           const SizedBox(height: 24),
//           ElevatedButton(
//             onPressed: () {
//               final name = _nameController.text.trim();
//               final address = _addressController.text.trim();
//               final phoneNumber = _phoneNumberController.text.trim();
//               context.read<LoginProfileBloc>().add(
//                     SaveProfileEvent(
//                       name: name,
//                       address: address,
//                       phoneNumber: phoneNumber,
//                     ),
//                   );
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: AppColors().mainColor,
//               padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
//             ),
//             child: const Text('Save'),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _addressController.dispose();
//     _phoneNumberController.dispose();
//     super.dispose();
//   }
// }
