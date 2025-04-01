abstract class TypeDetailsState {}

class TypeDetailsInitial extends TypeDetailsState {}

class TypeDetailsLoading extends TypeDetailsState {}

class TypeDetailsLoaded extends TypeDetailsState {
  final Map<String, dynamic> typeData;
  final bool isFavorite;
  final String? selectedWeight;
  final double calculatedPrice;
  final int quantity;

  TypeDetailsLoaded({
    required this.typeData,
    this.isFavorite = false,
    this.selectedWeight,
    this.calculatedPrice = 0.0,
    this.quantity = 1,
  });

  TypeDetailsLoaded copyWith({
    Map<String, dynamic>? typeData,
    bool? isFavorite,
    String? selectedWeight,
    double? calculatedPrice,
    int? quantity,
  }) {
    return TypeDetailsLoaded(
      typeData: typeData ?? this.typeData,
      isFavorite: isFavorite ?? this.isFavorite,
      selectedWeight: selectedWeight ?? this.selectedWeight,
      calculatedPrice: calculatedPrice ?? this.calculatedPrice,
      quantity: quantity ?? this.quantity,
    );
  }
}

class TypeDetailsError extends TypeDetailsState {
  final String message;

  TypeDetailsError(this.message);
}

class FavoriteToggleSuccess extends TypeDetailsState {
  final bool isFavorite;

  FavoriteToggleSuccess(this.isFavorite);
}

class AddToCartSuccess extends TypeDetailsState {}

class AddToCartError extends TypeDetailsState {
  final String message;

  AddToCartError(this.message);
}
