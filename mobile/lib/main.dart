import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:steermate/providers/auth_provider.dart';
import 'package:steermate/providers/trip_provider.dart';
import 'package:steermate/screens/auth/login_screen.dart';
import 'package:steermate/screens/home/home_screen.dart';
import 'package:steermate/services/storage_service.dart';
import 'package:steermate/services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize storage
  await StorageService.init();
  
  // Initialize API service
  ApiService.init();
  
  runApp(const SteerMateApp());
}

class SteerMateApp extends StatelessWidget {
  const SteerMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TripProvider()),
      ],
      child: MaterialApp(
        title: 'SteerMate',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isAuthenticated) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
