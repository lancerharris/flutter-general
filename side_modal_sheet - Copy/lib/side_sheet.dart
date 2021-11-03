import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';

const Duration _sideSheetEnterDuration = Duration(milliseconds: 250);
const Duration _sideSheetExitDuration = Duration(milliseconds: 200);
const Curve _modalSideSheetCurve = decelerateEasing;
const double _minPositiveFlingVelocity = 700.0;
const double _minNegativeFlingVelocity = -700;
const double _closeProgressThreshold = 0.5;

/// A callback for when the user begins dragging the sheet.
///
/// Used by [SideSheet.onDragStart].
typedef SideSheetDragStartHandler = void Function(DragStartDetails details);

/// A callback for when the user ssides dragging the sheet.
///
/// Used by [SideSheet.onDragEnd].
typedef SideSheetDragEndHandler = void Function(
  DragEndDetails details, {
  required bool isClosing,
});

enum Side { top, right, bottom, left }

class SideSheet extends StatefulWidget {
  /// Creates a side sheet.
  const SideSheet({
    Key? key,
    required this.side,
    this.animationController,
    this.enableDrag = true,
    this.onDragStart,
    this.onDragEnd,
    this.backgroundColor,
    this.elevation,
    this.shape,
    this.clipBehavior,
    this.constraints,
    required this.onClosing,
    required this.builder,
  })  : assert(enableDrag != null),
        assert(onClosing != null),
        assert(builder != null),
        assert(elevation == null || elevation >= 0.0),
        super(key: key);

  final Side side;

  /// The animation controller that controls the sheet's entrance and
  /// exit animations.
  ///
  /// The SideSheet widget will manipulate the position of this animation, it
  /// is not just a passive observer.
  final AnimationController? animationController;

  /// Called when the sheet begins to close.
  ///
  /// A sheet might be prevented from closing (e.g., by user
  /// interaction) even after this callback is called. For this reason, this
  /// callback might be call multiple times for a given Side sheet.
  final VoidCallback onClosing;

  /// A builder for the contents of the sheet.
  ///
  /// The sheet will wrap the widget produced by this builder in a
  /// [Material] widget.
  final WidgetBuilder builder;

  /// If true, the side sheet can be dragged up and down and dismissed by
  /// swiping downwards.
  ///
  /// Default is true.
  final bool enableDrag;

  /// Called when the user begins dragging the side sheet, if
  /// [enableDrag] is true.
  ///
  /// Would typically be used to change the side sheet animation curve so
  /// that it tracks the user's finger accurately.
  final SideSheetDragStartHandler? onDragStart;

  /// Called when the user ssides dragging the side sheet, if [enableDrag]
  /// is true.
  ///
  /// Would typically be used to reset the side sheet animation curve, so
  /// that it animates non-linearly. Called before [onClosing] if the side
  /// sheet is closing.
  final SideSheetDragEndHandler? onDragEnd;

  /// The side sheet's background color.
  ///
  /// Defines the side sheet's [Material.color].
  ///
  /// Defaults to null and falls back to [Material]'s default.
  final Color? backgroundColor;

  /// The z-coordinate at which to place this material relative to its parent.
  ///
  /// This controls the size of the shadow below the material.
  ///
  /// Defaults to 0. The value is non-negative.
  final double? elevation;

  /// The shape of the Side sheet.
  ///
  /// Defines the side sheet's [Material.shape].
  ///
  /// Defaults to null and falls back to [Material]'s default.
  final ShapeBorder? shape;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defines the side sheet's [Material.clipBehavior].
  ///
  /// Use this property to enable clipping of content when the side sheet has
  /// a custom [shape] and the content can extend past this shape. For example,
  /// a side sheet with rounded corners and an edge-to-edge [Image] at the
  /// side.
  ///
  /// If this property is null then [BottomSheetThemeData.clipBehavior] of
  /// [ThemeData.BottomSheetTheme] is used. If that's null then the behavior
  /// will be [Clip.none].
  final Clip? clipBehavior;

