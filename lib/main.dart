import 'package:flutter/material.dart';
import 'package:spacex/search.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpaceX Demo',
      home: SearchScreen(),
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
    );
  }
}
