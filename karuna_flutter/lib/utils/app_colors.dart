import 'package:flutter/material.dart';

/// Colors extracted directly from the Figma design (DSX37nkMZJkFcJFQz93CXB)
class AppColors {
  // ── Brand ────────────────────────────────────────────────────────────────
  static const Color teal      = Color(0xFF0F766E); // Primary brand teal
  static const Color tealDark  = Color(0xFF0D5C56);
  static const Color tealLight = Color(0xFFDDF3F2); // #ddf3f2 from Figma hero text
  static const Color tealBg    = Color(0x1F0F766E); // rgba(15,118,110,0.12) page bg tint
  static const Color navy      = Color(0xFF0A2E50);

  // ── Neutral ──────────────────────────────────────────────────────────────
  static const Color dark       = Color(0xFF1E293D); // #1e293d main text
  static const Color gray       = Color(0xFF64748B); // #64748b subtext
  static const Color divider    = Color(0xFFE2E7F0); // #e2e7f0 divider/border
  static const Color inputBg    = Color(0xFFF1F5F9);
  static const Color background = Color(0xFFF8FAFD); // #f8fafd page bg
  static const Color white      = Colors.white;

  // ── Status badges ────────────────────────────────────────────────────────
  static const Color critical   = Color(0xFFEF4444);
  static const Color criticalBg = Color(0xFFFCE5E5);
  static const Color urgent     = Color(0xFFFA9C45); // #fa9c45 "Moderate/Active" orange
  static const Color urgentBg   = Color(0xFFFFF5E0);
  static const Color active     = Color(0xFF3B82F6);
  static const Color activeBg   = Color(0xFFEFF6FF);
  static const Color resolved   = Color(0xFF10B981);
  static const Color resolvedBg = Color(0xFFD1FAE5);

  // ── Bottom nav (Figma: solid teal bg, white icons) ───────────────────────
  static const Color navBg         = Color(0xFF0F766E); // same as teal
  static const Color navIconActive  = Colors.white;
  static const Color navIconInactive= Color(0xAAFFFFFF); // white 67%
}
