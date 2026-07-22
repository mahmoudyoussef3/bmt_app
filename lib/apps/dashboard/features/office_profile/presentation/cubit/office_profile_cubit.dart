import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/office_profile.dart';
import '../../domain/usecases/office_profile_usecases.dart';
import 'office_profile_state.dart';

class OfficeProfileCubit extends Cubit<OfficeProfileState> {
  OfficeProfileCubit({
    required GetOfficeProfileUseCase getProfile,
    required UpdateOfficeProfileUseCase updateProfile,
  }) : _getProfile = getProfile,
       _updateProfile = updateProfile,
       super(const OfficeProfileInitial());

  final GetOfficeProfileUseCase _getProfile;
  final UpdateOfficeProfileUseCase _updateProfile;

  Future<void> load() async {
    emit(const OfficeProfileLoading());
    try {
      emit(OfficeProfileLoaded(await _getProfile()));
    } catch (error) {
      emit(OfficeProfileError(_message(error)));
    }
  }

  Future<void> save(OfficeProfileEdit edit) async {
    final current = _profile();
    if (current == null) return;

    emit(OfficeProfileLoaded(current, isSaving: true));
    try {
      final updated = await _updateProfile(edit);
      emit(OfficeProfileActionSuccess('تم حفظ بيانات المكتب', updated));
      emit(OfficeProfileLoaded(updated));
    } catch (error) {
      // A failure state carrying the last good profile, not OfficeProfileError:
      // the form is still on screen with the operator's edits in it, and a
      // full-screen error would discard them.
      emit(OfficeProfileActionFailure(_message(error), current));
      emit(OfficeProfileLoaded(current));
    }
  }

  OfficeProfile? _profile() {
    final current = state;
    return switch (current) {
      OfficeProfileLoaded() => current.profile,
      OfficeProfileActionSuccess() => current.profile,
      OfficeProfileActionFailure() => current.profile,
      _ => null,
    };
  }

  String _message(Object error) =>
      error.toString().replaceAll('Exception: ', '');
}
