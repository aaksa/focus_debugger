library focus_debugger_flutterflow;

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'defaults.dart';

import 'focus_debugger_overlay.dart';

/// A focus debugger that listens to [FocusManager] in order to show a border around the currently focused widget.
/// Uses [Overlay] to show the border.
class FocusDebugger {
  FocusDebugger._();
  Timer? _scrollEndTimer;

  static FocusDebugger instance = FocusDebugger._();

  final _FocusOverlayController _focusOverlayController =
      _FocusOverlayController();
  FocusDebuggerConfig config = const FocusDebuggerConfig();
  bool _active = false;
  bool _lastInputWasKeyboard = false;
  final ValueNotifier<String> debugFocusedWidget =
      ValueNotifier<String>('No focus');
  bool _pointerScrollInProgress = false;

  /// Sets the configuration for the focus debugger.
  /// Takes effect starting with the next focus change.
  void setConfig(FocusDebuggerConfig config) {
    this.config = config;
  }

  /// Activates the focus debugger immediately.
  /// (You probably won't call this manually now.)
  void activate() {
    if (_active) return;
    _activateInternal();
  }

  /// Internal activation logic
  void _activateInternal() {
    _active = true;
    WidgetsFlutterBinding.ensureInitialized();
    FocusManager.instance.addListener(_focusChanged);
    WidgetsBinding.instance.pointerRouter.addGlobalRoute(_handlePointerEvent);
    RawKeyboard.instance.addListener(_handleRawKeyEvent);
  }

  /// Deactivates the focus debugger and removes any currently visible overlay.
  void deactivate() {
    if (!_active) return;
    _focusOverlayController.hideOverlay();
    FocusManager.instance.removeListener(_focusChanged);
    WidgetsBinding.instance.pointerRouter
        .removeGlobalRoute(_handlePointerEvent);
    RawKeyboard.instance.removeListener(_handleRawKeyEvent);
    _active = false;
  }

  Timer? _focusChangeDebounce;

  void _focusChanged() {
    _focusChangeDebounce?.cancel();

    // Don’t act if scroll or pointer activity is ongoing
    if (!_lastInputWasKeyboard || _pointerScrollInProgress) {
      _focusOverlayController.hideOverlay();
      return;
    }

    // Delay application slightly in case of rapid pointer or scroll activity
    _focusChangeDebounce = Timer(const Duration(milliseconds: 150), () {
      final primaryFocus = FocusManager.instance.primaryFocus;

      if (primaryFocus?.context != null && primaryFocus!.context!.mounted) {
        final renderObject = primaryFocus.context!.findRenderObject();

        if (renderObject is! RenderBox ||
            !renderObject.attached ||
            !renderObject.hasSize) {
          return;
        }

        _focusOverlayController.showOverlay(
          primaryFocus.context!,
          primaryFocus,
          config,
        );
      }
    });
  }

  void _handlePointerEvent(PointerEvent event) {
    if (event is PointerScrollEvent) {
      _pointerScrollInProgress = true;

      _focusOverlayController.hideOverlay();
      // Cancel any previous timer
      _scrollEndTimer?.cancel();

      // Start a new timer that fires after 500ms (adjust delay as needed)
      _scrollEndTimer = Timer(const Duration(milliseconds: 200), () {
        // Called after user stops scrolling for 500ms
        _pointerScrollInProgress = false;
        refreshOverlay();
      });
    }

    if (event is PointerDownEvent) {
      _lastInputWasKeyboard = false;
      _focusOverlayController.hideOverlay();
    }
  }

  // void _handlePointerEvent(PointerEvent event) {
  //   _lastInputWasKeyboard = false;
  //   if (event is PointerDownEvent) {
  //     _focusOverlayController.hideOverlay();
  //     // FocusManager.instance.primaryFocus?.unfocus();
  //   }
  // }

