import 'package:bloc/bloc.dart';
import 'package:cake_bliss/bloc/type_details/event.dart';
import 'package:cake_bliss/bloc/type_details/state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TypeDetailsBloc extends Bloc<TypeDetailsEvent, TypeDetailsState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  TypeDetailsBloc() : super(TypeDetailsInitial()) {
    on<FetchTypeDetailsEvent>(_onFetchTypeDetails);
    on<CheckFavoriteStatusEvent>(_onCheckFavoriteStatus);
    on<ToggleFavoriteEvent>(_onToggleFavorite);
    on<SelectWeightEvent>(_onSelectWeight);
    on<UpdateQuantityEvent>(_onUpdateQuantity);
    on<AddToCartEvent>(_onAddToCart);
  }

  Future<void> _onFetchTypeDetails(
    FetchTypeDetailsEvent event,
    Emitter<TypeDetailsState> emit,
  ) async {
    emit(TypeDetailsLoading());

    try {
      final doc = await _firestore.collection('types').doc(event.typeId).get();

      if (doc.exists) {
        final typeData = doc.data() as Map<String, dynamic>;
        emit(TypeDetailsLoaded(typeData: typeData));

        // Check favorite status after loading type data
        add(CheckFavoriteStatusEvent(event.typeId));
      } else {
        emit(TypeDetailsError('Type not found'));
      }
    } catch (e) {
      emit(TypeDetailsError('Error fetching type data: $e'));
    }
  }

  Future<void> _onCheckFavoriteStatus(
    CheckFavoriteStatusEvent event,
    Emitter<TypeDetailsState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is TypeDetailsLoaded) {
        final userId = _auth.currentUser?.uid;
        bool isFavorite = false;

        if (userId != null) {
          final doc = await _firestore
              .collection('favorites')
              .doc(userId)
              .collection('items')
              .doc(event.typeId)
              .get();

          isFavorite = doc.exists;
        }

        emit(currentState.copyWith(isFavorite: isFavorite));
      }
    } catch (e) {
      print('Error checking favorite status: $e');
      // Don't change state on error, just log it
    }
  }

  Future<void> _onToggleFavorite(
    ToggleFavoriteEvent event,
    Emitter<TypeDetailsState> emit,
  ) async {
    final currentState = state;
    if (currentState is TypeDetailsLoaded) {
      final userId = _auth.currentUser?.uid;

      if (userId == null) {
        emit(TypeDetailsError('Please login to add favorites'));
        emit(currentState); // Return to loaded state
        return;
      }

      try {
        final favoriteRef = _firestore
            .collection('favorites')
            .doc(userId)
            .collection('items')
            .doc(event.typeId);

        final bool newFavoriteStatus = !currentState.isFavorite;

        // Update UI immediately
        emit(currentState.copyWith(isFavorite: newFavoriteStatus));

        if (newFavoriteStatus) {
          // Add to favorites
          await favoriteRef.set({
            'typeId': event.typeId,
            'name': event.typeData['name'],
            'image': event.typeData['images'].isNotEmpty
                ? event.typeData['images'][0]
                : '',
            'price': event.typeData['rate'],
            'categoryName': event.categoryName,
            'addedAt': FieldValue.serverTimestamp(),
          });

          emit(FavoriteToggleSuccess(true));
        } else {
          // Remove from favorites
          await favoriteRef.delete();

          emit(FavoriteToggleSuccess(false));
        }

        // Return to loaded state with updated favorite status
        emit(currentState.copyWith(isFavorite: newFavoriteStatus));
      } catch (e) {
        print('Error toggling favorite: $e');

        // Revert the state if operation failed
        emit(currentState.copyWith(isFavorite: !currentState.isFavorite));
        emit(TypeDetailsError('Failed to update favorites. Please try again.'));
        emit(currentState.copyWith(
            isFavorite: !currentState.isFavorite)); // Return to loaded state
      }
    }
  }

  void _onSelectWeight(
    SelectWeightEvent event,
    Emitter<TypeDetailsState> emit,
  ) {
    final currentState = state;
    if (currentState is TypeDetailsLoaded) {
      // Remove 'kg' and safely parse the weight value
      double weightValue =
          double.tryParse(event.weight.replaceAll('kg', '').trim()) ?? 0.0;

      // Ensure base rate is correctly retrieved
      double baseRate =
          double.tryParse(currentState.typeData['rate'].toString()) ?? 0.0;

      // Calculate price
      double calculatedPrice = baseRate * weightValue * currentState.quantity;

      emit(currentState.copyWith(
        selectedWeight: event.weight,
        calculatedPrice: calculatedPrice,
      ));
    }
  }

  void _onUpdateQuantity(
    UpdateQuantityEvent event,
    Emitter<TypeDetailsState> emit,
  ) {
    final currentState = state;
    if (currentState is TypeDetailsLoaded) {
      // Ensure we have a valid quantity (minimum 1)
      int newQuantity = event.quantity > 0 ? event.quantity : 1;

      // Recalculate price if weight is selected
      double calculatedPrice = currentState.calculatedPrice;
      if (currentState.selectedWeight != null) {
        double weightValue = double.tryParse(
                currentState.selectedWeight!.replaceAll('kg', '').trim()) ??
            0.0;

        double baseRate =
            double.tryParse(currentState.typeData['rate'].toString()) ?? 0.0;

        calculatedPrice = baseRate * weightValue * newQuantity;
      }

      emit(currentState.copyWith(
        quantity: newQuantity,
        calculatedPrice: calculatedPrice,
      ));
    }
  }

  Future<void> _onAddToCart(
    AddToCartEvent event,
    Emitter<TypeDetailsState> emit,
  ) async {
    final currentState = state;
    if (currentState is TypeDetailsLoaded) {
      if (event.selectedWeight == null) {
        emit(TypeDetailsError('Please select a weight first'));
        emit(currentState); // Return to loaded state
        return;
      }

      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        emit(TypeDetailsError('Please login to add items to cart'));
        emit(currentState); // Return to loaded state
        return;
      }

      try {
        // Reference to user's cart
        final cartRef =
            _firestore.collection('carts').doc(userId).collection('items');

        // Check if item already exists in cart
        final existingItem = await cartRef
            .where('typeId', isEqualTo: event.typeId)
            .where('weight', isEqualTo: event.selectedWeight)
            .get();

        if (existingItem.docs.isNotEmpty) {
          // Update quantity if item exists
          final doc = existingItem.docs.first;
          await cartRef.doc(doc.id).update({
            'quantity': FieldValue.increment(event.quantity),
            'totalPrice': (event.calculatedPrice * event.quantity) +
                (doc.data()['totalPrice'] as num),
          });
        } else {
          // Add new item to cart
          await cartRef.add({
            'typeId': event.typeId,
            'name': event.typeData['name'],
            'categoryName': event.categoryName,
            'image': event.typeData['images'][0],
            'weight': event.selectedWeight,
            'quantity': event.quantity,
            'price': event.calculatedPrice,
            'totalPrice': event.calculatedPrice * event.quantity,
            'addedAt': FieldValue.serverTimestamp(),
          });
        }

        emit(AddToCartSuccess());
        emit(currentState); // Return to loaded state
      } catch (e) {
        print('Error adding to cart: $e');
        emit(AddToCartError('Failed to add to cart. Please try again.'));
        emit(currentState); // Return to loaded state
      }
    }
  }
}
