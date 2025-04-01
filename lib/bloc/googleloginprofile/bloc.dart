// import 'dart:developer';

// import 'package:bloc/bloc.dart';
// import 'package:cake_bliss/Bloc/googleloginprofile/event.dart';
// import 'package:cake_bliss/Bloc/googleloginprofile/state.dart';
// import 'package:cake_bliss/databaseServices/database_service.dart';
// import 'package:cake_bliss/model/user_model.dart';
// import 'package:cake_bliss/services/auth_service.dart';

// class LoginProfileBloc extends Bloc<LoginProfileEvent, LoginProfileState> {
//   LoginProfileBloc() : super(LoginProfileInitial()) {
//     on<SaveProfileEvent>(_onSaveProfile);
//   }

//   Future<void> _onSaveProfile(
//     SaveProfileEvent event,
//     Emitter<LoginProfileState> emit,
//   ) async {
//     emit(LoginProfileLoading());

//     try {
//       // Validate the name
//       if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(event.name)) {
//         emit(const LoginProfileError('Name must contain only alphabets!'));
//         return;
//       }

//       // Validate the phone number
//       if (!RegExp(r'^\d{10}$').hasMatch(event.phoneNumber)) {
//         emit(const LoginProfileError('Phone number must be exactly 10 digits!'));
//         return;
//       }

//       // Validate that all fields are filled
//       if (event.name.isEmpty ||
//           event.address.isEmpty ||
//           event.phoneNumber.isEmpty) {
//         emit(const LoginProfileError('Please fill all the fields!'));
//         return;
//       }

//       // Assuming the user is authenticated and ready to save their profile
//       final user = await AuthService().getCurrentUser(); // Get current user (or authenticate if not done already)

//       if (user != null) {
//         // Create the UserModel and save to the database
//         await DatabaseService().create(UserModel(
//           id: user.uid, 
//           name: event.name,
//           email: user.email ?? '',
//           phone: event.phoneNumber,
//           address: event.address,
//         ));

//         log('Profile saved successfully');
//         emit(LoginProfileSuccess());
//       } else {
//         log('User not authenticated');
//         emit(const LoginProfileError('User not authenticated.'));
//       }
//     } catch (e) {
//       emit(LoginProfileError(errormessage: e.toString()));
//     }
//   }
// }
