import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:gen_ui_demo/features/chat/presentation/chat_home_ui.dart';
import 'package:genui/genui.dart';
import 'package:gen_ui_demo/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Surface GenUI logs in the console for troubleshooting
  configureLogging(logCallback: (level, msg) => debugPrint('GenUI $level: $msg'));

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(fontFamily: "Poppins", useMaterial3: false),
      home: ChatHomeUi(),
      debugShowCheckedModeBanner: false,
    );
  }
}
