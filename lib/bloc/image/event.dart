import 'package:equatable/equatable.dart';

abstract class StorageEvent extends Equatable {
  const StorageEvent();

  @override
  List<Object?> get props => [];
}

class FetchImagesEvent extends StorageEvent {
  const FetchImagesEvent();
}

class UploadImageEvent extends StorageEvent {
  final String filePath; // Local file path
  final String storagePath;
  final String imagepath; // Firebase storage path

  const UploadImageEvent({
    required this.filePath,
    required this.storagePath,
    required this.imagepath,
    required String imagePath,
  });

  @override
  List<Object> get props => [filePath, storagePath];
}
