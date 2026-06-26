// lib/features/settings/presentation/bloc/apptheme_bloc.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine/features/settings/domain/custom_theme_builder.dart';
import 'package:routine/features/settings/domain/custom_theme_model.dart';
import 'package:routine/features/settings/domain/theme_repository.dart';

part 'apptheme_event.dart';
part 'apptheme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final ThemeRepository repository;

  ThemeBloc({required this.repository}) : super(ThemeState.initial()) {
    on<LoadSavedTheme>(_onLoadSavedTheme);
    on<ChangeTheme>(_onChangeTheme);
    on<ApplyCustomTheme>(_onApplyCustomTheme);
    on<DeactivateCustomTheme>(_onDeactivateCustomTheme);
  }

  // ── Handlers ──────────────────────────────────────────────────────────────

  Future<void> _onLoadSavedTheme(
  LoadSavedTheme event,
  Emitter<ThemeState> emit,
) async {
  final index = await repository.getSavedThemeIndex();

  // Always load the saved custom theme model — even when it's not the active
  // theme. This ensures customThemeModel is non-null after a cold start for
  // lapsed subscribers, so the "Restore Custom Theme" button can appear.
  final savedCustomModel = await repository.getSavedCustomTheme();

  if (index == kCustomThemeIndex) {
    if (savedCustomModel != null) {
      emit(state.copyWith(
        themeIndex: kCustomThemeIndex,
        customThemeModel: savedCustomModel,
        customThemeData: buildCustomThemeData(savedCustomModel),
      ));
      return;
    }
    // Fallback: saved index was custom but no config found → use theme 0.
    emit(state.copyWith(themeIndex: 0));
    return;
  }

  // Active theme is a built-in — but still populate customThemeModel so the
  // Restore button appears for lapsed subscribers on the next cold start.
  emit(state.copyWith(
    themeIndex: index,
    customThemeModel: savedCustomModel, // null-safe: copyWith ignores null
  ));
}

  Future<void> _onChangeTheme(
    ChangeTheme event,
    Emitter<ThemeState> emit,
  ) async {
    await repository.saveThemeIndex(event.themeIndex);
    emit(state.copyWith(
      themeIndex: event.themeIndex,
      clearCustomTheme: true,
    ));
  }

  Future<void> _onApplyCustomTheme(
    ApplyCustomTheme event,
    Emitter<ThemeState> emit,
  ) async {
    await repository.saveCustomTheme(event.model);
    await repository.saveThemeIndex(kCustomThemeIndex);
    emit(state.copyWith(
      themeIndex: kCustomThemeIndex,
      customThemeModel: event.model,
      customThemeData: buildCustomThemeData(event.model),
    ));
  }

  /// Switches the active theme back to 0 (default) when a subscription expires,
  /// but deliberately preserves [customThemeModel] in state and in
  /// SharedPreferences so it can be restored when the user re-subscribes.
  ///
  /// Use this instead of [ChangeTheme] on subscription expiry — [ChangeTheme]
  /// calls `clearCustomTheme: true` which is destructive.
  Future<void> _onDeactivateCustomTheme(
    DeactivateCustomTheme event,
    Emitter<ThemeState> emit,
  ) async {
    // Persist the active-theme index as 0, but do NOT touch the saved custom
    // theme config — the user's data is theirs to keep.
    await repository.saveThemeIndex(0);
    emit(state.copyWith(
      themeIndex: 0,
      // customThemeModel intentionally NOT cleared — clearCustomTheme defaults
      // to false, so the model stays in state and survives this transition.
    ));
  }
}