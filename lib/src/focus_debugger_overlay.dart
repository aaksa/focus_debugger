import 'package:flutter/widgets.dart';
import 'package:focus_debugger_flutterflow/focus_debugger_flutterflow.dart';

class FocusDebuggerOverlay extends StatelessWidget {
  const FocusDebuggerOverlay({
    super.key,
    required this.config,
  });

  final FocusDebuggerConfig config;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: config.color, width: 2.5),
      ),
    );
  }
}
