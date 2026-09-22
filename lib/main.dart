import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const StoreAccountingApp());
}

class StoreAccountingApp extends StatelessWidget {
  const StoreAccountingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'حسابداری فروشگاه',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      locale: const Locale('fa', 'IR'),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const SplashScreen(),
    );
  }
}
