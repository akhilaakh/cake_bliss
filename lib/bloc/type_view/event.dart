abstract class TypeViewEvent {}

class LoadTypesEvent extends TypeViewEvent {
  final String categoryName;

  LoadTypesEvent({required this.categoryName});
}
