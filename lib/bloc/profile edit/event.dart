import 'package:cake_bliss/model/user_model.dart';
import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class FetchProfileEvent extends ProfileEvent {
  const FetchProfileEvent();
}

class UpdateProfileEvent extends ProfileEvent {
  final UserModel user;

  const UpdateProfileEvent(this.user);

  @override
  List<Object?> get props => [user];
}
