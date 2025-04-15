import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class CategoryEvent extends Equatable {
  const CategoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadCategories extends CategoryEvent {}

class CreateCategory extends CategoryEvent {
  final String id;
  final String name;
  final File image;

  const CreateCategory({
    required this.id,
    required this.name,
    required this.image,
  });

  @override
  List<Object?> get props => [id, name, image];
}

class UpdateCategory extends CategoryEvent {
  final String id;
  final String name;
  final File? image;
  final String currentImageUrl;

  const UpdateCategory({
    required this.id,
    required this.name,
    this.image,
    required this.currentImageUrl,
  });

  @override
  List<Object?> get props => [id, name, image, currentImageUrl];
}

class DeleteCategory extends CategoryEvent {
  final String id;

  const DeleteCategory(this.id);

  @override
  List<Object> get props => [id];
}
