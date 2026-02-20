import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:routine/features/settings/domain/theme_repository.dart';

part 'apptheme_event.dart';
part 'apptheme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final ThemeRepository repository;

  ThemeBloc({required this.repository}) : super(ThemeState.initial()) {
    on<LoadSavedTheme>(_onLoadSavedTheme);
    on<ChangeTheme>(_onChangeTheme);
  }

  Future<void> _onLoadSavedTheme(
    LoadSavedTheme event,
    Emitter<ThemeState> emit,
  ) async {
    final index = await repository.getSavedThemeIndex();
    emit(state.copyWith(themeIndex: index));
  }

  Future<void> _onChangeTheme(
    ChangeTheme event,
    Emitter<ThemeState> emit,
  ) async {
    await repository.saveThemeIndex(event.themeIndex);
    emit(state.copyWith(themeIndex: event.themeIndex));
  }
}