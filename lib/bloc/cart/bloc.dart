// import 'package:bloc/bloc.dart';
// import 'package:equatable/equatable.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// part 'cart_event.dart';
// part 'cart_state.dart';

// class CartBloc extends Bloc<CartEvent, CartState> {
//   final FirebaseFirestore _firestore;
//   final FirebaseAuth _auth;

//   CartBloc({
//     FirebaseFirestore? firestore,
//     FirebaseAuth? auth,
//   })  : _firestore = firestore ?? FirebaseFirestore.instance,
//         _auth = auth ?? FirebaseAuth.instance,
//         super(CartInitialState()) {
//     // Register event handlers
//     on<LoadCartEvent>(_onLoadCart);
//     on<UpdateCartItemQuantityEvent>(_onUpdateCartItemQuantity);
//     on<RemoveCartItemEvent>(_onRemoveCartItem);
//   }

//   Future<void> _onLoadCart(
//     LoadCartEvent event, 
//     Emitter<CartState> emit
//   ) async {
//     emit(CartLoadingState());
    
//     try {
//       final user = _auth.currentUser;
//       if (user == null) {
//         emit(CartErrorState('User not authenticated'));
//         return;
//       }

//       final cartRef = _firestore
//           .collection('carts')
//           .doc(user.uid)
//           .collection('items');

//       final querySnapshot = await cartRef
//           .orderBy('addedAt', descending: true)
//           .get();

//       if (querySnapshot.docs.isEmpty) {
//         emit(CartEmptyState());
//         return;
//       }

//       final cartItems = querySnapshot.docs.map((doc) {
//         return CartItemModel.fromFirestore(doc);
//       }).toList();

//       final total = cartItems.fold(
//         0.0, 
//         (sum, item) => sum + item.totalPrice
//       );

//       emit(CartLoadedState(
//         items: cartItems, 
//         total: total
//       ));
//     } catch (e) {
//       emit(CartErrorState(e.toString()));
//     }
//   }

//   Future<void> _onUpdateCartItemQuantity(
//     UpdateCartItemQuantityEvent event, 
//     Emitter<CartState> emit
//   ) async {
//     try {
//       final user = _auth.currentUser;
//       if (user == null) return;

//       if (event.newQuantity < 1) return;

//       await _firestore
//           .collection('carts')
//           .doc(user.uid)
//           .collection('items')
//           .doc(event.docId)
//           .update({
//         'quantity': event.newQuantity,
//         'totalPrice': event.price * event.newQuantity,
//       });

//       add(LoadCartEvent()); // Reload cart after update
//     } catch (e) {
//       emit(CartErrorState('Failed to update quantity: $e'));
//     }
//   }

//   Future<void> _onRemoveCartItem(
//     RemoveCartItemEvent event, 
//     Emitter<CartState> emit
//   ) async {
//     try {
//       final user = _auth.currentUser;
//       if (user == null) return;

//       await _firestore
//           .collection('carts')
//           .doc(user.uid)
//           .collection('items')
//           .doc(event.docId)
//           .delete();

//       add(LoadCartEvent()); // Reload cart after removal
//     } catch (e) {
//       emit(CartErrorState('Failed to remove item: $e'));
//     }
//   }
// }