part of 'diary_bloc.dart';

abstract class DiaryEvent extends Equatable {
  const DiaryEvent();

  @override
  List<Object?> get props => [];
}

class LoadDiaryEntries extends DiaryEvent {}

class UpdateScrollOffset extends DiaryEvent {
  final double offset;
  const UpdateScrollOffset(this.offset);

  @override
  List<Object?> get props => [offset];
}

class UpdateDominantColor extends DiaryEvent {
  final String imagePath;
  const UpdateDominantColor(this.imagePath);

  @override
  List<Object?> get props => [imagePath];
}

class FetchAllEntries extends DiaryEvent {}

class FetchEntryById extends DiaryEvent {
  final String id;
  const FetchEntryById(this.id);
  @override
  List<Object?> get props => [id];
}

class AddDiaryEntry extends DiaryEvent {
  final DiaryEntryModel entry;
  const AddDiaryEntry(this.entry);
  @override
  List<Object?> get props => [entry];
}

class UpdateDiaryEntry extends DiaryEvent {
  final DiaryEntryModel entry;
  const UpdateDiaryEntry(this.entry);
  @override
  List<Object?> get props => [entry];
}

class DeleteDiaryEntry extends DiaryEvent {
  final String id;
  const DeleteDiaryEntry(this.id);
  @override
  List<Object?> get props => [id];
}

class SearchDiaryEntries extends DiaryEvent {
  final String query;
  const SearchDiaryEntries(this.query);
  @override
  List<Object?> get props => [query];
}

class ToggleFavorite extends DiaryEvent {
  final String id;
  final bool isFavorite;
  const ToggleFavorite({required this.id, required this.isFavorite});
  @override
  List<Object?> get props => [id, isFavorite];
}

class FetchFavoriteEntries extends DiaryEvent {}
