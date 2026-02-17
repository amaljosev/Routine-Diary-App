import 'dart:developer';
import 'dart:typed_data';
import 'package:routine/features/diary/data/models/diary_entry_model.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image/image.dart' as img;

import 'package:routine/features/diary/domain/repository/diary_repository.dart';

part 'diary_event.dart';
part 'diary_state.dart';

class DiaryBloc extends Bloc<DiaryEvent, DiaryState> {
  final DiaryRepository repository;

  DiaryBloc({required this.repository}) : super(const DiaryState()) {
    // Core
    on<LoadDiaryEntries>(_onLoadEntries);
    on<UpdateScrollOffset>(_onUpdateScrollOffset);
    on<UpdateDominantColor>(_onUpdateDominantColor);

    // CRUD
    on<FetchAllEntries>(_onFetchAllEntries);
    on<FetchEntryById>(_onFetchEntryById);
    on<AddDiaryEntry>(_onSaveEntry);
    on<UpdateDiaryEntry>(_onUpdateEntry);
    on<DeleteDiaryEntry>(_onDeleteEntry);
    on<SearchDiaryEntries>(_onSearchEntries);
  }

  // --------------------------------------------------------------------------
  // Load all entries
  // --------------------------------------------------------------------------
  Future<void> _onLoadEntries(
    LoadDiaryEntries event,
    Emitter<DiaryState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final entries = await repository.getAllEntries();
      emit(state.copyWith(entries: entries, isLoading: false));
    } catch (e, st) {
      log('LoadDiaryEntries error: $e', stackTrace: st);
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  // --------------------------------------------------------------------------
  // Scroll offset update
  // --------------------------------------------------------------------------
  void _onUpdateScrollOffset(
    UpdateScrollOffset event,
    Emitter<DiaryState> emit,
  ) {
    emit(state.copyWith(scrollOffset: event.offset));
  }

  // --------------------------------------------------------------------------
  // Dominant color from image
  // --------------------------------------------------------------------------
  Future<void> _onUpdateDominantColor(
    UpdateDominantColor event,
    Emitter<DiaryState> emit,
  ) async {
    try {
      final ByteData data = await rootBundle.load(event.imagePath);
      final Uint8List bytes = Uint8List.fromList(data.buffer.asUint8List());
      final image = img.decodeImage(bytes);
      if (image == null) return;

      final int sampleHeight = (image.height * 0.1).round();
      final int startY = image.height - sampleHeight;

      Map<Color, int> colorCounts = {};

      for (int y = startY; y < image.height; y += 5) {
        for (int x = 0; x < image.width; x += 5) {
          final pixel = image.getPixel(x, y);
          final color = Color.fromARGB(
            pixel.a.toInt(),
            pixel.r.toInt(),
            pixel.g.toInt(),
            pixel.b.toInt(),
          );
          final groupedColor = _groupSimilarColor(color);
          colorCounts[groupedColor] = (colorCounts[groupedColor] ?? 0) + 1;
        }
      }

      if (colorCounts.isNotEmpty) {
        final mostFrequentColor = colorCounts.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
        emit(state.copyWith(dominantColor: mostFrequentColor));
      }
    } catch (e, st) {
      log('UpdateDominantColor error: $e', stackTrace: st);
      emit(state.copyWith(dominantColor: Colors.grey[900]!));
    }
  }

  Color _groupSimilarColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    final groupedHue = (hsl.hue / 30).round() * 30.0;
    return HSLColor.fromAHSL(
      hsl.alpha,
      groupedHue,
      hsl.saturation,
      hsl.lightness,
    ).toColor();
  }

  // --------------------------------------------------------------------------
  // CRUD methods
  // --------------------------------------------------------------------------
  Future<void> _onFetchAllEntries(
    FetchAllEntries event,
    Emitter<DiaryState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final entries = await repository.getAllEntries();
      emit(state.copyWith(entries: entries, isLoading: false));
    } catch (e, st) {
      log('FetchAllEntries error: $e', stackTrace: st);
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onFetchEntryById(
    FetchEntryById event,
    Emitter<DiaryState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final entry = await repository.getEntryById(event.id);
      if (entry != null) {
        emit(state.copyWith(entries: [entry], isLoading: false));
      } else {
        emit(state.copyWith(isLoading: false));
      }
    } catch (e, st) {
      log('FetchEntryById error: $e', stackTrace: st);
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onSaveEntry(
    AddDiaryEntry event,
    Emitter<DiaryState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      await repository.addEntry(event.entry);
      add(FetchAllEntries());
    } catch (e, st) {
      log('AddDiaryEntry error: $e', stackTrace: st);
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onUpdateEntry(
    UpdateDiaryEntry event,
    Emitter<DiaryState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      await repository.updateEntry(event.entry);
      add(FetchAllEntries());
    } catch (e, st) {
      log('UpdateDiaryEntry error: $e', stackTrace: st);
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onDeleteEntry(
    DeleteDiaryEntry event,
    Emitter<DiaryState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      await repository.deleteEntry(event.id);
      add(FetchAllEntries());
    } catch (e, st) {
      log('DeleteDiaryEntry error: $e', stackTrace: st);
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> _onSearchEntries(
    SearchDiaryEntries event,
    Emitter<DiaryState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final entries = await repository.searchEntries(event.query);
      emit(state.copyWith(entries: entries, isLoading: false));
    } catch (e, st) {
      log('SearchDiaryEntries error: $e', stackTrace: st);
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }
}
