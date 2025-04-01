// import 'package:flutter/material.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(

//     );
//   }
// }

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});

//   final String title;

//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(

//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,

//         ),
//       ),

//     );
//   }
// }
import 'package:cakebliss_admin/bloc/login/bloc.dart';
import 'package:cakebliss_admin/bloc/signin/bloc.dart';
import 'package:cakebliss_admin/firebase_option.dart';
import 'package:cakebliss_admin/splashscreen/spalashscreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => Loginbloc()),
          BlocProvider(create: (context) => Signinbloc()),
        ],
        child: MaterialApp(
          theme: ThemeData(
            visualDensity: VisualDensity.adaptivePlatformDensity,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          home: const SplashScreen(title: 'Flutter Demo Home Page'),
          debugShowCheckedModeBanner: false,
        ));
  }
}