  /// Defines minimum and maximum sizes for a [SideSheet].
  ///
  /// Typically a side sheet will cover the entire width of its
  /// parent. However for large screens you may want to limit the width
  /// to something smaller and this property provides a way to specify
  /// a maximum width.
  ///
  /// If null, then the ambient [ThemeData.BottomSheetTheme]'s
  /// [BottomSheetThemeData.constraints] will be used. If that
  /// is null then the side sheet's size will be constrained
  /// by its parent (usually a [Scaffold]).
  ///
  /// If constraints are specified (either in this property or in the
  /// theme), the side sheet will be aligned to the center of
  /// the available space. Otherwise, no alignment is applied.
  final BoxConstraints? constraints;

  @override
  State<SideSheet> createState() => _SideSheetState();

  /// Creates an [AnimationController] suitable for a
  /// [SideSheet.animationController].
  ///
  /// This API available as a convenience for a Material compliant side sheet
  /// animation. If alternative animation durations are required, a different
  /// animation controller could be provided.
  static AnimationController createAnimationController(TickerProvider vsync) {
    return AnimationController(
      duration: _sideSheetEnterDuration,
      reverseDuration: _sideSheetExitDuration,
      debugLabel: 'SideSheet',
      vsync: vsync,
    );
  }
}

class _SideSheetState extends State<SideSheet> {
  final GlobalKey _childKey = GlobalKey(debugLabel: 'SideSheet child');

  double get _childHeight {
    final RenderBox renderBox =
        _childKey.currentContext!.findRenderObject()! as RenderBox;
    return renderBox.size.height;
  }

  double get _childWidth {
    final RenderBox renderBox =
        _childKey.currentContext!.findRenderObject()! as RenderBox;
    return renderBox.size.width;
  }

  bool get _dismissUnderway =>
      widget.animationController!.status == AnimationStatus.reverse;

