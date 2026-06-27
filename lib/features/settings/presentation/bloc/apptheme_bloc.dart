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

  /// In-memory cache of the user's saved custom theme model.
  ///
  /// WHY THIS EXISTS:
  /// ThemeState.customThemeModel must survive calls to ChangeTheme (switching
  /// to a built-in theme) so the "Restore Custom Theme" button stays visible.
  /// if the ThemeRepository.getSavedCustomTheme() ever returns null mid-session
  /// — we keep a dedicated field here that is only ever set, never cleared
  /// except when the user explicitly deletes their custom theme.
  ///
  /// This field is the single source of truth for "does a saved custom theme
  /// exist?" across the bloc's lifetime.
  CustomThemeModel? _cachedCustomModel;

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
    // Always load the saved custom theme model first, regardless of which
    // theme index is active. This populates _cachedCustomModel so every
    // subsequent event can rely on it without hitting storage again.
    final savedCustomModel = await repository.getSavedCustomTheme();
    if (savedCustomModel != null) {
      _cachedCustomModel = savedCustomModel;
    }

    final index = await repository.getSavedThemeIndex();

    if (index == kCustomThemeIndex && _cachedCustomModel != null) {
      emit(state.copyWith(
        themeIndex: kCustomThemeIndex,
        customThemeModel: _cachedCustomModel,
        customThemeData: buildCustomThemeData(_cachedCustomModel!),
      ));
      return;
    }

    // Built-in theme is active — emit with the cached model so the restore
    // button has the data it needs immediately on first build.
    emit(state.copyWith(
      themeIndex: index.clamp(0, kCustomThemeIndex - 1), // clamps to 0–6 (the 7 built-in themes)
      customThemeModel: _cachedCustomModel,
      clearActiveCustomTheme: true,
    ));
  }

  /// Switches to a built-in theme by index.
  ///
  /// Emits with [_cachedCustomModel] explicitly so the value is guaranteed
  /// to be present in the new state — even if the previous state somehow
  /// lost it. This is the key fix: we never depend on copyWith's null-fallback
  /// for [customThemeModel]; we always supply the cached value directly.
  Future<void> _onChangeTheme(
    ChangeTheme event,
    Emitter<ThemeState> emit,
  ) async {
    await repository.saveThemeIndex(event.themeIndex);
    emit(state.copyWith(
      themeIndex: event.themeIndex,
      // Always pass the cached model explicitly — never rely on the
      // null-fallback in copyWith. If _cachedCustomModel is null the
      // parameter is null and copyWith keeps whatever was in state, which
      // is also correct. But if state somehow lost it, this restores it.
      customThemeModel: _cachedCustomModel,
      clearActiveCustomTheme: true,
    ));
  }

  Future<void> _onApplyCustomTheme(
    ApplyCustomTheme event,
    Emitter<ThemeState> emit,
  ) async {
    _cachedCustomModel = event.model; // update cache
    await repository.saveCustomTheme(event.model);
    await repository.saveThemeIndex(kCustomThemeIndex);
    emit(state.copyWith(
      themeIndex: kCustomThemeIndex,
      customThemeModel: _cachedCustomModel,
      customThemeData: buildCustomThemeData(_cachedCustomModel!),
    ));
  }

  /// Fired on subscription expiry. Switches active theme to 0 but preserves
  /// [_cachedCustomModel] so the restore button stays visible.
  Future<void> _onDeactivateCustomTheme(
    DeactivateCustomTheme event,
    Emitter<ThemeState> emit,
  ) async {
    await repository.saveThemeIndex(0);
    emit(state.copyWith(
      themeIndex: 0,
      // Explicitly pass cached model — same guarantee as _onChangeTheme.
      customThemeModel: _cachedCustomModel,
      clearActiveCustomTheme: true,
    ));
  }
}