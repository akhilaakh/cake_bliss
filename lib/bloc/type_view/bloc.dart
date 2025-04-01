import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cake_bliss/bloc/type_view/event.dart';
import 'package:cake_bliss/bloc/type_view/state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TypeViewBloc extends Bloc<TypeViewEvent, TypeViewState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TypeViewBloc() : super(TypeViewInitial()) {
    on<LoadTypesEvent>(_onLoadTypes);
  }

  Future<void> _onLoadTypes(
      LoadTypesEvent event, Emitter<TypeViewState> emit) async {
    emit(TypeViewLoading());

    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('types')
          .where('category', isEqualTo: event.categoryName)
          .get();

      if (snapshot.docs.isEmpty) {
        emit(TypeViewLoaded(types: [], typeIds: []));
        return;
      }

      final List<Map<String, dynamic>> types = [];
      final List<String> typeIds = [];

      for (var doc in snapshot.docs) {
        types.add(doc.data() as Map<String, dynamic>);
        typeIds.add(doc.id);
      }

      emit(TypeViewLoaded(types: types, typeIds: typeIds));
    } catch (e) {
      emit(TypeViewError(message: 'Failed to load types: ${e.toString()}'));
    }
  }
}
