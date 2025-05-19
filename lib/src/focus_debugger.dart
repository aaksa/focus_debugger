library focus_debugger_flutterflow;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'defaults.dart';

import 'focus_debugger_overlay.dart';

/// A focus debugger that listens to [FocusManager] in order to show a border around the currently focused widget.
/// Uses [Overlay] to show the border.
class FocusDebugger {
  FocusDebugger._();

  static FocusDebugger instance = FocusDebugger._();

  final _FocusOverlayController _focusOverlayController =
      _FocusOverlayController();
  FocusDebuggerConfig config = const FocusDebuggerConfig();
  bool _active = false;
  bool _lastInputWasKeyboard = false;

  /// Sets the configuration for the focus debugger.
  /// Takes effect starting with the next focus change.
  void setConfig(FocusDebuggerConfig config) {
    this.config = config;
  }

  /// Activates the focus debugger.
  void activate() {
    if (_active) return;
    _active = true;
    WidgetsFlutterBinding.ensureInitialized();
    FocusManager.instance.addListener(_focusChanged);
    WidgetsBinding.instance.pointerRouter.addGlobalRoute(_handlePointerEvent);
    RawKeyboard.instance.addListener(_handleRawKeyEvent); // <- Add this
  }

  /// Deactivates the focus debugger and removes any currently visible overlay.
  void deactivate() {
    if (!_active) return;
    _focusOverlayController.hideOverlay();
    FocusManager.instance.removeListener(_focusChanged);
    WidgetsBinding.instance.pointerRouter
        .removeGlobalRoute(_handlePointerEvent);
    RawKeyboard.instance.removeListener(_handleRawKeyEvent); // <- Add this
    _active = false;
  }

  // void _focusChanged() {
  //   final primaryFocus = FocusManager.instance.primaryFocus;

  //   if (primaryFocus?.context != null && _lastInputWasKeyboard) {
  //     _focusOverlayController.showOverlay(
  //       primaryFocus!.context!,
  //       primaryFocus,
  //       config,
  //     );
  //   } else {
  //     _focusOverlayController.hideOverlay();
  //   }
  // }

  void _focusChanged() {
    final primaryFocus = FocusManager.instance.primaryFocus;

    if (primaryFocus?.context != null && _lastInputWasKeyboard) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusOverlayController.showOverlay(
          primaryFocus!.context!,
          primaryFocus,
          config,
        );
      });
    } else {
      _focusOverlayController.hideOverlay();
    }
  }

  void _handlePointerEvent(PointerEvent event) {
    if (event is PointerDownEvent) {
      _lastInputWasKeyboard = false; // mouse or touch
      _focusOverlayController.hideOverlay();
      FocusManager.instance.primaryFocus?.unfocus(); // <- Add this line
    }
  }

  void _handleRawKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      _lastInputWasKeyboard = true;
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
    _overlayEntry?.remove();

    final renderObject = node.context!.findRenderObject() as RenderBox;
    if (!renderObject.hasSize) {
      return;
    }

    // Calculate the position and size of the focused widget.
    final offset = renderObject.localToGlobal(Offset.zero);
    final size = renderObject.size;
    if (size.width == 0 || size.height == 0) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => FocusDebuggerOverlay(
        offset: offset,
        size: size,
        config: config,
      ),
    );

    // Insert the OverlayEntry into the overlay.
    Overlay.maybeOf(context)?.insert(_overlayEntry!);
  }

  void hideOverlay() {
    if (_overlayEntry?.mounted == true) {
      _overlayEntry!.remove();
    }
    _overlayEntry = null;
  }
}
