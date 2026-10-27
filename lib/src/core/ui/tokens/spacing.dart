import 'package:flutter/material.dart';

/// Spacing, padding, and radius tokens for the Premium Enterprise SaaS
/// design system. Pure 4-pt scale. Every layout / primitive should
/// reference these instead of magic numbers.
class AppSpace {
  AppSpace._();

  // Base 4-pt scale
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double xxxxl = 40;
  static const double xxxxxl = 48;
  static const double huge = 64;

  // Backward-compatible names
  static const double x2l = xxl;
  static const double x3l = xxxl;

  // EdgeInsets
  static const EdgeInsets pageHorizontal = EdgeInsets.symmetric(horizontal: 24);
  static const EdgeInsets pageHorizontalCompact = EdgeInsets.symmetric(horizontal: 16);

  static const EdgeInsets allXs = EdgeInsets.all(xs);
  static const EdgeInsets allSm = EdgeInsets.all(sm);
  static const EdgeInsets allMd = EdgeInsets.all(md);
  static const EdgeInsets allLg = EdgeInsets.all(lg);
  static const EdgeInsets allXl = EdgeInsets.all(xl);
  static const EdgeInsets allXxl = EdgeInsets.all(xxl);

  static const EdgeInsets hVxs = EdgeInsets.symmetric(horizontal: xs, vertical: xs);
  static const EdgeInsets hVsm = EdgeInsets.symmetric(horizontal: sm, vertical: sm);
  static const EdgeInsets hVmd = EdgeInsets.symmetric(horizontal: md, vertical: md);
  static const EdgeInsets hVlg = EdgeInsets.symmetric(horizontal: lg, vertical: lg);

  static const EdgeInsets paddingScreen = EdgeInsets.symmetric(horizontal: lg, vertical: md);
  static const EdgeInsets paddingCard = EdgeInsets.all(lg);
  static const EdgeInsets paddingDialog = EdgeInsets.all(xl);
  static const EdgeInsets paddingListItem = EdgeInsets.symmetric(horizontal: md, vertical: sm);
}

/// Radius tokens — shared between buttons, cards, inputs, modals.
class AppRadii {
  AppRadii._();

  static const double radiusXs = 4;
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusX2l = 24;
  static const double radiusFull = 9999;

  static final BorderRadius brXs = BorderRadius.circular(radiusXs);
  static final BorderRadius brSm = BorderRadius.circular(radiusSm);
  static final BorderRadius brMd = BorderRadius.circular(radiusMd);
  static final BorderRadius brLg = BorderRadius.circular(radiusLg);
  static final BorderRadius brXl = BorderRadius.circular(radiusXl);
  static final BorderRadius brX2l = BorderRadius.circular(radiusX2l);
  static final BorderRadius brFull = BorderRadius.circular(radiusFull);
}
