import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/photo_provider.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const CleanSnapApp());
}

class CleanSnapApp extends StatelessWidget {
  const CleanSnapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => PhotoProvider())],
      child: MaterialApp(
        title: 'Clean Snap',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: Colors.blueAccent,
          scaffoldBackgroundColor: Colors.black,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            elevation: 0,
          ),
          colorScheme: ColorScheme.dark(
            primary: Colors.blueAccent,
            secondary: Colors.redAccent,
            surface: Colors.grey[900]!,
          ),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
