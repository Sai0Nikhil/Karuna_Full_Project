/// ─────────────────────────────────────────────────────────────────────────
///  Karuṇā API Configuration
///  Change ONE line below to switch between local and production.
/// ─────────────────────────────────────────────────────────────────────────

class ApiConfig {
  // ✏️  SET THIS to your Render URL once deployed, e.g.:
  //     'https://karuna-backend.onrender.com/api'
  //
  // For local development:
  //   Android emulator  → 'http://10.0.2.2:8081/api'
  //   Physical device   → 'http://192.168.X.X:8081/api'
  //   Production        → 'https://karuna-backend.onrender.com/api'

  static const String baseUrl = 'https://karuna-backend-pa4r.onrender.com/api'; // ✅ LIVE
  // static const String baseUrl = 'http://10.0.2.2:8081/api'; // ← local emulator

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
