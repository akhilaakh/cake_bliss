import 'package:equatable/equatable.dart';

abstract class StorageState extends Equatable {
  const StorageState();

  @override
  List<Object?> get props => [];
}

class StorageInitial extends StorageState {
  const StorageInitial();
}

class StorageLoading extends StorageState {
  const StorageLoading();
}

class StorageSuccess extends StorageState {
  final List<String> imageUrls;
  final String? lastUploadedUrl;

  const StorageSuccess(
    String downloadUrl, {
    required this.imageUrls,
    this.lastUploadedUrl,
  });

  @override
  List<Object?> get props => [imageUrls, lastUploadedUrl];
}

class StorageFailure extends StorageState {
  final String error;

  const StorageFailure(String string, {required this.error});

  @override
  List<Object?> get props => [error];
}
