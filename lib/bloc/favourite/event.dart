import 'package:equatable/equatable.dart';

abstract class FavouriteEvent extends Equatable {
  const FavouriteEvent();

  @override
  List<Object?> get props => [];
}

class LoadFavorites extends FavouriteEvent {}

class RemoveFavorite extends FavouriteEvent {
  final String docId;

  const RemoveFavorite({required this.docId});

  @override
  List<Object?> get props => [docId];
}
