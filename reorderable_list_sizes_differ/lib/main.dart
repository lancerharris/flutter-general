/// Flutter code sample for ReorderableListView

import 'package:flutter/material.dart';
import './new_reorderable_list.dart';

void main() => runApp(const MyApp());

/// This is the main application widget.
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static const String _title = 'Different Size Reorder Sample';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      home: Scaffold(
        appBar: AppBar(title: const Text(_title)),
        body: const MyStatefulWidget(),
      ),
    );
  }
}

/// This is the stateful widget that the main application instantiates.
class MyStatefulWidget extends StatefulWidget {
  const MyStatefulWidget({Key? key}) : super(key: key);

  @override
  State<MyStatefulWidget> createState() => _MyStatefulWidgetState();
}

/// This is the private State class that goes with MyStatefulWidget.
class _MyStatefulWidgetState extends State<MyStatefulWidget> {
  final List<Container> _items = List<Container>.generate(5, (int index) {
    return Container(
      height: (index + 1) % 2 == 0 ? index * 20 + 50 : 30,
      color: Colors.blue,
      child: Text('item $index!'),
    );
  });
  var oldImplementation = false;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          child: Container(
            padding: const EdgeInsets.all(10),
            child: const Text(
                'New implementation allows better behavior when moving around bigger items. Try moving items to the last and second to last positions in the old implementations to see the problem. \nTry draggin way beyond the list to see part of the incorrect animation. \nSlowing animations in dev tools helps to see the issue. \nI still need to figure out how to start the switching earlier than around the 50% mark of the item you are passing.'),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Use old Implementation'),
            Switch(
                value: oldImplementation,
                onChanged: (value) {
                  setState(() {
                    oldImplementation = !oldImplementation;
                  });
                }),
          ],
        ),
        if (!oldImplementation)
          ReorderableListSizesDiffer(
            shrinkWrap: true,
            header: const Text(
              'New implementation',
              textAlign: TextAlign.center,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 40),
            children: <Widget>[
              for (int index = 0; index < _items.length; index++)
                Card(
                  key: Key('$index'),
                  child: _items[index],
                )
            ],
            onReorder: (int oldIndex, int newIndex) {
              setState(() {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                final Container item = _items.removeAt(oldIndex);
                _items.insert(newIndex, item);
              });
            },
          ),
        if (oldImplementation)
          ReorderableListView(
            shrinkWrap: true,
            header: const Text(
              'Old implementation',
              textAlign: TextAlign.center,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 40),
            children: <Widget>[
              for (int index = 0; index < _items.length; index++)
                Card(
                  key: Key('$index'),
                  child: _items[index],
                )
            ],
            onReorder: (int oldIndex, int newIndex) {
              setState(() {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                final Container item = _items.removeAt(oldIndex);
                _items.insert(newIndex, item);
              });
            },
          ),
      ],
    );
  }
}
