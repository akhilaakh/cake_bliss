import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object?> get props => [];
}

class LoginInitial extends LoginState {}

class LoginLoading extends LoginState {}

class LoginSuccess extends LoginState {
  final User admin;

  const LoginSuccess({required this.admin});

  @override
  List<Object> get props => [admin];
}

class LoginFailure extends LoginState {
  final String errormessage;

  const LoginFailure({required this.errormessage});

  @override
  List<Object> get props => [errormessage];
}

class ForgotPasswordSent extends LoginState {
  final String message;

  const ForgotPasswordSent({required this.message});

  @override
  List<Object> get props => [message];
}

class ForgotPasswordFailure extends LoginState {
  final String error;

  const ForgotPasswordFailure({required this.error});

  @override
  List<Object> get props => [error];
}

class UserAuthenticated extends LoginState {
  final User user;

  const UserAuthenticated({required this.user});

  @override
  List<Object> get props => [user];
}

class UserUnauthenticated extends LoginState {}
