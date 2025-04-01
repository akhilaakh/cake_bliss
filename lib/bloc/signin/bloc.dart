import 'dart:developer';

import 'package:bloc/bloc.dart';

import 'package:cakebliss_admin/bloc/signin/event.dart';
import 'package:cakebliss_admin/bloc/signin/state.dart';
import 'package:cakebliss_admin/databaseservices/auth_service.dart';
import 'package:cakebliss_admin/databaseservices/database.dart';
import 'package:cakebliss_admin/model/usermodel.dart';

class Signinbloc extends Bloc<SigninEvent, SigninState> {
  Signinbloc() : super(SigninInitial()) {
    on<SignButtonClick>(Signin);
  }

  Future<void> Signin(SignButtonClick event, Emitter<SigninState> emit) async {
    emit(SigninLoading());
    try {
      final admin = await AuthService()
          .createUserWithEmailAndPassword(event.email, event.password);

      if (admin != null) {
        DatabaseService().create(AdminModel(
            id: admin.uid, // Use Firebase user's unique ID
            name: event.name,
            email: admin.email ?? '',
            phone: event.phone,
            address: event.address,
            password: event.password));
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
