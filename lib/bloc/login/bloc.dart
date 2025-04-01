import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:cake_bliss/Bloc/login/event.dart';
import 'package:cake_bliss/Bloc/login/state.dart';
import 'package:cake_bliss/services/auth_service.dart';

class Loginbloc extends Bloc<LoginEvent, LoginState> {
  Loginbloc() : super(LoginInitial()) {
    on<LoginButtonClick>(login);
  }

  Future<void> login(LoginButtonClick event, Emitter<LoginState> emit) async {
    emit(LoginLoading());
    try {
      final user = await AuthService()
          .loginUserWithEmailAndPassword(event.email, event.password);

      if (user != null) {
        log('Login successful');
        emit(LoginSuccess());
      } else {
        log('Invalid email or password');
        emit(LoginFailure(errormessage: 'Invalid email or password'));
      }
    } catch (e) {
      log('failed');
      log(e.toString());
      emit(LoginFailure(errormessage: e.toString()));
    }
  }
}
