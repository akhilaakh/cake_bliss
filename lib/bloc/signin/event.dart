import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class SigninEvent extends Equatable {
  SigninEvent();
  List<Object> get props => [];
}

class SignButtonClick extends SigninEvent {
  final String name;
  final String email;
  final String password;
  final String phone;
  final String address;
  final BuildContext context;
  SignButtonClick(
      {required this.name,
      required this.email,
      required this.password,
      required this.phone,
      required this.address,
      required this.context});
  List<Object> get props => [
        name,
        email,
        password,
        address,
        context,
      ];
}
