// lib/features/diary/presentation/blocs/showcase/showcase_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine/core/services/showcase_prefs_service.dart';

part 'showcase_state.dart';

class ShowcaseCubit extends Cubit<ShowcaseState> {
  ShowcaseCubit() : super(const ShowcaseState());

  // ── Home screen ────────────────────────────────────────────────────────────

  void checkIfShouldShowHome() {
    emit(ShowcaseState(
      shouldShow: !ShowcasePrefsService.instance.hasSeenHomeShowcase,
    ));
  }

  Future<void> markHomeSeen() async {
    await ShowcasePrefsService.instance.markHomeShowcaseSeen();
    emit(const ShowcaseState(shouldShow: false));
  }

  // ── Entry screen ───────────────────────────────────────────────────────────

  void checkIfShouldShowEntry() {
    emit(ShowcaseState(
      shouldShow: !ShowcasePrefsService.instance.hasSeenEntryShowcase,
    ));
  }

  Future<void> markEntrySeen() async {
    await ShowcasePrefsService.instance.markEntryShowcaseSeen();
    emit(const ShowcaseState(shouldShow: false));
  }
}