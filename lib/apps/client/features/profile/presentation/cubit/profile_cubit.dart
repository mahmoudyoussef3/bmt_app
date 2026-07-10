import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_profile_data_usecase.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._getProfileData) : super(const ProfileLoading());

  final GetProfileDataUseCase _getProfileData;

  /// Loads profile data. When content is already on screen
  /// (pull-to-refresh), the loaded state is kept instead of flashing the
  /// skeleton; a refresh failure also keeps the existing content rather than
  /// replacing it with a full-screen error.
  Future<void> load() async {
    final previous = state;
    if (previous is! ProfileLoaded) emit(const ProfileLoading());
    try {
      final data = await _getProfileData();
      emit(ProfileLoaded(data));
    } catch (error) {
      if (previous is ProfileLoaded) {
        emit(ProfileLoaded(previous.data, refreshFailure: error.toString()));
      } else {
        emit(ProfileError(error.toString()));
      }
    }
  }
}
