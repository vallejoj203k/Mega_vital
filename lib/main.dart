// lib/main.dart
import 'package:flutter/material.dart';
import 'app/app.dart';
import 'services/api_key_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Firebase (descomenta cuando hagas flutterfire configure) ──
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

  await ApiKeyManager.instance.load();
  runApp(const GymApp());
}
