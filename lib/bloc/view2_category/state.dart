import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class CategoryTypesState extends Equatable {
  const CategoryTypesState();

  @override
  List<Object?> get props => [];
}

class CategoryTypesInitial extends CategoryTypesState {}

class CategoryTypesLoading extends CategoryTypesState {}

class CategoryTypesLoaded extends CategoryTypesState {
  final List<QueryDocumentSnapshot> types;

  const CategoryTypesLoaded({required this.types});

  @override
  List<Object?> get props => [types];
}

class CategoryTypesError extends CategoryTypesState {
  final String message;

  const CategoryTypesError({required this.message});

  @override
  List<Object?> get props => [message];
}
