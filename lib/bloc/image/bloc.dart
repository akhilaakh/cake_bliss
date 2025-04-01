import 'dart:io';
import 'package:cake_bliss/Bloc/image/event.dart';
import 'package:cake_bliss/Bloc/image/state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cake_bliss/storage/services/storage_services.dart';

class StorageBloc extends Bloc<StorageEvent, StorageState> {
  final StorageService storageService;

  StorageBloc({required this.storageService}) : super(StorageInitial()) {
    on<UploadImageEvent>((event, emit) async {
      try {
        emit(StorageLoading());

        // Check if file exists
        final file = File(event.imagepath); // Changed from event.filePath
        if (!await file.exists()) {
          throw Exception('File does not exist at path: ${event.imagepath}');
        }

        // Create the storage reference with the correct path
        final ref = FirebaseStorage.instance.ref().child(event.filePath);

        // Upload file
        final uploadTask = await ref.putFile(file);

        if (uploadTask.state == TaskState.success) {
          final downloadUrl = await ref.getDownloadURL();
          print('Download URL: $downloadUrl'); // Debug print

          emit(StorageSuccess(
            downloadUrl,
            imageUrls: [downloadUrl],
            lastUploadedUrl: downloadUrl,
          ));
        } else {
          throw Exception('Upload task failed');
        }
      } catch (e) {
        print('Error uploading image: $e');
        emit(StorageFailure(
          'Failed to upload image: ${e.toString()}',
          error: e.toString(),
        ));
      }
    });
  }
}
