// import 'package:equatable/equatable.dart';

// abstract class ProfileEvent extends Equatable {
//   const ProfileEvent();

//   @override
//   List<Object> get props => [];
// }

// class FetchProfileEvent extends ProfileEvent {
//   const FetchProfileEvent();

//   @override
//   List<Object> get props => [];
// }
// lib/Bloc/profile/event.dart

import 'package:equatable/equatable.dart';
import 'package:cake_bliss/model/user_model.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object> get props => [];
}

class FetchProfileEvent extends ProfileEvent {
  const FetchProfileEvent();

  @override
  List<Object> get props => [];
}

class UpdateProfileEvent extends ProfileEvent {
  final UserModel user;

  const UpdateProfileEvent(this.user);

  @override
  List<Object> get props => [user];
}
