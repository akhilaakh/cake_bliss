import 'dart:developer';
import 'package:cakebliss_admin/bloc/login/event.dart';
import 'package:cakebliss_admin/bloc/login/state.dart';
import 'package:cakebliss_admin/databaseservices/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Loginbloc extends Bloc<LoginEvent, LoginState> {
  final AuthService _authService = AuthService();

  Loginbloc() : super(LoginInitial()) {
    on<LoginButtonClick>(_onLoginButtonClick);
    on<LogoutEvent>(_onLogout);
  }

  Future<void> _onLoginButtonClick(
      LoginButtonClick event, Emitter<LoginState> emit) async {
    try {
      emit(LoginLoading());

      // Basic validation
      if (event.email.isEmpty || event.password.isEmpty) {
        emit(LoginFailure(errormessage: 'Email and password cannot be empty'));
        return;
      }

      // Email format validation
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(event.email)) {
        emit(LoginFailure(errormessage: 'Please enter a valid email address'));
        return;
      }

      // Authenticate user
      final admin = await _authService.loginUserWithEmailAndPassword(
          event.email, event.password);

      if (admin != null) {
        log("Admin logged in successfully: ${admin.email}");
        emit(LoginSuccess(admin: admin));
      } else {
        emit(LoginFailure(errormessage: 'Invalid email or password'));
      }
    } catch (e) {
      log("Login error: $e");
      emit(LoginFailure(errormessage: 'Login failed: ${e.toString()}'));
    }
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<LoginState> emit) async {
    try {
      emit(LoginLoading());
      await _authService.signout();
      emit(LoginInitial());
    } catch (e) {
      emit(LoginFailure(errormessage: 'Logout failed: ${e.toString()}'));
    }
  }
}
