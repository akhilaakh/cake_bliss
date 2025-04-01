import 'package:equatable/equatable.dart';

abstract class SigninState extends Equatable {
  SigninState();
  @override
  List<Object> get props => [];
}

class SigninInitial extends SigninState {
  SigninInitial();
  @override
  List<Object> get props => [];
}

class SigninSuccess extends SigninState {
  SigninSuccess();
  @override
  List<Object> get props => [];
}

class SigninLoading extends SigninState {
  SigninLoading();
  @override
  List<Object> get props => [];
}

class SigninFailure extends SigninState {
  final String errormessage;
  SigninFailure({required this.errormessage});
  @override
  List<Object> get props => [];
}
