library focus_debugger;

import 'package:flutter/widgets.dart';
import 'package:focus_debugger/src/defaults.dart';

import 'focus_debugger_overlay.dart';

/// A focus debugger that listens to [FocusManager] in order to show a border around the currently focused widget.
/// Uses [Overlay] to show the border.
class FocusDebugger {
  FocusDebugger._();

  static FocusDebugger instance = FocusDebugger._();

  final _FocusOverlayController _focusOverlayController =
      _FocusOverlayController();
  FocusDebuggerConfig config = const FocusDebuggerConfig();

  /// Sets the configuration for the focus debugger.
  /// Takes effect starting with the next focus change.
  void setConfig(FocusDebuggerConfig config) {
    this.config = config;
  }

  /// Activates the focus debugger.
  void activate() {
    WidgetsFlutterBinding.ensureInitialized();
    FocusManager.instance.addListener(_focusChanged);
  }

  /// Deactivates the focus debugger and removes any currently visible overlay.
  void deactivate() {
    _focusOverlayController.hideOverlay();
    FocusManager.instance.removeListener(_focusChanged);
  }

  void _focusChanged() {
    final primaryFocus = FocusManager.instance.primaryFocus;
    if (primaryFocus?.context != null) {
      _focusOverlayController.showOverlay(
          primaryFocus!.context!, primaryFocus, config);
    } else {
      _focusOverlayController.hideOverlay();
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
