import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_debugger_flutterflow/focus_debugger_flutterflow.dart';
import 'package:focus_debugger_flutterflow/src/defaults.dart';
import 'package:focus_debugger_flutterflow/src/focus_debugger_overlay.dart';

void main() {
  testWidgets('Shows overlay when widget receives focus', (tester) async {
    final focusNode = FocusNode();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Focus(
            focusNode: focusNode,
            child: const TextField(),
          ),
        ),
      ),
    );

    FocusDebugger.instance.activate();

    focusNode.requestFocus();

    await tester.pumpAndSettle();

    // Checks if an overlay with the specified border color is in the widget tree.
    expect(
      find.byWidgetPredicate((widget) =>
          widget is Container &&
          (widget.decoration as BoxDecoration).border?.top.color ==
              defaultColor),
      findsOneWidget,
    );

    FocusDebugger.instance.deactivate();
  });

  testWidgets('Removes overlay when widget loses focus', (tester) async {
    final focusNode = FocusNode();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Column(
            children: [
              Focus(
                focusNode: focusNode,
                child: const TextField(),
              ),
              Focus(
                onFocusChange: (hasFocus) {
                  FocusManager.instance.primaryFocus?.unfocus();
                  SchedulerBinding.instance.scheduleFrameCallback((timeStamp) {
                    FocusManager.instance.primaryFocus?.unfocus();
                  });
                },
                child: const TextField(),
              ),
            ],
          ),
        ),
      ),
    );

    FocusDebugger.instance.activate();

    focusNode.requestFocus();

    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate((widget) => widget is FocusDebuggerOverlay),
      findsOneWidget,
    );

    // Simulate tapping the second TextField, thus removing the focus from the first one.
    await tester.tap(find.byType(TextField).last);
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate((widget) => widget is FocusDebuggerOverlay),
      findsNothing,
    );

    FocusDebugger.instance.deactivate();
  });

  testWidgets('Overlay respects custom configuration', (tester) async {
    final focusNode = FocusNode();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Focus(
            focusNode: focusNode,
            child: const TextField(),
          ),
        ),
      ),
    );

    FocusDebugger.instance.setConfig(
      const FocusDebuggerConfig(color: Colors.green, bgOpacity: 0.7),
    );
    FocusDebugger.instance.activate();

    focusNode.requestFocus();

    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate((widget) =>
          widget is Container &&
          (widget.decoration as BoxDecoration).border?.top.color ==
              Colors.green),
      findsOneWidget,
    );

    FocusDebugger.instance.deactivate();
  });
}
