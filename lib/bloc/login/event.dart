import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object?> get props => [];
}

class LoginButtonClick extends LoginEvent {
  final String email;
  final String password;
  final BuildContext context;

  const LoginButtonClick({
    required this.email,
    required this.password,
    required this.context,
  });

  @override
  List<Object> get props => [email, password, context];
}

class LogoutEvent extends LoginEvent {}

class ForgotPasswordEvent extends LoginEvent {
  final String email;

  const ForgotPasswordEvent({required this.email});

  @override
  List<Object> get props => [email];
}

class CheckAuthStatusEvent extends LoginEvent {}