  void refreshOverlay() {
    final primaryFocus = FocusManager.instance.primaryFocus;
    final context = primaryFocus?.context;

    if (context != null && context.mounted && _lastInputWasKeyboard) {
      _focusOverlayController.hideOverlay();
      _focusOverlayController.showOverlay(context, primaryFocus!, config);
    }
  }

  void _handleRawKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      // Activate only on Tab key
      if (event.logicalKey == LogicalKeyboardKey.tab) {
        _lastInputWasKeyboard = true;
        if (!_active) {
          _activateInternal();
        }
      }
    }
  }
}

class FocusDebuggerConfig {
  const FocusDebuggerConfig({
    this.color = defaultColor,
    this.bgOpacity = 0.5,
  });

  final Color color;
  final double bgOpacity;
}

class _FocusOverlayController {
  OverlayEntry? _overlayEntry;

  void showOverlay(
      BuildContext context, FocusNode node, FocusDebuggerConfig config) {
    if (_overlayEntry != null && _overlayEntry!.mounted) {
      _overlayEntry!.remove();
    }
    // _overlayEntry?.remove();

    try {
      final renderObject = node.context?.findRenderObject();

      if (renderObject is! RenderBox ||
          !renderObject.attached ||
          !renderObject.hasSize) {
        // debugPrint("FocusDebugger: Cannot show overlay — invalid RenderBox.");
        return;
      }

      final size = renderObject.size;

      // ✅ Skip internal Flutter focus scopes
      if (context.widget.runtimeType.toString().contains('FocusScope')) {
        // debugPrint(
        //     "FocusDebugger: Skipped internal widget = ${context.widget.runtimeType}");
        return;
      }

      // Skip if widget is an internal focus scope
      if (context.widget.runtimeType.toString().contains('FocusScope') ||
          context.widget.runtimeType
              .toString()
              .contains('FocusScopeWithExternalFocusNode')) {
        // debugPrint(
        //     "FocusDebugger: Skipping internal focus widget = ${context.widget.runtimeType}");
        return;
      }

      final screenSize = MediaQuery.of(context).size;

      // debugPrint(
      //     "screen width ${screenSize.width}, height ${screenSize.height}");
      // print(size);
      // debugPrint("width ${size.width.toString()}");
      // debugPrint("heigt ${size.height.toString()}");

// Skip if widget takes the full screen (or nearly full screen)
      if ((size.width >= screenSize.width &&
              size.height >= screenSize.height) ||
          size.width == 0 ||
          size.height == 0) {
        // debugPrint(
        //     "FocusDebugger: Skipping overlay for full-screen or zero-size widget.");
        return;
      }
      final offset = renderObject.localToGlobal(Offset.zero);

      // _overlayEntry = OverlayEntry(
      //   builder: (context) => FocusDebuggerOverlay(
      //     offset: offset,
      //     size: size,
      //     config: config,
      //   ),
      // );
      _overlayEntry = OverlayEntry(
        builder: (context) => Stack(
          children: [
            Positioned(
              left: offset.dx,
              top: offset.dy,
              width: size.width,
              height: size.height,
              child: IgnorePointer(
                ignoringSemantics: true,
                ignoring: true,
                child: FocusDebuggerOverlay(config: config),
              ),
            ),
          ],
        ),
      );

      Overlay.maybeOf(context)?.insert(_overlayEntry!);
    } catch (e, stackTrace) {
      debugPrint("FocusDebugger error: $e\n$stackTrace");
    }
  }

  void hideOverlay() {
    if (_overlayEntry?.mounted == true) {
      _overlayEntry!.remove();
    }
    _overlayEntry = null;
  }

  // void hideOverlay() {
  //   try {
  //     if (_overlayEntry?.mounted == true) {
  //       _overlayEntry!.remove();
  //     }
  //   } catch (e) {
  //     debugPrint("FocusDebugger: Error removing overlay: $e");
  //   } finally {
  //     _overlayEntry = null;
  //   }
  // }
}
