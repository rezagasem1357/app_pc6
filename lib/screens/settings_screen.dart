import 'package:flutter/material.dart';
import '../storage.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storage = AppStorage();
  final _nameCtrl = TextEditingController();
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _nameCtrl.text = await _storage.loadStoreName();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveName() async {
    setState(() => _busy = true);
    await _storage.saveStoreName(_nameCtrl.text.trim());
    if (mounted) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ذخیره شد ✅')));
    }
  }

  Future<void> _renumberNow() async {
    setState(() => _busy = true);
    final vouchers = await _storage.loadVouchers();
    final renumbered = renumberVouchersByDate(vouchers);
    await _storage.saveVouchers(renumbered);
    if (mounted) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('شماره‌گذاری اسناد بر اساس تاریخ صدور، از ۱ به بعد، بازچینی شد.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('تنظیمات')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text('نام فروشگاه', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameCtrl,
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(hintText: 'نام فروشگاه برای نمایش در صفحه ورود'),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(onPressed: _busy ? null : _saveName, child: const Text('ذخیره')),
            ],
          ),
          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 10),
          const Text('شماره‌گذاری اسناد حسابداری', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'شماره سند حسابداری همیشه از ۱ شروع شده و به‌صورت خودکار بر اساس '
              'تاریخ صدور سند مرتب می‌شود؛ یعنی اگر سندی با تاریخ قدیمی‌تر اضافه '
              'شود، شماره‌های بعد از آن به‌طور خودکار به‌روزرسانی می‌شوند. این '
              'کار بعد از هر ثبت/ویرایش/حذف سند به‌طور خودکار انجام می‌شود.',
              style: TextStyle(fontSize: 13, height: 1.6),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy ? null : _renumberNow,
            icon: const Icon(Icons.refresh),
            label: const Text('بازچینی دستی شماره اسناد (در صورت نیاز)'),
          ),
        ],
      ),
    );
  }
}
