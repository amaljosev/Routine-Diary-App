// lib/features/diary/presentation/blocs/showcase/showcase_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine/core/services/showcase_prefs_service.dart';

part 'showcase_state.dart';

class ShowcaseCubit extends Cubit<ShowcaseState> {
  ShowcaseCubit() : super(const ShowcaseState());

  /// Check SharedPrefs and emit whether the showcase should run.
  void checkIfShouldShow() {
    emit(ShowcaseState(
      shouldShow: !ShowcasePrefsService.instance.hasSeenShowcase,
    ));
  }

  /// Persist "seen" and emit done state.
  Future<void> markSeen() async {
    await ShowcasePrefsService.instance.markShowcaseSeen();
    emit(const ShowcaseState(shouldShow: false));
  }
}