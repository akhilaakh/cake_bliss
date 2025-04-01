abstract class TypeDetailsEvent {}

class FetchTypeDetailsEvent extends TypeDetailsEvent {
  final String typeId;

  FetchTypeDetailsEvent(this.typeId);
}

class CheckFavoriteStatusEvent extends TypeDetailsEvent {
  final String typeId;

  CheckFavoriteStatusEvent(this.typeId);
}

class ToggleFavoriteEvent extends TypeDetailsEvent {
  final String typeId;
  final Map<String, dynamic> typeData;
  final String categoryName;

  ToggleFavoriteEvent({
    required this.typeId,
    required this.typeData,
    required this.categoryName,
  });
}

class SelectWeightEvent extends TypeDetailsEvent {
  final String weight;

  SelectWeightEvent(this.weight);
}

class UpdateQuantityEvent extends TypeDetailsEvent {
  final int quantity;

  UpdateQuantityEvent(this.quantity);
}

class AddToCartEvent extends TypeDetailsEvent {
  final String typeId;
  final String categoryName;
  final Map<String, dynamic> typeData;
  final String selectedWeight;
  final int quantity;
  final double calculatedPrice;

  AddToCartEvent({
    required this.typeId,
    required this.categoryName,
    required this.typeData,
    required this.selectedWeight,
    required this.quantity,
    required this.calculatedPrice,
  });
}
