import 'package:equatable/equatable.dart';

abstract class CategoryTypesEvent extends Equatable {
  const CategoryTypesEvent();

  @override
  List<Object?> get props => [];
}

class FetchCategoryTypes extends CategoryTypesEvent {
  final String categoryName;

  const FetchCategoryTypes({required this.categoryName});

  @override
  List<Object?> get props => [categoryName];
}
