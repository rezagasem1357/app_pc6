import 'package:flutter/material.dart';
import '../theme.dart';
import '../storage.dart';
import 'login_role_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _storeName = 'فروشگاه';

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final name = await AppStorage().loadStoreName();
    if (mounted) setState(() => _storeName = name);
    // طبق درخواست: لودینگ ۲ ثانیه‌ای، دقیقاً مثل اسپلش اپ موبایل.
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginRoleScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashGreen,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3),
                    blurRadius: 50,
                    spreadRadius: 10,
                  ),
                ],
                image: const DecorationImage(
                  image: AssetImage('assets/images/logo.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 26),
            Text(
              _storeName,
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'بوستان فرهنگی مذهبی — سامانه حسابداری',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 20),
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
            ),
          ],
        ),
      ),
    );
  }
}
