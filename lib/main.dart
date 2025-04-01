import 'package:cake_bliss/Bloc/image/bloc.dart';
import 'package:cake_bliss/Bloc/login/bloc.dart';
import 'package:cake_bliss/Bloc/profile/bloc.dart';
import 'package:cake_bliss/Bloc/signup/bloc.dart';
import 'package:cake_bliss/checkout/checkout_cart.dart';
import 'package:cake_bliss/customization/customization.dart';
import 'package:cake_bliss/firebase_options.dart';
import 'package:cake_bliss/payment_history/payment_history.dart';
import 'package:cake_bliss/screen/home_page.dart';
import 'package:cake_bliss/splashscreen/splashscreen.dart';
import 'package:cake_bliss/storage/services/storage_services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await dotenv.load(fileName: ".env");
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
        BlocProvider(create: (context) => ProfileBloc()),
        BlocProvider(
          create: (context) => StorageBloc(
            storageService: StorageService(),
          ),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(
          visualDensity: VisualDensity.adaptivePlatformDensity,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const SplashScreen(title: 'Flutter Demo Home Page'),
        debugShowCheckedModeBanner: false,
        routes: {
          '/CheckoutPage': (context) => const CheckoutPage(),
          // '/add-address': (context) => const AddAddressPage(), // If you have this page
          // '/order-success': (context) => const OrderSuccessPage(), // If you have this page
          '/customization': (context) =>
              const CustomizationPage(), // If you have this page
          // Add other routes as needed
        },
      ),
    );
  }
}
