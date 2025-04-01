// import 'package:bloc/bloc.dart';
// import 'package:cake_bliss/Bloc/login/event.dart';
// import 'package:cake_bliss/Bloc/login/state.dart';
// import 'package:cake_bliss/loginpage.dart';

// class Loginbloc extends Bloc<LoginEvent, LoginState> {
//   Loginbloc() : super(LoginInitial()) {
//     on<LoginButtonClick>(login);
//   }

//   Future<void> login(LoginButtonClick event, Emitter<LoginState> emit) async {
//     emit(LoginLoading());
//     try {
//       await loginn(event.email, event.password, event.context);
//       emit(LoginSuccess());
//     } catch (e) {
//       emit(LoginFailure(errormessage: e.toString()));
//     }
//   }
// }

import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:cake_bliss/Bloc/signup/event.dart';
import 'package:cake_bliss/Bloc/signup/state.dart';
import 'package:cake_bliss/databaseServices/database_service.dart';
import 'package:cake_bliss/model/user_model.dart';
import 'package:cake_bliss/services/auth_service.dart';

class Signinbloc extends Bloc<SigninEvent, SigninState> {
  Signinbloc() : super(SigninInitial()) {
    on<SignButtonClick>(Signin);
  }

  Future<void> Signin(SignButtonClick event, Emitter<SigninState> emit) async {
    emit(SigninLoading());
    try {
      final user = await AuthService()
          .createUserWithEmailAndPassword(event.email, event.password);

      if (user != null) {
        DatabaseService().create(UserModel(
            id: user.uid, // Use Firebase user's unique ID
            name: event.name,
            email: user.email ?? '',
            phone: event.phone,
            address: event.address,
            password: event.password,
            imageUrl: event.imageUrl ?? ''));
        log('Login successful');
        emit(SigninSuccess());
      } else {
        log('Invalid email or password');
        emit(SigninFailure(errormessage: 'Invalid email or password'));
      }
    } catch (e) {
      emit(SigninFailure(errormessage: e.toString()));
    }
  }
}
