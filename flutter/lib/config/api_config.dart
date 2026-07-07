/// ─────────────────────────────────────────────────────────────────────────
///  Karuṇā API Configuration
///  Change baseUrl below to point to your backend.
/// ─────────────────────────────────────────────────────────────────────────

class ApiConfig {
  // ── Set baseUrl to match your environment ────────────────────────────────
  //   Android emulator  → 'http://10.0.2.2:8081/api'
  //   Physical device   → 'http://<YOUR_LOCAL_IP>:8081/api'
  //   Production        → 'https://<YOUR_BACKEND_DOMAIN>/api'

  static const String baseUrl = 'http://10.0.2.2:8081/api'; // local (Android emulator)
  // static const String baseUrl = 'http://192.168.1.X:8081/api'; // local (physical device)

  // ── Endpoints ─────────────────────────────────────────────────────────────
  static const String login       = '$baseUrl/auth/login';
  static const String register    = '$baseUrl/auth/register';
  static const String health      = '$baseUrl/auth/health';
  static const String cases       = '$baseUrl/cases';
  static const String openCases   = '$baseUrl/cases/open';
  static const String myCases     = '$baseUrl/cases/my';
  static const String donations   = '$baseUrl/donations';
  static const String adoptions   = '$baseUrl/adoptions';

  static String caseById(int id)       => '$baseUrl/cases/$id';
  static String assignCase(int id)     => '$baseUrl/cases/$id/assign';
  static String advanceCase(int id)    => '$baseUrl/cases/$id/advance';
  static String caseNotes(int id)      => '$baseUrl/cases/$id/notes';
  static String donationsForCase(int id)  => '$baseUrl/donations/case/$id';
  static String adoptionsForCase(int id)  => '$baseUrl/adoptions/case/$id';
  static String applyAdoption(int id)     => '$baseUrl/adoptions/case/$id/apply';
  static String aiAnalyze()           => '$baseUrl/ai/analyze';
  static String aiPhoto()             => '$baseUrl/ai/analyze-photo';
  static String aiFirstAid()          => '$baseUrl/ai/firstaid';
  static String aiSummary(int id)     => '$baseUrl/ai/summary/$id';

  static const Duration timeout = Duration(seconds: 20);
}
