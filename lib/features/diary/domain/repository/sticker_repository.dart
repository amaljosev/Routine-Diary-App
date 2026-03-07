abstract class StickerRepository {
  Future<List<String>> getStickerUrls();
  Future<String> downloadSticker(String url);
}