import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cake_bliss/category/fetchcategory.dart';
import 'package:cake_bliss/services/auth_service.dart';
import 'package:equatable/equatable.dart';

// Events
abstract class HomeEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadCategoriesEvent extends HomeEvent {}

class CategoriesLoadedEvent extends HomeEvent {
  final List<Category> categories;

  CategoriesLoadedEvent(this.categories);

  @override
  List<Object?> get props => [categories];
}

class SearchCategoriesEvent extends HomeEvent {
  final String query;

  SearchCategoriesEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class ClearSearchEvent extends HomeEvent {}

class CustomizeCakeEvent extends HomeEvent {}

class NavigateToPageEvent extends HomeEvent {
  final String page;

  NavigateToPageEvent(this.page);

  @override
  List<Object?> get props => [page];
}

class SignOutEvent extends HomeEvent {}
