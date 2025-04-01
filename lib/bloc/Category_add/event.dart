import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class CategoryEvent extends Equatable {
  const CategoryEvent();

  @override
  List<Object?> get props => [];
}

class PickImageEvent extends CategoryEvent {}

class SaveCategoryEvent extends CategoryEvent {
  final String categoryName;
  final File imageFile;

  const SaveCategoryEvent({
    required this.categoryName,
    required this.imageFile,
  });

  @override
  List<Object> get props => [categoryName, imageFile];
}

class DeleteCategoryEvent extends CategoryEvent {
  final String categoryId;
  final String? imageUrl;

  const DeleteCategoryEvent({
    required this.categoryId,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [categoryId, imageUrl];
}

class FetchCategoriesEvent extends CategoryEvent {}

class UpdateCategoryEvent extends CategoryEvent {
  final String categoryId;
  final String categoryName;
  final File? newImageFile;
  final String? currentImageUrl;

  const UpdateCategoryEvent({
    required this.categoryId,
    required this.categoryName,
    this.newImageFile,
    this.currentImageUrl,
  });

  @override
  List<Object?> get props =>
      [categoryId, categoryName, newImageFile, currentImageUrl];
}
