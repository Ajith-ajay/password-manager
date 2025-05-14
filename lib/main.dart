import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:password_manager/screens/add_password_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/setup_screen.dart'; // You'll create this next
import 'screens/login_screen.dart'; // You'll create this next
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize secure storage
  const secureStorage = FlutterSecureStorage();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Secure Vault',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/setup': (context) => const SetupScreen(), // Next to implement
        '/login': (context) => const LoginScreen(), // Next to implement
        '/home': (context) => const HomeScreen(),
        '/add-password': (context) => const AddPasswordScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
