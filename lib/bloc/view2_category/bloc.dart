import 'dart:developer';
import 'package:bloc/bloc.dart';
import 'package:cakebliss_admin/bloc/view2_category/event.dart';
import 'package:cakebliss_admin/bloc/view2_category/state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class CategoryTypesBloc extends Bloc<CategoryTypesEvent, CategoryTypesState> {
  final FirebaseFirestore _firestore;

  CategoryTypesBloc({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        super(CategoryTypesInitial()) {
    on<FetchCategoryTypes>(_onFetchCategoryTypes);
  }

  Future<void> _onFetchCategoryTypes(
    FetchCategoryTypes event,
    Emitter<CategoryTypesState> emit,
  ) async {
    try {
      emit(CategoryTypesLoading());

      log('Fetching types for category: ${event.categoryName}');
      final QuerySnapshot snapshot = await _firestore
          .collection('types')
          .where('category', isEqualTo: event.categoryName)
          .get();

      log('Fetched ${snapshot.docs.length} types for category: ${event.categoryName}');
      emit(CategoryTypesLoaded(types: snapshot.docs));
    } catch (error) {
      log('Error fetching types: $error');
      emit(CategoryTypesError(message: error.toString()));
    }
  }
}
