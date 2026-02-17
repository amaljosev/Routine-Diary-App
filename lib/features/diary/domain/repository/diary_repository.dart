import 'package:routine/features/diary/data/models/diary_entry_model.dart';

abstract class DiaryRepository {
  Future<List<DiaryEntryModel>> getAllEntries();
  Future<DiaryEntryModel?> getEntryById(String id);
  Future<void> addEntry(DiaryEntryModel entry);
  Future<void> updateEntry(DiaryEntryModel entry);
  Future<void> deleteEntry(String id);
  Future<List<DiaryEntryModel>> searchEntries(String query);
}
