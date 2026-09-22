import 'package:flutter/material.dart';
import '../network_service.dart';
import '../date_utils.dart';
import 'server_settings_tab.dart';

/// این صفحه دقیقاً همان فید مشترکی را می‌خواند که اپ موبایل صندوق/مدیریت با
/// آن گزارش عملکرد صندوق‌داران، تغییرات قیمت مدیر و گزارش‌های حسابداری را رد
/// و بدل می‌کند (NetworkService.fetchRecentEvents). این‌جا فقط نمایش (خواندن)
/// است؛ برای نوشتن گزارش قیمت به مدیر یک تب جداگانه لازم است (فاز بعد).
class ServerReportsScreen extends StatefulWidget {
  const ServerReportsScreen({super.key});

  @override
  State<ServerReportsScreen> createState() => _ServerReportsScreenState();
}

class _ServerReportsScreenState extends State<ServerReportsScreen> with SingleTickerProviderStateMixin {
  final _service = NetworkService();
  late final TabController _tabs = TabController(length: 5, vsync: this);
  List<Map<String, dynamic>> _events = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cfg = await _service.loadConfig();
      if (!cfg.isConfigured) {
        setState(() {
          _loading = false;
          _error = 'ابتدا در تب «تنظیمات اتصال» مشخصات سرور را وارد و ذخیره کنید.';
        });
        return;
      }
      final events = await _service.fetchRecentEvents(limit: 300);
      if (mounted) {
        setState(() {
          _events = events;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'خطا در دریافت اطلاعات: $e';
        });
      }
    }
  }

  List<Map<String, dynamic>> _byType(List<String> types) =>
      _events.where((e) => types.contains(e['type']?.toString())).toList();

  List<Map<String, dynamic>> _byAction(List<String> actions) {
    return _events.where((e) {
      if (e['type']?.toString() != 'cashier_performance') return false;
      final p = Map<String, dynamic>.from(e['payload'] ?? {});
      return actions.contains(p['action']?.toString());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ارتباط با سرور'),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: const Color(0xFFD6B65A),
          tabs: const [
            Tab(text: 'تنظیمات اتصال'),
            Tab(text: 'فروش صندوق‌داران'),
            Tab(text: 'هزینه‌های روزانه'),
            Tab(text: 'گزارش‌های مدیریت'),
            Tab(text: 'حذف‌ها'),
          ],
        ),
        actions: [
          IconButton(tooltip: 'به‌روزرسانی', icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          const ServerSettingsTab(),
          _buildEventList(_byAction(['sales_invoice']), _saleTile),
          _buildEventList(_byAction(['daily_expense']), _expenseTile),
          _buildEventList(_byType(['manager_price_change', 'manager_cheque_action', 'accounting_report']), _managerTile),
          _buildEventList(_byAction(['invoice_deleted', 'expense_deleted', 'manifest_deleted']), _deletionTile),
        ],
      ),
    );
  }

  Widget _buildEventList(List<Map<String, dynamic>> list, Widget Function(Map<String, dynamic>) tileBuilder) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
        ),
      );
    }
    if (list.isEmpty) {
      return const Center(child: Text('موردی برای نمایش وجود ندارد.'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: list.map((e) => Card(child: tileBuilder(e))).toList(),
      ),
    );
  }

  Widget _saleTile(Map<String, dynamic> e) {
    final p = Map<String, dynamic>.from(e['payload'] ?? {});
    final user = (e['actor_name'] ?? '').toString();
    return ListTile(
      leading: const Icon(Icons.receipt_long, color: Colors.teal),
      title: Text('صندوق‌دار $user: فاکتور شماره ${p['invoice_number'] ?? ''}'),
      subtitle: Text('${p['date'] ?? ''}\nمبلغ: ${toPersianDigits((p['total'] ?? 0).toString())} ریال'),
      isThreeLine: true,
    );
  }

  Widget _expenseTile(Map<String, dynamic> e) {
    final p = Map<String, dynamic>.from(e['payload'] ?? {});
    final user = (e['actor_name'] ?? '').toString();
    return ListTile(
      leading: const Icon(Icons.payments_outlined, color: Colors.orange),
      title: Text('صندوق‌دار $user: هزینه «${p['name'] ?? ''}»'),
      subtitle: Text('${p['date'] ?? ''}\nمبلغ: ${toPersianDigits((p['amount'] ?? 0).toString())} ریال'),
      isThreeLine: true,
    );
  }

  Widget _managerTile(Map<String, dynamic> e) {
    final p = Map<String, dynamic>.from(e['payload'] ?? {});
    final user = (e['actor_name'] ?? '').toString();
    final type = e['type']?.toString() ?? '';
    final label = {
      'manager_price_change': 'تغییر قیمت توسط مدیر',
      'manager_cheque_action': 'اقدام روی چک توسط مدیر',
      'accounting_report': 'گزارش حسابداری',
    }[type] ?? type;
    return ListTile(
      leading: const Icon(Icons.admin_panel_settings_outlined, color: Colors.indigo),
      title: Text('$label — $user'),
      subtitle: Text(p.toString(), maxLines: 3, overflow: TextOverflow.ellipsis),
    );
  }

  Widget _deletionTile(Map<String, dynamic> e) {
    final p = Map<String, dynamic>.from(e['payload'] ?? {});
    final user = (e['actor_name'] ?? '').toString();
    final role = p['user_role']?.toString() == 'manager' ? 'مدیر' : 'صندوق‌دار';
    const labels = {
      'invoice_deleted': 'حذف فاکتور فروش',
      'expense_deleted': 'حذف هزینه روزانه',
      'manifest_deleted': 'حذف بارنامه',
    };
    final action = p['action']?.toString() ?? '';
    final reason = (p['reason']?.toString().isNotEmpty ?? false) ? p['reason'].toString() : 'رویداد مالی حذف شد و در حسابداری ارسال نشد';
    final ref = p['reference']?.toString() ?? '';
    return ListTile(
      leading: const Icon(Icons.delete_forever, color: Colors.red),
      title: Text('$role $user: ${labels[action] ?? action}${ref.isNotEmpty ? ' ($ref)' : ''}'),
      subtitle: Text('علت: $reason${p['date'] != null ? '\n${p['date']}' : ''}'),
      isThreeLine: true,
    );
  }
}
