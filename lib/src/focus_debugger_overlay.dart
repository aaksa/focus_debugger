import 'package:flutter/widgets.dart';
import 'package:focus_debugger_flutterflow/focus_debugger_flutterflow.dart';

class FocusDebuggerOverlay extends StatelessWidget {
  const FocusDebuggerOverlay({
    super.key,
    required this.offset,
    required this.size,
    required this.config,
  });

  final Offset offset;
  final Size size;
  final FocusDebuggerConfig config;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      width: size.width,
      height: size.height,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: config.color, width: 2.5),
          // boxShadow: [
          //   BoxShadow(
          //     color: config.color.withOpacity(config.bgOpacity),
          //     blurRadius: 4.0,
          //   ),
          // ],
        ),
      ),
    );
  }
}
