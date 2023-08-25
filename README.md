# Focus debugger

A debugger that listens to FocusManager in order to show a border around the currently focused widget.
Uses Overlay to show the border.

Useful for debugging keyboard navigation or AndroidTV D-pad navigation, TV remotes, etc.

## Usage

```dart
import 'package:focus_debugger/focus_debugger.dart';

Future main() async {
  FocusDebugger.instance.activate();
  runApp(const MyApp());
}
```
