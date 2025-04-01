import 'package:cake_bliss/Bloc/profile/event.dart';
import 'package:cake_bliss/Bloc/profile/state.dart';
import 'package:cake_bliss/databaseServices/database_service.dart';
import 'package:cake_bliss/model/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ProfileBloc() : super(const ProfileInitial()) {
    on<FetchProfileEvent>(_fetchProfile);
    on<UpdateProfileEvent>(_updateProfile);
  }

  // Fetch user profile
  Future<void> _fetchProfile(
      FetchProfileEvent event, Emitter<ProfileState> emit) async {
    emit(const ProfileLoading());
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        emit(const ProfileError("No user logged in"));
        return;
      }

      final UserModel? userProfile =
          await _dbService.getUserProfile(currentUser.uid);

      if (userProfile != null) {
        print("Fetched Profile: ${userProfile.imageUrl}"); // Debugging
        emit(ProfileLoaded(userProfile));
      } else {
        emit(const ProfileError("Profile not found"));
      }
    } catch (e) {
      emit(ProfileError("Failed to fetch profile: ${e.toString()}"));
    }
  }

  // Update user profile
  Future<void> _updateProfile(
      UpdateProfileEvent event, Emitter<ProfileState> emit) async {
    emit(const ProfileLoading());
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        emit(const ProfileError("No user logged in"));
        return;
      }

      // Ensure image URL is updated
      print("Updating Profile: ${event.user.imageUrl}"); // Debugging
      await _dbService.updateUserProfile(event.user);

      emit(const ProfileUpdateSuccess());

      // Fetch updated profile to reflect changes
      add(FetchProfileEvent());
    } catch (e) {
      emit(ProfileError("Failed to update profile: ${e.toString()}"));
    }
  }
}
