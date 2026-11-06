class ApiConstants {
  // Support compile-time configuration via --dart-define=SANITA_API_URL=...
  // Example for Railway: https://sanita-backend.up.railway.app/api/v1
  // Example for Render:  https://sanita-backend.onrender.com/api/v1
  static const String _envBaseUrl = String.fromEnvironment(
    'SANITA_API_URL',
    defaultValue: 'http://localhost:8080/api/v1',
  );

  static String baseUrl = _envBaseUrl;

  /// Dynamic URL configuration for testing or cloud switching
  static void setBaseUrl(String newUrl) {
    if (newUrl.isNotEmpty) {
      baseUrl = newUrl;
    }
  }

  // Endpoints
  static const String authLogin        = '/auth/login';
  static const String authRegister     = '/auth/register';
  static const String authProfile      = '/auth/profile';

  static const String checklistSubmit  = '/sanitasi/checklist';
  static const String checklistHistory = '/sanitasi/history';

  static const String laporanSubmit    = '/laporan';
  static const String laporanMy        = '/laporan';
  static const String laporanAll       = '/laporan/all';

  static const String edukasiAll       = '/edukasi';
  static const String monitoringStats  = '/monitoring/stats';
  static const String securityStatus   = '/security/status';

  static const Duration timeout = Duration(seconds: 15);
}