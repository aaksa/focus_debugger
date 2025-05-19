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
  final ValueNotifier<String> debugFocusedWidget =
      ValueNotifier<String>('No focus');

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

  void _focusChanged() {
    final primaryFocus = FocusManager.instance.primaryFocus;

    if (primaryFocus?.context != null && _lastInputWasKeyboard) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final currentFocus = FocusManager.instance.primaryFocus;

        // Ensure the focus hasn't changed in the meantime
        if (currentFocus != primaryFocus) {
          // debugPrint(
          //     "FocusDebugger: Focus changed before overlay could be shown.");
          return;
        }

        final context = primaryFocus!.context;

        // Ensure the context is still mounted
        if (context == null || !context.mounted) {
          // debugPrint("FocusDebugger: context is null or unmounted.");
          return;
        }

        final widget = context.widget;

        // 🔐 Skip drawing overlay for generic containers or FocusScope/Focus widget
        // if (widget is Focus ||
        //     widget is FocusScope ||
        //     widget.runtimeType.toString().contains('Semantics')) {
        //   debugPrint(
        //       "FocusDebugger: Skipped widget of type ${widget.runtimeType}");
        //   _focusOverlayController.hideOverlay();
        //   return;
        // }

        final renderObject = context.findRenderObject();

        if (renderObject is! RenderBox ||
            !renderObject.attached ||
            !renderObject.hasSize) {
          // debugPrint("FocusDebugger: renderObject is invalid or not ready.");
          return;
        }

        // debugPrint(
        //     "FocusDebugger: Focused widget = ${context.widget.runtimeType}");

        _focusOverlayController.showOverlay(
          context,
          primaryFocus,
          config,
        );
      });

      // debugPrint("Focus path:");
      // for (var node in FocusManager.instance.rootScope.traversalDescendants) {
      //   debugPrint(
      //       " - ${node.debugLabel ?? node.toString()} ${node.hasFocus ? '(focused)' : ''}");
      // }
    } else {
      _focusOverlayController.hideOverlay();
    }
  }

  void _handlePointerEvent(PointerEvent event) {
    _lastInputWasKeyboard = false;
    if (event is PointerDownEvent) {
      _focusOverlayController.hideOverlay();
      // FocusManager.instance.primaryFocus?.unfocus();
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

      if (size.width == 0 || size.height == 0) return;

      final offset = renderObject.localToGlobal(Offset.zero);

      _overlayEntry = OverlayEntry(
        builder: (context) => FocusDebuggerOverlay(
          offset: offset,
          size: size,
          config: config,
        ),
      );
      Overlay.of(context, rootOverlay: true)?.insert(_overlayEntry!);

      // final overlay = Overlay.maybeOf(context);
      // if (overlay == null || !overlay.mounted) {
      //   debugPrint("FocusDebugger: Overlay not found or not mounted.");
      //   return;
      // }
      // overlay.insert(_overlayEntry!);
    } catch (e, stackTrace) {
      // debugPrint("FocusDebugger error: $e\n$stackTrace");
    }
  }

  void hideOverlay() {
    if (_overlayEntry?.mounted == true) {
      _overlayEntry!.remove();
    }
    _overlayEntry = null;
  }
}
