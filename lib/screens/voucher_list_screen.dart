import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models.dart';
import '../storage.dart';
import '../date_utils.dart';
import 'voucher_entry_screen.dart';

class VoucherListScreen extends StatefulWidget {
  const VoucherListScreen({super.key});

  @override
  State<VoucherListScreen> createState() => _VoucherListScreenState();
}

class _VoucherListScreenState extends State<VoucherListScreen> {
  final _storage = AppStorage();
  List<Voucher> _vouchers = [];
  Map<String, int> _dailyNumbers = {};
  bool _loading = true;
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _storage.loadVouchers();
    list.sort((a, b) {
      final byDate = compareJalaliDates(a.date, b.date);
      if (byDate != 0) return byDate;
      return a.number.compareTo(b.number);
    });
    if (mounted) setState(() {
      _vouchers = list;
      _dailyNumbers = computeDailyNumbers(list);
      _loading = false;
    });
  }

  List<Voucher> get _filtered {
    if (_fromCtrl.text.trim().isEmpty && _toCtrl.text.trim().isEmpty) return _vouchers;
    return _vouchers.where((v) {
      if (_fromCtrl.text.trim().isNotEmpty &&
          compareJalaliDates(v.date, _fromCtrl.text.trim()) < 0) {
        return false;
      }
      if (_toCtrl.text.trim().isNotEmpty &&
          compareJalaliDates(v.date, _toCtrl.text.trim()) > 0) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> _openVoucher([Voucher? v]) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => VoucherEntryScreen(existing: v)),
    );
    if (changed == true) _load();
  }

  Future<void> _deleteVoucher(Voucher v) async {
    if (v.status == VoucherStatus.permanent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سند دائم قابل حذف نیست.')),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('حذف سند شماره ${toPersianDigits(v.number.toString())}'),
        content: const Text('این سند موقت حذف شود؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('انصراف')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final list = await _storage.loadVouchers();
    list.removeWhere((x) => x.id == v.id);
    final renumbered = renumberVouchersByDate(list);
    await _storage.saveVouchers(renumbered);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.f3): () => _openVoucher(),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
      appBar: AppBar(
        title: const Text('اسناد حسابداری'),
        actions: [
          IconButton(
            tooltip: 'سند جدید (F3)',
            icon: const Icon(Icons.add),
            onPressed: () => _openVoucher(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _fromCtrl,
                          textDirection: TextDirection.rtl,
                          decoration: const InputDecoration(
                            labelText: 'از تاریخ (مثال: 1403/01/01)',
                            prefixIcon: Icon(Icons.filter_alt_outlined),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _toCtrl,
                          textDirection: TextDirection.rtl,
                          decoration: const InputDecoration(labelText: 'تا تاریخ'),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        tooltip: 'پاک‌کردن فیلتر',
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _fromCtrl.clear();
                          _toCtrl.clear();
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _filtered.isEmpty
                        ? const Center(child: Text('سندی برای نمایش وجود ندارد.'))
                        : ListView.builder(
                            itemCount: _filtered.length,
                            itemBuilder: (context, i) {
                              final v = _filtered[i];
                              final isPermanent = v.status == VoucherStatus.permanent;
                              return Card(
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isPermanent
                                        ? Colors.green.shade100
                                        : Colors.orange.shade100,
                                    child: Text(toPersianDigits(v.number.toString())),
                                  ),
                                  title: Text(v.description.isEmpty ? '(بدون شرح)' : v.description),
                                  subtitle: Text(
                                      '${toPersianDigits(v.date)} (سند شماره ${toPersianDigits((_dailyNumbers[v.id] ?? 1).toString())} همان روز)  •  ${isPermanent ? 'دائم' : 'موقت'}  •  جمع: ${toPersianDigits(v.totalDebit.toString())} ریال'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (!isPermanent)
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                                          onPressed: () => _deleteVoucher(v),
                                        ),
                                      const Icon(Icons.chevron_left),
                                    ],
                                  ),
                                  onTap: () => _openVoucher(v),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
        ),
      ),
    );
  }
}
