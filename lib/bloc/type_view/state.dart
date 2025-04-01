abstract class TypeViewState {}

class TypeViewInitial extends TypeViewState {}

class TypeViewLoading extends TypeViewState {}

class TypeViewLoaded extends TypeViewState {
  final List<Map<String, dynamic>> types;
  final List<String> typeIds;

  TypeViewLoaded({required this.types, required this.typeIds});
}

class TypeViewError extends TypeViewState {
  final String message;

  TypeViewError({required this.message});
}
