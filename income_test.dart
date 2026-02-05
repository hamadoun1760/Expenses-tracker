import 'package:flutter/material.dart';
import 'screens/income_list_screen.dart';

void main() {
  runApp(MyIncomeTestApp());
}

class MyIncomeTestApp extends StatelessWidget {
  const MyIncomeTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Income Test',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const IncomeListScreen(),
    );
  }
}