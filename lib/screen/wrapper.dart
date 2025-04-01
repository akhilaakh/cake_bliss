import 'package:cake_bliss/bottomnavigation.dart/bottom.dart';
import 'package:cake_bliss/Login/loginpage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (snapshot.hasError) {
              return const Center(
                child: Text("error"),
              );
            } else {
              if (snapshot.data == null) {
                return const LoginPage();
              } else {
                return const BottomNavigationScreen();
              }
            }
          }),
    );
  }
}
// import 'package:cake_bliss/home_page.dart';
// import 'package:cake_bliss/loginpage.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';

// class Wrapper extends StatelessWidget {
//   const Wrapper({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: StreamBuilder<User?>(
//         stream: FirebaseAuth.instance.authStateChanges(),
//         builder: (context, snapshot) {
//           // Show loading indicator while waiting
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(
//               child: CircularProgressIndicator(),
//             );
//           }
//           // Handle errors in the stream
//           if (snapshot.hasError) {
//             return Center(
//               child: Text("An error occurred: ${snapshot.error}"),
//             );
//           }
//           // Display appropriate screen based on authentication state
//           if (snapshot.hasData && snapshot.data != null) {
//             return const HomePage(); // User is logged in
//           } else {
//             return const LoginPage(); // User is not logged in
//           }
//         },
//       ),
//     );
//   }
// }
