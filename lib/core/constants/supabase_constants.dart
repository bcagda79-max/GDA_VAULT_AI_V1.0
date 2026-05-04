class SupabaseConstants {
  SupabaseConstants._();

  static const String bucketName = 'documents';

  static const String pathBoardAuthorityMinutes =
      'board-of-authority/board-authority-minutes';

  static const String pathTrustMinutes = 'board-of-authority/trust-minutes';

  static const String pathTownPlots = 'town-plots-files';

  static const String pathAdministration = 'administration-files';

  static const String pathPrivateProperties = 'private-properties-files';

  static const String idBoardOfAuthority =
      '11111111-1111-1111-1111-111111111111';

  static const String idBoardAuthorityMinutes =
      '22222222-2222-2222-2222-222222222222';

  static const String idTrustMinutes = '33333333-3333-3333-3333-333333333333';

  static const String idTownPlots = '44444444-4444-4444-4444-444444444444';

  static const String idAdministration = '55555555-5555-5555-5555-555555555555';

  static const String idPrivateProperties =
      '66666666-6666-6666-6666-666666666666';

  static String buildPath({
    required String categoryPath,
    required int year,
    required String fileName,
  }) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final safe = fileName
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^\w\-\.]'), '');
    return '$categoryPath/$year/${ts}_$safe';
  }
}
