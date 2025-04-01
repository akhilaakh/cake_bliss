// import 'package:cake_bliss/model/user_model.dart';
// import 'package:equatable/equatable.dart';

// abstract class ProfileState extends Equatable {
//   const ProfileState();

//   @override
//   List<Object?> get props => [];
// }

// class ProfileInitial extends ProfileState {
//   const ProfileInitial();

//   @override
//   List<Object> get props => [];
// }

// class ProfileLoading extends ProfileState {
//   const ProfileLoading();

//   @override
//   List<Object> get props => [];
// }

// class ProfileLoaded extends ProfileState {
//   final UserModel user;

//   const ProfileLoaded(this.user);

//   @override
//   List<Object> get props => [user];
// }

// class ProfileError extends ProfileState {
//   final String message;

//   const ProfileError(this.message);

//   @override
//   List<Object> get props => [message];
// }
// lib/Bloc/profile/state.dart

import 'package:cake_bliss/model/user_model.dart';
import 'package:equatable/equatable.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  final UserModel user;

  const ProfileLoaded(this.user);

  @override
  List<Object> get props => [user];
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);

  @override
  List<Object> get props => [message];
}

class ProfileUpdateSuccess extends ProfileState {
  const ProfileUpdateSuccess();
}
