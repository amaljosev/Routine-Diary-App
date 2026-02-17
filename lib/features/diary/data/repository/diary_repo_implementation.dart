import 'dart:developer';
import 'package:routine/features/diary/data/datasources/diary_local_data_source.dart';
import 'package:routine/features/diary/data/models/diary_entry_model.dart';
import 'package:routine/features/diary/domain/repository/diary_repository.dart';

class DiaryRepositoryImpl implements DiaryRepository {
  final DiaryLocalDataSource localDataSource;

  DiaryRepositoryImpl(this.localDataSource);

  @override
Future<void> addEntry(DiaryEntryModel entry) async {
  try {
    await localDataSource.insertEntry(entry); 
  } catch (e, st) {
    log('addEntry error: $e', stackTrace: st);
    rethrow;
  }
}

@override
Future<void> updateEntry(DiaryEntryModel entry) async {
  try {
    await localDataSource.updateEntry(entry); 
  } catch (e, st) {
    log('updateEntry error: $e', stackTrace: st);
    rethrow;
  }
}


  @override
  Future<void> deleteEntry(String id) async {
    try {
      await localDataSource.deleteEntry(id);
    } catch (e, st) {
      log('deleteEntry error: $e', stackTrace: st);
      rethrow;
    }
  }

  @override
Future<List<DiaryEntryModel>> getAllEntries() async {
  try {
    final models = await localDataSource.getAllEntries();
    return models; // ✅ return models directly
  } catch (e, st) {
    log('getAllEntries error: $e', stackTrace: st);
    return [];
  }
}

@override
Future<DiaryEntryModel?> getEntryById(String id) async {
  try {
    final model = await localDataSource.getEntryById(id);
    return model; // ✅ no .toEntity()
  } catch (e, st) {
    log('getEntryById error: $e', stackTrace: st);
    return null;
  }
}

@override
Future<List<DiaryEntryModel>> searchEntries(String query) async {
  try {
    final models = await localDataSource.search(query);
    return models; // ✅ no .toEntity()
  } catch (e, st) {
    log('searchEntries error: $e', stackTrace: st);
    return [];
  }
}

}
