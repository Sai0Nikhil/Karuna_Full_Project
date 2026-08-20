import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/case_provider.dart';
import 'providers/volunteer_provider.dart';
import 'utils/app_theme.dart';

// Auth
import 'screens/splash_screen.dart';
import 'screens/auth/choose_role_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';

// Citizen
import 'screens/citizen/citizen_home.dart';
import 'screens/citizen/case_detail_screen.dart';
import 'screens/citizen/donate_screen.dart';
import 'screens/citizen/adopt_screen.dart';
import 'screens/citizen/first_aid_screen.dart';
import 'screens/citizen/my_cases_screen.dart';
import 'screens/citizen/sita_chat_screen.dart';
import 'screens/citizen/nearby_vets_screen.dart';

// NGO
import 'screens/ngo/ngo_home.dart';
import 'screens/ngo/ngo_case_detail.dart';
import 'screens/ngo/map_routing_screen.dart';

// Volunteer
import 'screens/volunteer/volunteer_home.dart';
import 'screens/volunteer/volunteer_case_detail.dart';

// Veterinary Clinic
import 'screens/vet/vet_home.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CaseProvider()),
        ChangeNotifierProvider(create: (_) => VolunteerProvider()),
      ],
      child: const KarunaApp(),
    ),
  );
}

class KarunaApp extends StatelessWidget {
  const KarunaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Karuṇā',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: '/',
      onGenerateRoute: _router,
    );
  }

  Route<dynamic>? _router(RouteSettings settings) {
    switch (settings.name) {
      // ── Entry flow ──────────────────────────────────────────────────────
      case '/':
        return _fade(const SplashScreen());

      case '/choose-role':
        return _slide(const ChooseRoleScreen());

      case '/login':
        return _slide(const LoginScreen());

      case '/register':
        return _slide(const RegisterScreen());

      // ── Citizen portal ──────────────────────────────────────────────────
      case '/citizen':
        return _fade(const CitizenHome());

      case '/citizen/case':
        final id = settings.arguments as int;
        return _slide(CaseDetailScreen(caseId: id));

      case '/citizen/donate':
        return _slide(const DonateScreen());

      case '/citizen/adopt':
        return _slide(const AdoptScreen());

      case '/citizen/firstaid':
        return _slide(const FirstAidScreen());

      case '/citizen/cases':
        return _slide(const MyCasesScreen());

      case '/citizen/sita':
        return _slide(const SitaChatScreen());

      case '/citizen/vets':
        return _slide(const NearbyVetsScreen());

      // ── NGO portal ──────────────────────────────────────────────────────
      case '/ngo':
        return _fade(const NgoHome());

      case '/ngo/case':
        final id = settings.arguments as int;
        return _slide(NgoCaseDetail(caseId: id));

      case '/map-routing':
        final args = settings.arguments as Map<String, dynamic>;
        return _slide(MapRoutingScreen(
          caseId: args['caseId'] as int,
          caseLat: args['caseLat'] as double,
          caseLon: args['caseLon'] as double,
          animalTitle: args['animalTitle'] as String,
        ));

      // ── Volunteer portal ─────────────────────────────────────────────────
      case '/volunteer':
        return _fade(const VolunteerHome());

      case '/volunteer/case':
        final caseModel = settings.arguments;
        return _slide(VolunteerCaseDetail(caseModel: caseModel));

      // ── Veterinary Clinic portal ─────────────────────────────────────────
      case '/vet':
        return _fade(const VetHome());

      case '/vet/case':
        final id = settings.arguments as int;
        return _slide(NgoCaseDetail(caseId: id)); // reuses NGO case detail

      default:
        return _fade(const ChooseRoleScreen());
    }
  }

  PageRoute _fade(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      );

  PageRoute _slide(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 280),
      );
}
