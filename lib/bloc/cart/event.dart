// part of 'cart_bloc.dart';

// abstract class CartEvent extends Equatable {
//   const CartEvent();

//   @override
//   List<Object> get props => [];
// }

// class LoadCartEvent extends CartEvent {}

// class UpdateCartItemQuantityEvent extends CartEvent {
//   final String docId;
//   final int newQuantity;
//   final double price;

//   const UpdateCartItemQuantityEvent({
//     required this.docId,
//     required this.newQuantity,
//     required this.price,
//   });

//   @override
//   List<Object> get props => [docId, newQuantity, price];
// }

// class RemoveCartItemEvent extends CartEvent {
//   final String docId;

//   const RemoveCartItemEvent({required this.docId});

//   @override
//   List<Object> get props => [docId];
// }