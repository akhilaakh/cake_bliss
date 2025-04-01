import 'package:bloc/bloc.dart';
import 'package:cake_bliss/bloc/favourite/event.dart';
import 'package:cake_bliss/bloc/favourite/state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavouriteBloc extends Bloc<FavouriteEvent, FavouriteState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FavouriteBloc() : super(FavouriteInitial()) {
    on<LoadFavorites>(_onLoadFavorites);
    on<RemoveFavorite>(_onRemoveFavorite);
  }

  Future<void> _onLoadFavorites(
      LoadFavorites event, Emitter<FavouriteState> emit) async {
    emit(FavouriteLoading());
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final favorites = await _firestore
          .collection('favorites')
          .doc(userId)
          .collection('items')
          .orderBy('addedAt', descending: true)
          .get();

      emit(FavouriteLoaded(favorites: favorites.docs));
    } catch (e) {
      emit(FavouriteError(message: 'Failed to load favorites: $e'));
    }
  }

  Future<void> _onRemoveFavorite(
      RemoveFavorite event, Emitter<FavouriteState> emit) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore
          .collection('favorites')
          .doc(userId)
          .collection('items')
          .doc(event.docId)
          .delete();

      add(LoadFavorites());
    } catch (e) {
      emit(FavouriteError(message: 'Failed to remove favorite: $e'));
    }
  }
}
