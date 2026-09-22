import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network_service.dart';

class ServerSettingsTab extends StatefulWidget {
  const ServerSettingsTab({super.key});

  @override
  State<ServerSettingsTab> createState() => _ServerSettingsTabState();
}

class _ServerSettingsTabState extends State<ServerSettingsTab> {
  final _service = NetworkService();
  final _baseUrlCtrl = TextEditingController();
  final _anonKeyCtrl = TextEditingController();
  final _storeIdCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  bool _autoSync = true;
  bool _loading = true;
  bool _testing = false;
  String? _testResult;
  bool _testOk = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cfg = await _service.loadConfig();
    _baseUrlCtrl.text = cfg.baseUrl;
    _anonKeyCtrl.text = cfg.anonKey;
    _storeIdCtrl.text = cfg.storeId;
    _licenseCtrl.text = cfg.license;
    _autoSync = cfg.autoSync;
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    await _service.saveConfig(
      baseUrl: _baseUrlCtrl.text.trim(),
      anonKey: _anonKeyCtrl.text.trim(),
      storeId: _storeIdCtrl.text.trim(),
      role: 'accounting',
      autoSync: _autoSync,
    );
    // NetworkService لایسنس را از کلید 'user_license' می‌خواند (همان کلیدی که
    // اپ موبایل هنگام ورود ذخیره می‌کند)؛ چون این اپ صفحه ورود جداگانه ندارد،
    // همان کلید را مستقیماً اینجا می‌نویسیم تا با اپ موبایل هم‌خوان بماند.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_license', _licenseCtrl.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تنظیمات ذخیره شد ✅')));
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });
    await _save();
    final result = await _service.testConnection();
    if (mounted) {
      setState(() {
        _testing = false;
        _testResult = result.message;
        _testOk = result.success;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text(
          'برای اتصال به همان سروری که اپ موبایل صندوق/مدیریت استفاده می‌کند، '
          'همان مشخصات (آدرس سرور، کلید، شناسه فروشگاه و لایسنس) را اینجا هم وارد کنید.',
          style: TextStyle(fontSize: 12.5, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _baseUrlCtrl,
          textDirection: TextDirection.ltr,
          decoration: const InputDecoration(labelText: 'آدرس سرور (Base URL)'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _anonKeyCtrl,
          textDirection: TextDirection.ltr,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'کلید (anon key)'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _storeIdCtrl,
          textDirection: TextDirection.rtl,
          decoration: const InputDecoration(labelText: 'شناسه فروشگاه (store id)'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _licenseCtrl,
          textDirection: TextDirection.ltr,
          decoration: const InputDecoration(labelText: 'کد لایسنس (همان لایسنس اپ موبایل)'),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          value: _autoSync,
          onChanged: (v) => setState(() => _autoSync = v),
          title: const Text('همگام‌سازی خودکار'),
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            ElevatedButton(onPressed: _save, child: const Text('ذخیره تنظیمات')),
            OutlinedButton(
              onPressed: _testing ? null : _testConnection,
              child: Text(_testing ? 'در حال بررسی...' : 'تست اتصال'),
            ),
          ],
        ),
        if (_testResult != null) ...[
          const SizedBox(height: 14),
          Text(
            _testResult!,
            style: TextStyle(color: _testOk ? Colors.green.shade700 : Colors.red, fontWeight: FontWeight.bold),
          ),
        ],
      ],
    );
  }
}
