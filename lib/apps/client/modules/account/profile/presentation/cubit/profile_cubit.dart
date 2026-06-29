import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_profile_data_usecase.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._getProfileData) : super(const ProfileLoading());

  final GetProfileDataUseCase _getProfileData;

  Future<void> load() async {
    emit(const ProfileLoading());
    try {
      final data = await _getProfileData();
      emit(ProfileLoaded(data));
    } catch (error) {
      emit(ProfileError(error.toString()));
    }
  }
}
