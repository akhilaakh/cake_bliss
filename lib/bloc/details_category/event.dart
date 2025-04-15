import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Events
abstract class TypeDetailsEvent extends Equatable {
  const TypeDetailsEvent();

  @override
  List<Object?> get props => [];
}

class FetchTypeDetails extends TypeDetailsEvent {
  final String typeId;

  const FetchTypeDetails(this.typeId);

  @override
  List<Object?> get props => [typeId];
}

class SelectWeight extends TypeDetailsEvent {
  final String weight;
  final double baseRate;

  const SelectWeight(this.weight, this.baseRate);

  @override
  List<Object?> get props => [weight, baseRate];
}

class ChangeImagePage extends TypeDetailsEvent {
  final int pageIndex;

  const ChangeImagePage(this.pageIndex);

  @override
  List<Object?> get props => [pageIndex];
}

class DeleteType extends TypeDetailsEvent {
  final String typeId;

  const DeleteType(this.typeId);

  @override
  List<Object?> get props => [typeId];
}

// States
abstract class TypeDetailsState extends Equatable {
  const TypeDetailsState();

  @override
  List<Object?> get props => [];
}

class TypeDetailsInitial extends TypeDetailsState {}

class TypeDetailsLoading extends TypeDetailsState {}

class TypeDetailsLoaded extends TypeDetailsState {
  final Map<String, dynamic> typeData;
  final String? selectedWeight;
  final double calculatedPrice;
  final double baseRate;
  final int currentPage;

  const TypeDetailsLoaded({
    required this.typeData,
    this.selectedWeight,
    this.calculatedPrice = 0.0,
    required this.baseRate,
    this.currentPage = 0,
  });

  @override
  List<Object?> get props =>
      [typeData, selectedWeight, calculatedPrice, baseRate, currentPage];

  TypeDetailsLoaded copyWith({
    Map<String, dynamic>? typeData,
    String? selectedWeight,
    double? calculatedPrice,
    double? baseRate,
    int? currentPage,
  }) {
    return TypeDetailsLoaded(
      typeData: typeData ?? this.typeData,
      selectedWeight: selectedWeight ?? this.selectedWeight,
      calculatedPrice: calculatedPrice ?? this.calculatedPrice,
      baseRate: baseRate ?? this.baseRate,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class TypeDetailsError extends TypeDetailsState {
  final String message;

  const TypeDetailsError(this.message);

  @override
  List<Object?> get props => [message];
}

class TypeDeleteSuccess extends TypeDetailsState {}

class TypeDeleteError extends TypeDetailsState {
  final String message;

  const TypeDeleteError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class TypeDetailsBloc extends Bloc<TypeDetailsEvent, TypeDetailsState> {
  final FirebaseFirestore _firestore;

  TypeDetailsBloc({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        super(TypeDetailsInitial()) {
    on<FetchTypeDetails>(_onFetchTypeDetails);
    on<SelectWeight>(_onSelectWeight);
    on<ChangeImagePage>(_onChangeImagePage);
    on<DeleteType>(_onDeleteType);
  }

  Future<void> _onFetchTypeDetails(
    FetchTypeDetails event,
    Emitter<TypeDetailsState> emit,
  ) async {
    emit(TypeDetailsLoading());
    try {
      final doc = await _firestore.collection('types').doc(event.typeId).get();

      if (doc.exists) {
        final typeData = doc.data() as Map<String, dynamic>;
        final baseRate = double.tryParse(typeData['rate'].toString()) ?? 0.0;

        emit(TypeDetailsLoaded(
          typeData: typeData,
          baseRate: baseRate,
        ));
      } else {
        emit(const TypeDetailsError('Type not found'));
      }
    } catch (e) {
      emit(TypeDetailsError('Error fetching type data: $e'));
    }
  }

  void _onSelectWeight(
    SelectWeight event,
    Emitter<TypeDetailsState> emit,
  ) {
    if (state is TypeDetailsLoaded) {
      final currentState = state as TypeDetailsLoaded;
      final double weightValue = double.tryParse(
            event.weight.replaceAll('kg', '').trim(),
          ) ??
          0.0;
      final double calculatedPrice = event.baseRate * weightValue;

      emit(currentState.copyWith(
        selectedWeight: event.weight,
        calculatedPrice: calculatedPrice,
      ));
    }
  }

  void _onChangeImagePage(
    ChangeImagePage event,
    Emitter<TypeDetailsState> emit,
  ) {
    if (state is TypeDetailsLoaded) {
      final currentState = state as TypeDetailsLoaded;
      emit(currentState.copyWith(currentPage: event.pageIndex));
    }
  }

  Future<void> _onDeleteType(
    DeleteType event,
    Emitter<TypeDetailsState> emit,
  ) async {
    try {
      await _firestore.collection('types').doc(event.typeId).delete();
      emit(TypeDeleteSuccess());
    } catch (e) {
      emit(TypeDeleteError('Error deleting type: $e'));
    }
  }
}
