import 'package:flutter/material.dart';
import '../models.dart';
import '../storage.dart';
import '../date_utils.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  final _storage = AppStorage();
  late final TabController _tabs = TabController(length: 3, vsync: this);
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  List<AccountNode> _accounts = [];
  List<Voucher> _vouchers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _accounts = await _storage.loadAccounts();
    _vouchers = await _storage.loadVouchers();
    if (mounted) setState(() => _loading = false);
  }

  /// طبق رویه استاندارد حسابداری، گزارش‌های رسمی فقط از روی اسناد «دائم»
  /// ساخته می‌شوند؛ اسناد موقت هنوز نهایی نشده‌اند.
  List<Voucher> get _permanentInRange {
    return _vouchers.where((v) {
      if (v.status != VoucherStatus.permanent) return false;
      if (_fromCtrl.text.trim().isNotEmpty && compareJalaliDates(v.date, _fromCtrl.text.trim()) < 0) return false;
      if (_toCtrl.text.trim().isNotEmpty && compareJalaliDates(v.date, _toCtrl.text.trim()) > 0) return false;
      return true;
    }).toList();
  }

  bool _isDescendantOrSelf(String accountId, String ancestorId) {
    String? cur = accountId;
    while (cur != null) {
      if (cur == ancestorId) return true;
      final node = _accounts.where((a) => a.id == cur).toList();
      if (node.isEmpty) return false;
      cur = node.first.parentId;
    }
    return false;
  }

  (int, int) _debitCreditFor(AccountNode account, List<Voucher> vouchers) {
    var debit = 0, credit = 0;
    for (final v in vouchers) {
      for (final l in v.lines) {
        if (_isDescendantOrSelf(l.accountId, account.id)) {
          debit += l.debit;
          credit += l.credit;
        }
      }
    }
    return (debit, credit);
  }

  int _balanceFor(AccountNode account, List<Voucher> vouchers) {
    final (debit, credit) = _debitCreditFor(account, vouchers);
    return account.nature == AccountNature.debit ? debit - credit : credit - debit;
  }

  String _money(int v) => toPersianDigits(v.toString());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('گزارش‌های حسابداری'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: const Color(0xFFD6B65A),
          tabs: const [
            Tab(text: 'تراز آزمایشی'),
            Tab(text: 'ترازنامه'),
            Tab(text: 'صورت سود و زیان'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _fromCtrl,
                          textDirection: TextDirection.rtl,
                          decoration: const InputDecoration(labelText: 'از تاریخ'),
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
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text('* فقط اسناد «دائم» در این گزارش‌ها محاسبه می‌شوند.',
                        style: TextStyle(fontSize: 11.5, color: Colors.grey)),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _buildTrialBalance(),
                      _buildBalanceSheet(),
                      _buildIncomeStatement(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTrialBalance() {
    final vouchers = _permanentInRange;
    final kolAccounts = _accounts.where((a) => a.level == AccountLevel.kol).toList()
      ..sort((a, b) => a.code.compareTo(b.code));
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _tableHeaderRow(['کد', 'نام حساب', 'بدهکار', 'بستانکار']),
        for (final kol in kolAccounts) ..._trialBalanceRowsFor(kol, vouchers, 0),
      ],
    );
  }

  List<Widget> _trialBalanceRowsFor(AccountNode node, List<Voucher> vouchers, int depth) {
    final (debit, credit) = _debitCreditFor(node, vouchers);
    if (debit == 0 && credit == 0) return [];
    final rows = <Widget>[
      _tableRow([
        node.code,
        Padding(padding: EdgeInsets.only(right: depth * 14.0), child: Text(node.name)),
        _money(debit),
        _money(credit),
      ], bold: depth == 0),
    ];
    final children = _accounts.where((a) => a.parentId == node.id).toList()
      ..sort((a, b) => a.code.compareTo(b.code));
    for (final c in children) {
      rows.addAll(_trialBalanceRowsFor(c, vouchers, depth + 1));
    }
    return rows;
  }

  Widget _buildBalanceSheet() {
    final vouchers = _permanentInRange;
    final assets = _accounts.where((a) => a.level == AccountLevel.kol && a.group == AccountGroup.asset);
    final liabilities = _accounts.where((a) => a.level == AccountLevel.kol && a.group == AccountGroup.liability);
    final equity = _accounts.where((a) => a.level == AccountLevel.kol && a.group == AccountGroup.equity);

    int sumGroup(Iterable<AccountNode> kols) =>
        kols.fold(0, (s, k) => s + _balanceFor(k, vouchers));

    final totalAssets = sumGroup(assets);
    final totalLiabEquity = sumGroup(liabilities) + sumGroup(equity);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text('دارایی‌ها', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        for (final a in assets) _kolBalanceRow(a, vouchers),
        const Divider(),
        _tableRow(['', 'جمع دارایی‌ها', '', _money(totalAssets)], bold: true),
        const SizedBox(height: 16),
        const Text('بدهی‌ها', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        for (final a in liabilities) _kolBalanceRow(a, vouchers),
        const SizedBox(height: 10),
        const Text('حقوق صاحبان سرمایه', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        for (final a in equity) _kolBalanceRow(a, vouchers),
        const Divider(),
        _tableRow(['', 'جمع بدهی‌ها و حقوق صاحبان سرمایه', '', _money(totalLiabEquity)], bold: true),
        const SizedBox(height: 10),
        if (totalAssets != totalLiabEquity)
          Text('⚠️ مغایرت ترازنامه: ${_money((totalAssets - totalLiabEquity).abs())} ریال',
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _kolBalanceRow(AccountNode a, List<Voucher> vouchers) {
    final balance = _balanceFor(a, vouchers);
    if (balance == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text('${a.code} — ${a.name}')),
          Text('${_money(balance)} ریال'),
        ],
      ),
    );
  }

  Widget _buildIncomeStatement() {
    final vouchers = _permanentInRange;
    final revenues = _accounts.where((a) => a.level == AccountLevel.kol && a.group == AccountGroup.revenue);
    final expenses = _accounts.where((a) => a.level == AccountLevel.kol && a.group == AccountGroup.expense);

    int sumGroup(Iterable<AccountNode> kols) => kols.fold(0, (s, k) => s + _balanceFor(k, vouchers));
    final totalRevenue = sumGroup(revenues);
    final totalExpense = sumGroup(expenses);
    final net = totalRevenue - totalExpense;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text('درآمدها', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        for (final a in revenues) _kolBalanceRow(a, vouchers),
        const Divider(),
        _tableRow(['', 'جمع درآمدها', '', _money(totalRevenue)], bold: true),
        const SizedBox(height: 16),
        const Text('هزینه‌ها', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        for (final a in expenses) _kolBalanceRow(a, vouchers),
        const Divider(),
        _tableRow(['', 'جمع هزینه‌ها', '', _money(totalExpense)], bold: true),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: net >= 0 ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            net >= 0 ? 'سود خالص دوره: ${_money(net)} ریال' : 'زیان خالص دوره: ${_money(net.abs())} ریال',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: net >= 0 ? Colors.green.shade800 : Colors.red.shade800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _tableHeaderRow(List<String> cells) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(cells[0], style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 3, child: Text(cells[1], style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text(cells[2], style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text(cells[3], style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  Widget _tableRow(List<dynamic> cells, {bool bold = false}) {
    final style = TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal);
    Widget cellWidget(dynamic c) => c is Widget ? c : Text(c.toString(), style: style);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        children: [
          SizedBox(width: 60, child: cellWidget(cells[0])),
          Expanded(flex: 3, child: cellWidget(cells[1])),
          Expanded(flex: 2, child: Align(alignment: Alignment.center, child: cellWidget(cells[2]))),
          Expanded(flex: 2, child: Align(alignment: Alignment.center, child: cellWidget(cells[3]))),
        ],
      ),
    );
  }
}
