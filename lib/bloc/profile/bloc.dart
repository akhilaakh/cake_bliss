import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cake_bliss/Bloc/profile/event.dart';
import 'package:cake_bliss/Bloc/profile/state.dart';
import 'package:cake_bliss/databaseServices/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ProfileBloc() : super(const ProfileInitial()) {
    on<FetchProfileEvent>(_fetchProfile);
    on<UpdateProfileEvent>(_updateProfile);
  }

  Future<void> _fetchProfile(
      FetchProfileEvent event, Emitter<ProfileState> emit) async {
    emit(const ProfileLoading());

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        emit(const ProfileError("No user logged in"));
        return;
      }

      final userModel = await _dbService.readUserProfile(currentUser.email!);
      if (userModel != null) {
        // Add debug logging
        log('Fetched user profile:');
        log('Name: ${userModel.name}');
        log('Email: ${userModel.email}');
        log('ImageUrl: ${userModel.imageUrl}');
        log('Address: ${userModel.address}');
        log('Phone: ${userModel.phone}');

        emit(ProfileLoaded(userModel));
      } else {
        log('User profile not found');
        emit(const ProfileError("User profile not found"));
      }
    } catch (e) {
      log("Error fetching profile: ${e.toString()}");
      emit(ProfileError("Failed to load profile: ${e.toString()}"));
    }
  }

  Future<void> _updateProfile(
      UpdateProfileEvent event, Emitter<ProfileState> emit) async {
    emit(const ProfileLoading());
    try {
      // Add debug logging
      log('Updating profile with image URL: ${event.user.imageUrl}');

      await _dbService.updateUserProfile(event.user);
      emit(const ProfileUpdateSuccess());
      add(const FetchProfileEvent()); // Refresh profile data
    } catch (e) {
      log("Error updating profile: ${e.toString()}");
      emit(ProfileError("Failed to update profile: ${e.toString()}"));
    }
  }
}