  void _handleDragStart(DragStartDetails details) {
    widget.onDragStart?.call(details);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    assert(
      widget.enableDrag && widget.animationController != null,
      "'SideSheet.animationController' can not be null when 'SideSheet.enableDrag' is true. "
      "Use 'SideSheet.createAnimationController' to create one, or provide another AnimationController.",
    );
    if (_dismissUnderway) return;
    switch (widget.side) {
      case Side.top:
        widget.animationController!.value +=
            details.primaryDelta! / _childHeight;
        break;
      case Side.bottom:
        widget.animationController!.value -=
            details.primaryDelta! / _childHeight;
        break;
      case Side.right:
        widget.animationController!.value -=
            details.primaryDelta! / _childWidth;
        break;
      case Side.left:
        widget.animationController!.value +=
            details.primaryDelta! / _childWidth;
        break;
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    assert(
      widget.enableDrag && widget.animationController != null,
      "'SideSheet.animationController' can not be null when 'SideSheet.enableDrag' is true. "
      "Use 'SideSheet.createAnimationController' to create one, or provide another AnimationController.",
    );
    if (_dismissUnderway) return;
    bool isClosing = false;
    var dragVelocity = widget.side == Side.top || widget.side == Side.bottom
        ? details.velocity.pixelsPerSecond.dy
        : details.velocity.pixelsPerSecond.dx;
    // handle both negative and positive velocity drags
    if ((widget.side == Side.top || widget.side == Side.left) &&
        dragVelocity < _minNegativeFlingVelocity) {
      final double flingVelocity = dragVelocity / _childHeight;
      if (widget.animationController!.value > 0.0) {
        widget.animationController!.fling(velocity: flingVelocity);
      }
      if (flingVelocity > 0.0) {
        isClosing = true;
      }
    } else if ((widget.side == Side.right || widget.side == Side.bottom) &&
        dragVelocity > _minPositiveFlingVelocity) {
      final double flingVelocity = -dragVelocity / _childHeight;
      if (widget.animationController!.value > 0.0) {
        widget.animationController!.fling(velocity: flingVelocity);
      }
      if (flingVelocity < 0.0) {
        isClosing = true;
      }
    } else if (widget.animationController!.value < _closeProgressThreshold) {
      if (widget.animationController!.value > 0.0)
        widget.animationController!.fling(velocity: -1.0);
      isClosing = true;
    } else {
      widget.animationController!.forward();
    }

    widget.onDragEnd?.call(
      details,
      isClosing: isClosing,
    );

    if (isClosing) {
      widget.onClosing();
    }
  }

  bool extentChanged(DraggableScrollableNotification notification) {
    if (notification.extent == notification.minExtent) {
      widget.onClosing();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final BottomSheetThemeData sideSheetTheme =
        Theme.of(context).bottomSheetTheme;
    final BoxConstraints? constraints =
        widget.constraints ?? sideSheetTheme.constraints;
    final Color? color =
        widget.backgroundColor ?? sideSheetTheme.backgroundColor;
    final double elevation = widget.elevation ?? sideSheetTheme.elevation ?? 0;
    final ShapeBorder? shape = widget.shape ?? sideSheetTheme.shape;
    final Clip clipBehavior =
        widget.clipBehavior ?? sideSheetTheme.clipBehavior ?? Clip.none;

    Widget sideSheet = Material(
      key: _childKey,
      color: color,
      elevation: elevation,
      shape: shape,
      clipBehavior: clipBehavior,
      child: NotificationListener<DraggableScrollableNotification>(
        onNotification: extentChanged,
        child: widget.builder(context),
      ),
    );

    if (constraints != null) {
      sideSheet = Align(
        alignment: Alignment.center,
        heightFactor: 2.0,
        child: ConstrainedBox(
          constraints: constraints,
          child: sideSheet,
        ),
      );
    }

    var dragDirection = widget.side == Side.top || widget.side == Side.bottom
        ? 'vertical'
        : 'horizontal';
    final sideSheetDetector = dragDirection == 'vertical'
        ? GestureDetector(
            onVerticalDragStart: _handleDragStart,
            onVerticalDragUpdate: _handleDragUpdate,
            onVerticalDragEnd: _handleDragEnd,
            excludeFromSemantics: true,
            child: sideSheet,
          )
        : GestureDetector(
            onHorizontalDragStart: _handleDragStart,
            onHorizontalDragUpdate: _handleDragUpdate,
            onHorizontalDragEnd: _handleDragEnd,
            excludeFromSemantics: true,
            child: sideSheet,
          );

    return !widget.enableDrag ? sideSheet : sideSheetDetector;
  }
}

class _ModalSideSheet<T> extends StatefulWidget {
  const _ModalSideSheet({
    Key? key,
    this.route,
    this.backgroundColor,
    this.elevation,
    this.shape,
    this.clipBehavior,
    this.constraints,
    this.isScrollControlled = false,
    this.enableDrag = true,
  })  : assert(isScrollControlled != null),
        assert(enableDrag != null),
        super(key: key);

  final _ModalSideSheetRoute<T>? route;
  final bool isScrollControlled;
  final Color? backgroundColor;
  final double? elevation;
  final ShapeBorder? shape;
  final Clip? clipBehavior;
  final BoxConstraints? constraints;
  final bool enableDrag;

  @override
  _ModalSideSheetState<T> createState() => _ModalSideSheetState<T>();
}

class _ModalSideSheetState<T> extends State<_ModalSideSheet<T>> {
  ParametricCurve<double> animationCurve = _modalSideSheetCurve;

  String _getRouteLabel(MaterialLocalizations localizations) {
    switch (Theme.of(context).platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return '';
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return localizations.dialogLabel;
    }
  }

  void handleDragStart(DragStartDetails details) {
    // Allow the side sheet to track the user's finger accurately.
    animationCurve = Curves.linear;
  }

  void handleDragEnd(DragEndDetails details, {bool? isClosing}) {
    // Allow the side sheet to animate smoothly from its current position.
    animationCurve = _SideSheetSuspendedCurve(
      widget.route!.animation!.value,
      curve: _modalSideSheetCurve,
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    assert(debugCheckHasMaterialLocalizations(context));
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final MaterialLocalizations localizations =
        MaterialLocalizations.of(context);
    final String routeLabel = _getRouteLabel(localizations);

    return AnimatedBuilder(
      animation: widget.route!.animation!,
      child: SideSheet(
        side: widget.route!.side,
        animationController: widget.route!._animationController,
        onClosing: () {
          if (widget.route!.isCurrent) {
            Navigator.pop(context);
          }
        },
        builder: widget.route!.builder!,
        backgroundColor: widget.backgroundColor,
        elevation: widget.elevation,
        shape: widget.shape,
        clipBehavior: widget.clipBehavior,
        constraints: widget.constraints,
        enableDrag: widget.enableDrag,
        onDragStart: handleDragStart,
        onDragEnd: handleDragEnd,
      ),
      builder: (BuildContext context, Widget? child) {
        // Disable the initial animation when accessible navigation is on so
        // that the semantics are added to the tree at the correct time.
        final double animationValue = animationCurve.transform(
          mediaQuery.accessibleNavigation
              ? 1.0
              : widget.route!.animation!.value,
        );
        return Semantics(
          scopesRoute: true,
          namesRoute: true,
          label: routeLabel,
          explicitChildNodes: true,
          child: ClipRect(
            child: CustomSingleChildLayout(
              delegate: _ModalSideSheetLayout(widget.route!.side,
                  animationValue, widget.isScrollControlled),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _ModalSideSheetRoute<T> extends PopupRoute<T> {
  _ModalSideSheetRoute({
    required this.side,
    this.builder,
    required this.capturedThemes,
    this.barrierLabel,
    this.backgroundColor,
    this.elevation,
    this.shape,
    this.clipBehavior,
    this.constraints,
    this.modalBarrierColor,
    this.isDismissible = true,
    this.enableDrag = true,
    required this.isScrollControlled,
    RouteSettings? settings,
    this.transitionAnimationController,
  })  : assert(isScrollControlled != null),
        assert(isDismissible != null),
        assert(enableDrag != null),
        super(settings: settings);

  final Side side;
  final WidgetBuilder? builder;
  final CapturedThemes capturedThemes;
  final bool isScrollControlled;
  final Color? backgroundColor;
  final double? elevation;
  final ShapeBorder? shape;
  final Clip? clipBehavior;
  final BoxConstraints? constraints;
  final Color? modalBarrierColor;
  final bool isDismissible;
  final bool enableDrag;
  final AnimationController? transitionAnimationController;

  @override
  Duration get transitionDuration => _sideSheetEnterDuration;

  @override
  Duration get reverseTransitionDuration => _sideSheetExitDuration;

  @override
  bool get barrierDismissible => isDismissible;

  @override
  final String? barrierLabel;

  @override
  Color get barrierColor => modalBarrierColor ?? Colors.black54;

  AnimationController? _animationController;

  @override
  AnimationController createAnimationController() {
    assert(_animationController == null);
    _animationController = transitionAnimationController ??
        SideSheet.createAnimationController(navigator!.overlay!);
    return _animationController!;
  }

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    // By definition, the bottom sheet is aligned to the bottom of the page
    // and isn't exposed to the side padding of the MediaQuery.
    final Widget sideSheet = MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: Builder(
        builder: (BuildContext context) {
          // keep type BottomSheetThemeData it will be applied to the SideSheet
          final BottomSheetThemeData sheetTheme =
              Theme.of(context).bottomSheetTheme;
          return _ModalSideSheet<T>(
            route: this,
            backgroundColor: backgroundColor ??
                sheetTheme.modalBackgroundColor ??
                sheetTheme.backgroundColor,
            elevation:
                elevation ?? sheetTheme.modalElevation ?? sheetTheme.elevation,
            shape: shape,
            clipBehavior: clipBehavior,
            constraints: constraints,
            isScrollControlled: isScrollControlled,
            enableDrag: enableDrag,
          );
        },
      ),
    );
    return capturedThemes.wrap(sideSheet);
  }
}

// TODO(guidezpl): Look into making this public. A copy of this class is in
//  scaffold.dart, for now, https://github.com/flutter/flutter/issues/51627
/// A curve that progresses linearly until a specified [startingPoint], at which
/// point [curve] will begin. Unlike [Interval], [curve] will not start at zero,
/// but will use [startingPoint] as the Y position.
///
/// For example, if [startingPoint] is set to `0.5`, and [curve] is set to
/// [Curves.easeOut], then the bottom-left quarter of the curve will be a
/// straight line, and the side-right quarter will contain the entire contents of
/// [Curves.easeOut].
///
/// This is useful in situations where a widget must track the user's finger
/// (which requires a linear animation), and afterwards can be flung using a
/// curve specified with the [curve] argument, after the finger is released. In
/// such a case, the value of [startingPoint] would be the progress of the
/// animation at the time when the finger was released.
///
/// The [startingPoint] and [curve] arguments must not be null.
class _SideSheetSuspendedCurve extends ParametricCurve<double> {
  /// Creates a suspended curve.
  const _SideSheetSuspendedCurve(
    this.startingPoint, {
    this.curve = Curves.easeOutCubic,
  })  : assert(startingPoint != null),
        assert(curve != null);

  /// The progress value at which [curve] should begin.
  ///
  /// This defaults to [Curves.easeOutCubic].
  final double startingPoint;

  /// The curve to use when [startingPoint] is reached.
  final Curve curve;

  @override
  double transform(double t) {
    assert(t >= 0.0 && t <= 1.0);
    assert(startingPoint >= 0.0 && startingPoint <= 1.0);

    if (t < startingPoint) {
      return t;
    }

    if (t == 1.0) {
      return t;
    }

    final double curveProgress = (t - startingPoint) / (1 - startingPoint);
    final double transformed = curve.transform(curveProgress);
    return lerpDouble(startingPoint, 1, transformed)!;
  }

  @override
  String toString() {
    return '${describeIdentity(this)}($startingPoint, $curve)';
  }
}

// MODAL Side SHEETS
class _ModalSideSheetLayout extends SingleChildLayoutDelegate {
  _ModalSideSheetLayout(this.side, this.progress, this.isScrollControlled);

  final Side side;
  final double progress;
  final bool isScrollControlled;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints(
      minWidth: 0.0,
      maxWidth: constraints.maxWidth,
      minHeight: 0.0,
      maxHeight: isScrollControlled
          ? constraints.maxHeight
          : constraints.maxHeight * 16.0 / 16.0,
    );
  }

  // TODO: Mark as first component changed= this is the first item that really changes modal position. now its set to be off the side of the screen
  @override
  Offset getPositionForChild(Size size, Size childSize) {
    var xOffset = 0.0;
    var yOffset = 0.0;
    switch (side) {
      case Side.top:
        yOffset = -childSize.height + childSize.height * progress;
        break;
      case Side.bottom:
        yOffset = size.height - childSize.height * progress;
        break;
      case Side.right:
        xOffset = size.width - childSize.width * progress;
        break;
      case Side.left:
        xOffset = -childSize.width + childSize.width * progress;
        break;
    }
    return Offset(xOffset, yOffset);
  }

  @override
  bool shouldRelayout(_ModalSideSheetLayout oldDelegate) {
    return progress != oldDelegate.progress;
  }
}

/// Shows a modal material design side sheet.
///
/// A modal side sheet is an alternative to a menu or a dialog and prevents
/// the user from interacting with the rest of the app.
///
/// A closely related widget is a persistent bottom sheet, which shows
/// information that supplements the primary content of the app without
/// preventing the user from interacting with the app. Persistent bottom sheets
/// can be created and displayed with the [showBottomSheet] function or the
/// [ScaffoldState.showBottomSheet] method.
///
/// The `context` argument is used to look up the [Navigator] and [Theme] for
/// the side sheet. It is only used when the method is called. Its
/// corresponding widget can be safely removed from the tree before the side
/// sheet is closed.
///
/// The `isScrollControlled` parameter specifies whether this is a route for
/// a side sheet that will utilize [DraggableScrollableSheet]. If you wish
/// to have a side sheet that has a scrollable child such as a [ListView] or
/// a [GridView] and have the side sheet be draggable, you should set this
/// parameter to true.
///
/// The `useRootNavigator` parameter ensures that the root navigator is used to
/// display the [SideSheet] when set to `true`. This is useful in the case
/// that a modal [SideSheet] needs to be displayed above all other content
/// but the caller is inside another [Navigator].
///
/// The [isDismissible] parameter specifies whether the side sheet will be
/// dismissed when user taps on the scrim.
///
/// The [enableDrag] parameter specifies whether the side sheet can be
/// dragged up and down and dismissed by swiping downwards.
///
/// The optional [backgroundColor], [elevation], [shape], [clipBehavior],
/// [constraints] and [transitionAnimationController]
/// parameters can be passed in to customize the appearance and behavior of
/// modal side sheets (see the documentation for these on [SideSheet]
/// for more details).
///
/// The [transitionAnimationController] controls the side sheet's entrance and
/// exit animations. It's up to the owner of the controller to call
/// [AnimationController.dispose] when the controller is no longer needed.
///
/// The optional `routeSettings` parameter sets the [RouteSettings] of the modal side sheet
/// sheet. This is particularly useful in the case that a user wants to observe
/// [PopupRoute]s within a [NavigatorObserver].
///
/// Returns a `Future` that resolves to the value (if any) that was passed to
/// [Navigator.pop] when the modal side sheet was closed.
///
/// {@tool dartpad}
/// This example demonstrates how to use `showModalSideSheet` to display a
/// side sheet that obscures the content behind it when a user taps a button.
/// It also demonstrates how to close the side sheet using the [Navigator]
/// when a user taps on a button inside the side sheet.
///
/// ** See code in examples/api/lib/material/bottom_sheet/show_modal_bottom_sheet.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [BottomSheet], which becomes the parent of the widget returned by the
///    function passed as the `builder` argument to [showModalBottomSheet].
///  * [showBottomSheet] and [ScaffoldState.showBottomSheet], for showing
///    non-modal bottom sheets.
///  * [DraggableScrollableSheet], which allows you to create a bottom sheet
///    that grows and then becomes scrollable once it reaches its maximum size.
///  * <https://material.io/design/components/sheets-bottom.html#modal-bottom-sheet>
Future<T?> showModalSideSheet<T>({
  required Side side,
  required BuildContext context,
  required WidgetBuilder builder,
  Color? backgroundColor,
  double? elevation,
  ShapeBorder? shape,
  Clip? clipBehavior,
  BoxConstraints? constraints,
  Color? barrierColor,
  bool isScrollControlled = false,
  bool useRootNavigator = false,
  bool isDismissible = true,
  bool enableDrag = true,
  RouteSettings? routeSettings,
  AnimationController? transitionAnimationController,
}) {
  assert(context != null);
  assert(builder != null);
  assert(isScrollControlled != null);
  assert(useRootNavigator != null);
  assert(isDismissible != null);
  assert(enableDrag != null);
  assert(debugCheckHasMediaQuery(context));
  assert(debugCheckHasMaterialLocalizations(context));

  final NavigatorState navigator =
      Navigator.of(context, rootNavigator: useRootNavigator);
  return navigator.push(_ModalSideSheetRoute<T>(
    side: side,
    builder: builder,
    capturedThemes:
        InheritedTheme.capture(from: context, to: navigator.context),
    isScrollControlled: isScrollControlled,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    backgroundColor: backgroundColor,
    elevation: elevation,
    shape: shape,
    clipBehavior: clipBehavior,
    constraints: constraints,
    isDismissible: isDismissible,
    modalBarrierColor: barrierColor,
    enableDrag: enableDrag,
    settings: routeSettings,
    transitionAnimationController: transitionAnimationController,
  ));
}
