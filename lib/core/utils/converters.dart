class AppConverters {
  static DateTime? stringToDateTime(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.tryParse(dateString);
    } catch (_) {
      return null;
    }
  }

}
