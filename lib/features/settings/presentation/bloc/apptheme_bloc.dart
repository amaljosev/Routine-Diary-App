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
  }

  // ── existing handlers ─────────────────────────────────────────────────────

  Future<void> _onLoadSavedTheme(
    LoadSavedTheme event,
    Emitter<ThemeState> emit,
  ) async {
    final index = await repository.getSavedThemeIndex();
    if (index == kCustomThemeIndex) {
      final saved = await repository.getSavedCustomTheme();
      if (saved != null) {
        emit(state.copyWith(
          themeIndex: kCustomThemeIndex,
          customThemeModel: saved,
          customThemeData: buildCustomThemeData(saved),
        ));
        return;
      }
      // Fallback: saved index was custom but no config found → use theme 0
      emit(state.copyWith(themeIndex: 0));
      return;
    }
    emit(state.copyWith(themeIndex: index));
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

  // ── new handler ───────────────────────────────────────────────────────────

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
}