import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

/// A custom scroll behavior that enables touch, mouse, and trackpad scrolling
/// across different platforms while maintaining consistent scrollbar behavior.
class CustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };

  @override
  ScrollBehavior copyWith({
    bool? scrollbars,
    ScrollPhysics? physics,
    bool? overscroll,
    Set<PointerDeviceKind>? dragDevices,
    TargetPlatform? platform,
    Set<LogicalKeyboardKey>? pointerAxisModifiers,
    MultitouchDragStrategy? multitouchDragStrategy,
  }) {
    return CustomScrollBehavior();
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const AlwaysScrollableScrollPhysics();
  }

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    switch (getPlatform(context)) {
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return Scrollbar(
          controller: details.controller,
          thumbVisibility: true,
          child: child,
        );
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.iOS:
        return child;
    }
  }

  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}
