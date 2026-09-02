import 'package:flutter/material.dart';

import '../ui/tokens/spacing.dart';

export '../ui/tokens/spacing.dart';

/// Backward-compatible alias. Legacy code that did
/// `import 'app_spacing.dart'; AppSpacing.lg` keeps working.
///
/// The new canonical token class is [AppSpace] (and [AppRadii]).
@Deprecated('Use AppSpace / AppRadii from core/ui/tokens/spacing.dart instead.')
class AppSpacing {
  AppSpacing._();

  // Spacing
  static const double xs = AppSpace.xs;
  static const double sm = AppSpace.sm;
  static const double md = AppSpace.md;
  static const double lg = AppSpace.lg;
  static const double xl = AppSpace.xl;
  static const double xxl = AppSpace.xxl;
  static const double xxxl = AppSpace.xxxl;

  // Radii
  static const double radiusXs = AppRadii.radiusXs;
  static const double radiusSm = AppRadii.radiusSm;
  static const double radiusMd = AppRadii.radiusMd;
  static const double radiusLg = AppRadii.radiusLg;
  static const double radiusXl = AppRadii.radiusXl;
  static const double radiusXxl = AppRadii.radiusX2l;
  static const double radiusFull = AppRadii.radiusFull;

  // EdgeInsets
  static const EdgeInsets edgeInsetsXs = AppSpace.allXs;
  static const EdgeInsets edgeInsetsSm = AppSpace.allSm;
  static const EdgeInsets edgeInsetsMd = AppSpace.allMd;
  static const EdgeInsets edgeInsetsLg = AppSpace.allLg;
  static const EdgeInsets edgeInsetsXl = AppSpace.allXl;
  static const EdgeInsets edgeInsetsXxl = AppSpace.allXxl;

  static const EdgeInsets paddingScreen = AppSpace.paddingScreen;
  static const EdgeInsets paddingCard = AppSpace.paddingCard;
  static const EdgeInsets paddingDialog = AppSpace.paddingDialog;
  static const EdgeInsets paddingListItem = AppSpace.paddingListItem;

  // BorderRadius
  static final BorderRadius borderRadiusSm = AppRadii.brSm;
  static final BorderRadius borderRadiusMd = AppRadii.brMd;
  static final BorderRadius borderRadiusLg = AppRadii.brLg;
  static final BorderRadius borderRadiusXl = AppRadii.brXl;
  static final BorderRadius borderRadiusFull = AppRadii.brFull;
}
