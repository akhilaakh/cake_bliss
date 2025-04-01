import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class LoginEvent extends Equatable {
  LoginEvent();
  @override
  List<Object> get props => [];
}

class LoginButtonClick extends LoginEvent {
  final String email;
  final String password;
  final BuildContext context;
  LoginButtonClick(
      {required this.email, required this.password, required this.context});
  @override
  List<Object> get props => [email, password, context];
}
