abstract class BackgroundRepository {
  Future<List<String>> getBackgroundUrls();
  Future<String> downloadBackground(String url);
}