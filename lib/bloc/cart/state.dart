// part of 'cart_bloc.dart';

// abstract class CartState extends Equatable {
//   const CartState();
  
//   @override
//   List<Object> get props => [];
// }

// class CartInitialState extends CartState {}

// class CartLoadingState extends CartState {}

// class CartEmptyState extends CartState {}

// class CartLoadedState extends CartState {
//   final List<CartItemModel> items;
//   final double total;

//   const CartLoadedState({
//     required this.items,
//     required this.total,
//   });

//   @override
//   List<Object> get props => [items, total];
// }

// class CartErrorState extends CartState {
//   final String message;

//   const CartErrorState(this.message);

//   @override
//   List<Object> get props => [message];
// }

// class CartItemModel extends Equatable {
//   final String docId;
//   final String name;
//   final String categoryName;
//   final String image;
//   final String weight;
//   final double price;
//   final int quantity;
//   final double totalPrice;

//   const CartItemModel({
//     required this.docId,
//     required this.name,
//     required this.categoryName,
//     required this.image,
//     required this.weight,
//     required this.price,
//     required this.quantity,
//     required this.totalPrice,
//   });

//   factory CartItemModel.fromFirestore(DocumentSnapshot doc) {
//     final data = doc.data() as Map<String, dynamic>;
//     return CartItemModel(
//       docId: doc.id,
//       name: data['name'] ?? '',
//       categoryName: data['categoryName'] ?? '',
//       image: data['image'] ?? '',
//       weight: data['weight'] ?? '',
//       price: (data['price'] ?? 0.0).toDouble(),
//       quantity: data['quantity'] ?? 0,
//       totalPrice: (data['totalPrice'] ?? 0.0).toDouble(),
//     );
//   }

//   @override
//   List<Object> get props => [
//         docId,
//         name,
//         categoryName,
//         image,
//         weight,
//         price,
//         quantity,
//         totalPrice,
//       ];
// }