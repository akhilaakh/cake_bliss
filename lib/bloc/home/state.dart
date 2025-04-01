import 'package:cake_bliss/category/fetchcategory.dart';
import 'package:equatable/equatable.dart';

abstract class HomeState extends Equatable {
  @override
  List<Object?> get props => [];
}

class HomeInitialState extends HomeState {}

class HomeLoadingState extends HomeState {}

class HomeCategoriesLoadedState extends HomeState {
  final List<Category> categories;
  final List<Category> filteredCategories;
  final bool isSearching;

  HomeCategoriesLoadedState({
    required this.categories,
    required this.filteredCategories,
    this.isSearching = false,
  });

  @override
  List<Object?> get props => [categories, filteredCategories, isSearching];

  HomeCategoriesLoadedState copyWith({
    List<Category>? categories,
    List<Category>? filteredCategories,
    bool? isSearching,
  }) {
    return HomeCategoriesLoadedState(
      categories: categories ?? this.categories,
      filteredCategories: filteredCategories ?? this.filteredCategories,
      isSearching: isSearching ?? this.isSearching,
    );
  }
}

class HomeErrorState extends HomeState {
  final String message;

  HomeErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

class NavigateToCustomizationState extends HomeState {}

class NavigateToPageState extends HomeState {
  final String page;

  NavigateToPageState(this.page);

  @override
  List<Object?> get props => [page];
}

class ShowCustomizationDialogState extends HomeState {}

class SignOutSuccessState extends HomeState {}

class ConfirmSignOutState extends HomeState {}
