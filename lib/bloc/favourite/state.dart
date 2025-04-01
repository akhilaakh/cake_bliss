import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class FavouriteState extends Equatable {
  const FavouriteState();

  @override
  List<Object?> get props => [];
}

class FavouriteInitial extends FavouriteState {}

class FavouriteLoading extends FavouriteState {}

class FavouriteLoaded extends FavouriteState {
  final List<QueryDocumentSnapshot> favorites;

  const FavouriteLoaded({required this.favorites});

  @override
  List<Object?> get props => [favorites];
}

class FavouriteError extends FavouriteState {
  final String message;

  const FavouriteError({required this.message});

  @override
  List<Object?> get props => [message];
}
