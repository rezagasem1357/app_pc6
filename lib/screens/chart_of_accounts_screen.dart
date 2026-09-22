import 'package:flutter/material.dart';
import '../models.dart';
import '../storage.dart';

class ChartOfAccountsScreen extends StatefulWidget {
  const ChartOfAccountsScreen({super.key});

  @override
  State<ChartOfAccountsScreen> createState() => _ChartOfAccountsScreenState();
}

class _ChartOfAccountsScreenState extends State<ChartOfAccountsScreen> {
  final _storage = AppStorage();
  List<AccountNode> _accounts = [];
  Set<String> _usedAccountIds = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _accounts = await _storage.loadAccounts();
    final vouchers = await _storage.loadVouchers();
    _usedAccountIds = {
      for (final v in vouchers) for (final l in v.lines) l.accountId,
    };
    if (mounted) setState(() => _loading = false);
  }

  List<AccountNode> _children(String? parentId) =>
      _accounts.where((a) => a.parentId == parentId).toList()
        ..sort((a, b) => a.code.compareTo(b.code));

  String _natureLabel(AccountNature n) => n == AccountNature.debit ? 'بدهکار' : 'بستانکار';
  String _groupLabel(AccountGroup g) => {
        AccountGroup.asset: 'دارایی',
        AccountGroup.liability: 'بدهی',
        AccountGroup.equity: 'حقوق صاحبان سرمایه',
        AccountGroup.revenue: 'درآمد',
        AccountGroup.expense: 'هزینه',
      }[g]!;

  Future<void> _saveAll() async {
    await _storage.saveAccounts(_accounts);
  }

  Future<void> _addOrEditDialog({
    AccountNode? existing,
    AccountNode? parent,
    required AccountLevel level,
  }) async {
    final codeCtrl = TextEditingController(text: existing?.code ?? '');
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    AccountNature nature = existing?.nature ?? parent?.nature ?? AccountNature.debit;
    AccountGroup group = existing?.group ?? parent?.group ?? AccountGroup.asset;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(existing == null
              ? (level == AccountLevel.kol
                  ? 'افزودن حساب کل جدید'
                  : level == AccountLevel.moin
                      ? 'افزودن حساب معین جدید'
                      : 'افزودن حساب تفصیلی جدید')
              : 'ویرایش حساب'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeCtrl,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(labelText: 'کد حساب'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nameCtrl,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(labelText: 'نام حساب'),
              ),
              if (level == AccountLevel.kol) ...[
                const SizedBox(height: 10),
                DropdownButtonFormField<AccountGroup>(
                  initialValue: group,
                  decoration: const InputDecoration(labelText: 'گروه حساب'),
                  items: AccountGroup.values
                      .map((g) => DropdownMenuItem(value: g, child: Text(_groupLabel(g))))
                      .toList(),
                  onChanged: (v) => setStateDialog(() {
                    group = v!;
                    nature = (v == AccountGroup.asset || v == AccountGroup.expense)
                        ? AccountNature.debit
                        : AccountNature.credit;
                  }),
                ),
                const SizedBox(height: 6),
                Text('ماهیت: ${_natureLabel(nature)}', style: const TextStyle(color: Colors.grey)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('انصراف')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('ذخیره')),
          ],
        ),
      ),
    );

    if (result != true) return;
    if (codeCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('کد و نام حساب الزامی است.')));
      return;
    }

    setState(() {
      if (existing != null) {
        existing.code = codeCtrl.text.trim();
        existing.name = nameCtrl.text.trim();
      } else {
        _accounts.add(AccountNode(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          code: codeCtrl.text.trim(),
          name: nameCtrl.text.trim(),
          level: level,
          parentId: parent?.id,
          nature: nature,
          group: group,
          isDefault: false,
        ));
      }
    });
    await _saveAll();
  }

  Future<void> _deleteAccount(AccountNode a) async {
    if (_children(a.id).isNotEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('ابتدا زیرحساب‌های این حساب را حذف کنید.')));
      return;
    }
    if (_usedAccountIds.contains(a.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('این حساب در یک یا چند سند حسابداری استفاده شده و قابل حذف نیست.')));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('حذف «${a.name}»'),
        content: Text(a.isDefault
            ? 'این یکی از حساب‌های پیش‌فرض سیستم است؛ آیا مطمئن به حذف آن هستید؟'
            : 'آیا از حذف این حساب مطمئن هستید؟'),
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
    setState(() => _accounts.removeWhere((x) => x.id == a.id));
    await _saveAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('درختواره حساب‌ها'),
        actions: [
          IconButton(
            tooltip: 'افزودن حساب کل',
            icon: const Icon(Icons.add),
            onPressed: () => _addOrEditDialog(level: AccountLevel.kol),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(10),
              children: _children(null).map((kol) => _buildKolTile(kol)).toList(),
            ),
    );
  }

  Widget _buildKolTile(AccountNode kol) {
    return Card(
      child: ExpansionTile(
        title: Text('${kol.code} — ${kol.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${_groupLabel(kol.group)} • ماهیت ${_natureLabel(kol.nature)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.add, size: 20),
              tooltip: 'افزودن معین',
              onPressed: () => _addOrEditDialog(level: AccountLevel.moin, parent: kol),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => _addOrEditDialog(existing: kol, level: AccountLevel.kol),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
              onPressed: () => _deleteAccount(kol),
            ),
          ],
        ),
        children: _children(kol.id).map((moin) => _buildMoinTile(moin)).toList(),
      ),
    );
  }

  Widget _buildMoinTile(AccountNode moin) {
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: ExpansionTile(
        title: Text('${moin.code} — ${moin.name}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.add, size: 20),
              tooltip: 'افزودن تفصیلی',
              onPressed: () => _addOrEditDialog(level: AccountLevel.tafsili, parent: moin),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => _addOrEditDialog(existing: moin, level: AccountLevel.moin),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
              onPressed: () => _deleteAccount(moin),
            ),
          ],
        ),
        children: _children(moin.id)
            .map((t) => ListTile(
                  contentPadding: const EdgeInsets.only(right: 28, left: 16),
                  title: Text('${t.code} — ${t.name}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => _addOrEditDialog(existing: t, level: AccountLevel.tafsili),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        onPressed: () => _deleteAccount(t),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}
