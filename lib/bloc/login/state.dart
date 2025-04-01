import 'package:equatable/equatable.dart';

abstract class LoginState extends Equatable {
  LoginState();
  @override
  List<Object> get props => [];
}

class LoginInitial extends LoginState {
  LoginInitial();
  @override
  List<Object> get props => [];
}

class LoginSuccess extends LoginState {
  LoginSuccess();
  @override
  List<Object> get props => [];
}

class LoginLoading extends LoginState {
  LoginLoading();
  @override
  List<Object> get props => [];
}

class LoginFailure extends LoginState {
  final String errormessage;
  LoginFailure({required this.errormessage});
  @override
  List<Object> get props => [errormessage];
}
