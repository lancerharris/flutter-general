/// Flutter code sample for showModalSideSheet

// This example demonstrates how to use `showModalSideSheet` to display a
// sheet that obscures the content behind it when a user taps a button.
// It also demonstrates how to close the sheet using the [Navigator]
// when a user taps on a button inside the sheet.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'side_sheet.dart';

void main() => runApp(const MyApp());

/// This is the main application widget.
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static const String _title = 'Flutter Code Sample';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      home: Scaffold(
        appBar: AppBar(title: const Text(_title)),
        body: const MyStatelessWidget(),
      ),
    );
  }
}

/// This is the stateless widget that the main application instantiates.
class MyStatelessWidget extends StatelessWidget {
  const MyStatelessWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          ButtonForModal(
              buttonText: 'show sideSheetModel from top', side: Side.top),
          SizedBox(height: 10),
          ButtonForModal(
              buttonText: 'show sideSheetModel from bottom', side: Side.bottom),
          SizedBox(height: 10),
          ButtonForModal(
              buttonText: 'show sideSheetModel from right', side: Side.right),
          SizedBox(height: 10),
          ButtonForModal(
              buttonText: 'show sideSheetModel from left', side: Side.left),
        ],
      ),
    );
  }
}

class ButtonForModal extends StatelessWidget {
  const ButtonForModal({Key? key, required this.buttonText, required this.side})
      : super(key: key);
  final String buttonText;
  final Side side;
  @override
  Widget build(BuildContext context) {
    String modalSheetText;
    switch (side) {
      case Side.top:
        modalSheetText = 'TopSheet';
        break;
      case Side.bottom:
        modalSheetText = 'BottomSheet';
        break;
      case Side.right:
        modalSheetText = 'RightSheet';
        break;
      case Side.left:
        modalSheetText = 'LeftSheet';
        break;
    }

    return ElevatedButton(
      child: Text(buttonText),
      onPressed: () {
        showModalSideSheet<void>(
          side: side, // top right, bottom, or left
          context: context,
          builder: (BuildContext context) {
            return Container(
              height: (side == Side.top) || (side == Side.bottom) ? 400 : null,
              width: (side == Side.right) || (side == Side.left) ? 300 : null,
              color: Colors.amber,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text('Modal $modalSheetText'),
                    ElevatedButton(
                      child: Text('Close $modalSheetText'),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
