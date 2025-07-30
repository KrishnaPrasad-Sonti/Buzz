import 'package:flutter/material.dart';
import 'frames/userinfo.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BUZZ',
      debugShowCheckedModeBanner: false,
      home: const UserInfoPage(),  
    );
  }
}
