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

## Additional information

TODO: Tell users more about the package: where to find more information, how to
contribute to the package, how to file issues, what response they can expect
from the package authors, and more.
