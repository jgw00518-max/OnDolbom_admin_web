import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondolbom_admin/firebase_options.dart';
import 'package:ondolbom_admin/view/admin_gate.dart';

Future<void> main() async {
  // Web 앱 설정으로 Firebase를 초기화한 뒤 공통 Riverpod 상태를 시작한다.
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const ProviderScope(child: MyApp()));
  } catch (_) {
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Firebase 초기화에 실패했습니다. 관리자 Web 앱 설정을 확인해 주세요.'),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '온돌봄 관리자',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFAD5B32)),
      useMaterial3: true,
    ),
    home: const AdminGate(),
  );
}
