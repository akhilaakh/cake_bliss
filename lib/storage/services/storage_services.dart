import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class StorageService with ChangeNotifier {
  // firebase storage
  final firebaseStorage = FirebaseStorage.instance;

  // images are stored in firebase as download URLs
  List<String> _imageUrls = [];

  //loading status
  bool _isLoading = false;

  //uploading status
  bool _isUploading = false;

  /*

  G E T T E R S


  */
  List<String> get imageUrls => _imageUrls;
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;

  /*


   R E A D    I M A G E

    */

  Future<void> fetchImage() async {
    //start loading...
    _isLoading = true;

    //get the list under the directory:upload_images
    final ListResult result =
        await firebaseStorage.ref('uploaded_images/').listAll();

    //get the download URLs for each image
    final urls =
        await Future.wait(result.items.map((ref) => ref.getDownloadURL()));

    // update URLs
    _imageUrls = urls;

    //loading finished..
    _isLoading = false;

    //update UI
    notifyListeners();
  }

  /*


     D E L E T E   I M A G E
   eg:  - images are stored as download URLs.eg.
     https://firebasestorage.googleapis.com/v0/b/fir-masterclass...../upload_images/image_name.png/.

     -in order to delete,we need to know only the path of this images store in firebase
     ie:upload_images/image_name.png

     */

  Future<void> deleteImages(String imageUrl) async {
    try {
      //remove from local list
      _imageUrls.remove(imageUrl);

      //get path name and delete from firebase
      final String path = extractPathFormUrl(imageUrl);
      await firebaseStorage.ref(path).delete();
    }

    //handle UI
    catch (e) {
      print("error deleting image: $e");
    }

    //upadete UI
    notifyListeners();
  }

  String extractPathFormUrl(String url) {
    Uri uri = Uri.parse(url);

    //extract the part of the url we need
    String encodePath = uri.pathSegments.last;

    //url decoding the path
    return Uri.decodeComponent(encodePath);
  }

  /*

    
   //  U P L O A D   I M A G E
   
   */

  Future<String?> uploadImage(String imagePath) async {
    try {
      _isUploading = true;
      notifyListeners();

      File file = File(imagePath);
      String filePath =
          'profile_images/${DateTime.now().millisecondsSinceEpoch}.png';

      // Upload file
      await firebaseStorage.ref(filePath).putFile(file);

      // Get download URL
      String downloadUrl = await firebaseStorage.ref(filePath).getDownloadURL();

      _imageUrls.add(downloadUrl);
      return downloadUrl;
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  saveImageUrl(String downloadUrl) {}
}
