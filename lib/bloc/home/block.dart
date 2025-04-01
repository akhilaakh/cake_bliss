import 'dart:async';

import 'package:cake_bliss/bloc/home/event.dart';
import 'package:cake_bliss/bloc/home/state.dart';
import 'package:cake_bliss/category/fetchcategory.dart';
import 'package:cake_bliss/services/auth_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final AuthService _authService;
  final FirestoreService _firestoreService;
  StreamSubscription? _categoriesSubscription;
  List<Category> _allCategories = [];

  HomeBloc({
    required AuthService authService,
    required FirestoreService firestoreService,
  })  : _authService = authService,
        _firestoreService = firestoreService,
        super(HomeInitialState()) {
    on<LoadCategoriesEvent>(_onLoadCategories);
    on<CategoriesLoadedEvent>(_onCategoriesLoaded);
    on<SearchCategoriesEvent>(_onSearchCategories);
    on<ClearSearchEvent>(_onClearSearch);
    on<CustomizeCakeEvent>(_onCustomizeCake);
    on<NavigateToPageEvent>(_onNavigateToPage);
    on<SignOutEvent>(_onSignOut);
  }

  void _onLoadCategories(LoadCategoriesEvent event, Emitter<HomeState> emit) {
    emit(HomeLoadingState());

    _categoriesSubscription?.cancel();
    _categoriesSubscription = _firestoreService.fetchCategories().listen(
      (categories) {
        _allCategories = categories;
        add(CategoriesLoadedEvent(categories));
      },
      onError: (error) {
        emit(HomeErrorState('Failed to load categories: $error'));
      },
    );
  }

  void _onCategoriesLoaded(
      CategoriesLoadedEvent event, Emitter<HomeState> emit) {
    emit(HomeCategoriesLoadedState(
      categories: event.categories,
      filteredCategories: event.categories,
    ));
  }

  void _onSearchCategories(
      SearchCategoriesEvent event, Emitter<HomeState> emit) {
    final currentState = state;

    if (currentState is HomeCategoriesLoadedState) {
      final query = event.query;

      if (query.isEmpty) {
        emit(currentState.copyWith(
          filteredCategories: currentState.categories,
          isSearching: false,
        ));
        return;
      }

      final filteredList = currentState.categories.where((category) {
        return category.name.toLowerCase().contains(query.toLowerCase());
      }).toList();

      emit(currentState.copyWith(
        filteredCategories: filteredList,
        isSearching: true,
      ));
    }
  }

  void _onClearSearch(ClearSearchEvent event, Emitter<HomeState> emit) {
    if (state is HomeCategoriesLoadedState) {
      final currentState = state as HomeCategoriesLoadedState;
      emit(currentState.copyWith(
        filteredCategories: currentState.categories,
        isSearching: false,
      ));
    }
  }

  void _onCustomizeCake(CustomizeCakeEvent event, Emitter<HomeState> emit) {
    emit(ShowCustomizationDialogState());
  }

  void _onNavigateToPage(NavigateToPageEvent event, Emitter<HomeState> emit) {
    if (event.page == 'Sign Out') {
      emit(ConfirmSignOutState());
    } else {
      emit(NavigateToPageState(event.page));
    }
  }

  void _onSignOut(SignOutEvent event, Emitter<HomeState> emit) async {
    try {
      await _authService.signout();
      emit(SignOutSuccessState());
    } catch (e) {
      emit(HomeErrorState('Failed to sign out: $e'));
    }
  }

  @override
  Future<void> close() {
    _categoriesSubscription?.cancel();
    return super.close();
  }
}
