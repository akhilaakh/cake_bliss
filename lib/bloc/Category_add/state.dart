import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class CategoryState extends Equatable {
  const CategoryState();

  @override
  List<Object?> get props => [];
}

class CategoryInitial extends CategoryState {}

class CategoryImagePicked extends CategoryState {
  final File imageFile;

  const CategoryImagePicked({required this.imageFile});

  @override
  List<Object> get props => [imageFile];
}

class CategorySaving extends CategoryState {}

class CategorySaved extends CategoryState {
  final String message;

  const CategorySaved({required this.message});

  @override
  List<Object> get props => [message];
}

class CategoryDeleting extends CategoryState {}

class CategoryDeleted extends CategoryState {
  final String message;

  const CategoryDeleted({required this.message});

  @override
  List<Object> get props => [message];
}

class CategoryError extends CategoryState {
  final String error;

  const CategoryError({required this.error});

  @override
  List<Object> get props => [error];
}

class CategoriesLoading extends CategoryState {}

class CategoriesLoaded extends CategoryState {
  final List<Map<String, dynamic>> categories;

  const CategoriesLoaded({required this.categories});

  @override
  List<Object> get props => [categories];
}

class CategoryUpdating extends CategoryState {}

class CategoryUpdated extends CategoryState {
  final String message;

  const CategoryUpdated({required this.message});

  @override
  List<Object> get props => [message];
}
