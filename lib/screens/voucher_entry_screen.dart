import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models.dart';
import '../storage.dart';
import '../date_utils.dart';

class VoucherEntryScreen extends StatefulWidget {
  final Voucher? existing;
  const VoucherEntryScreen({super.key, this.existing});

  @override
  State<VoucherEntryScreen> createState() => _VoucherEntryScreenState();
}

class _LineRow {
  AccountNode? kol;
  AccountNode? moin;
  AccountNode? tafsili;
  final TextEditingController descCtrl;
  final TextEditingController debitCtrl;
  final TextEditingController creditCtrl;
  final String id;

  _LineRow({this.kol, this.moin, this.tafsili, String description = '', int debit = 0, int credit = 0, String? id})
      : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        descCtrl = TextEditingController(text: description),
        debitCtrl = TextEditingController(text: debit == 0 ? '' : debit.toString()),
        creditCtrl = TextEditingController(text: credit == 0 ? '' : credit.toString());

  int get debit => int.tryParse(debitCtrl.text.trim()) ?? 0;
  int get credit => int.tryParse(creditCtrl.text.trim()) ?? 0;
}

class _VoucherEntryScreenState extends State<VoucherEntryScreen> {
  final _storage = AppStorage();
  final _dateCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  List<AccountNode> _accounts = [];
  final List<_LineRow> _rows = [];
  bool _loading = true;
  bool _saving = false;
  int? _dailyNumber;

  bool get _isReadOnly => widget.existing?.status == VoucherStatus.permanent;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _accounts = await _storage.loadAccounts();
    final existing = widget.existing;
    if (existing != null) {
      _dateCtrl.text = existing.date;
      _descCtrl.text = existing.description;
      final allVouchers = await _storage.loadVouchers();
      final dailyNumbers = computeDailyNumbers(allVouchers);
      _dailyNumber = dailyNumbers[existing.id];
      for (final l in existing.lines) {
        AccountNode? tafsili;
        for (final a in _accounts) {
          if (a.id == l.accountId) tafsili = a;
        }
        AccountNode? moin;
        AccountNode? kol;
        if (tafsili != null) {
          for (final a in _accounts) {
            if (a.id == tafsili!.parentId) moin = a;
          }
          if (moin != null) {
            for (final a in _accounts) {
              if (a.id == moin!.parentId) kol = a;
            }
          }
        }
        _rows.add(_LineRow(
          kol: kol,
          moin: moin,
          tafsili: tafsili,
          description: l.description,
          debit: l.debit,
          credit: l.credit,
          id: l.id,
        ));
      }
    } else {
      _dateCtrl.text = todayJalali();
      _rows.add(_LineRow());
      _rows.add(_LineRow());
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _descCtrl.dispose();
    for (final r in _rows) {
      r.descCtrl.dispose();
      r.debitCtrl.dispose();
      r.creditCtrl.dispose();
    }
    super.dispose();
  }

  int get _totalDebit => _rows.fold(0, (s, r) => s + r.debit);
  int get _totalCredit => _rows.fold(0, (s, r) => s + r.credit);
  int get _diff => _totalDebit - _totalCredit;

  List<AccountNode> get _kolOptions =>
      _accounts.where((a) => a.level == AccountLevel.kol).toList()..sort((a, b) => a.code.compareTo(b.code));

  List<AccountNode> _moinOptions(AccountNode? kol) {
    if (kol == null) return [];
    return _accounts.where((a) => a.level == AccountLevel.moin && a.parentId == kol.id).toList()
      ..sort((a, b) => a.code.compareTo(b.code));
  }

  List<AccountNode> _tafsiliOptions(AccountNode? moin) {
    if (moin == null) return [];
    return _accounts.where((a) => a.level == AccountLevel.tafsili && a.parentId == moin.id).toList()
      ..sort((a, b) => a.code.compareTo(b.code));
  }

  void _addRow() => setState(() => _rows.add(_LineRow()));

  void _removeRow(_LineRow row) {
    if (_rows.length <= 2) {
      _showMsg('سند حسابداری حداقل باید ۲ ردیف داشته باشد.');
      return;
    }
    setState(() => _rows.remove(row));
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _save({required bool asPermanent}) async {
    if (_isReadOnly || _saving) return;
    if (_dateCtrl.text.trim().isEmpty) {
      _showMsg('تاریخ سند را وارد کنید.');
      return;
    }
    final activeRows = _rows.where((r) => r.tafsili != null && (r.debit > 0 || r.credit > 0)).toList();
    if (activeRows.length < 2) {
      _showMsg('سند باید حداقل ۲ ردیف با حساب تفصیلی و مبلغ معتبر داشته باشد.');
      return;
    }
    if (_totalDebit != _totalCredit || _totalDebit == 0) {
      _showMsg('جمع بدهکار و بستانکار باید برابر و بزرگ‌تر از صفر باشد (مغایرت: ${_diff.abs()} ریال).');
      return;
    }

    setState(() => _saving = true);
    try {
      final vouchers = await _storage.loadVouchers();
      final lines = activeRows
          .map((r) => VoucherLine(
                id: r.id,
                accountId: r.tafsili!.id,
                description: r.descCtrl.text.trim(),
                debit: r.debit,
                credit: r.credit,
              ))
          .toList();

      if (widget.existing != null) {
        final idx = vouchers.indexWhere((v) => v.id == widget.existing!.id);
        if (idx != -1) {
          vouchers[idx].date = _dateCtrl.text.trim();
          vouchers[idx].description = _descCtrl.text.trim();
          vouchers[idx].lines = lines;
          if (asPermanent) vouchers[idx].status = VoucherStatus.permanent;
        }
      } else {
        vouchers.add(Voucher(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          number: 0,
          date: _dateCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          status: asPermanent ? VoucherStatus.permanent : VoucherStatus.temporary,
          lines: lines,
        ));
      }

      final renumbered = renumberVouchersByDate(vouchers);
      await _storage.saveVouchers(renumbered);
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final balanced = _diff == 0 && _totalDebit > 0;
    final titleText = widget.existing == null
        ? 'سند حسابداری جدید'
        : 'سند شماره ${toPersianDigits(widget.existing!.number.toString())}'
            '${_dailyNumber != null ? ' (سند شماره ${toPersianDigits(_dailyNumber.toString())} تاریخ ${toPersianDigits(widget.existing!.date)})' : ''}';

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.f1): () => _save(asPermanent: false),
        const SingleActivator(LogicalKeyboardKey.f2): () => _save(asPermanent: true),
        const SingleActivator(LogicalKeyboardKey.f4): _addRow,
        const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.maybePop(context),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            title: Text(titleText),
            actions: [
              if (_isReadOnly)
                const Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Center(
                    child: Chip(
                      label: Text('دائم — غیرقابل ویرایش', style: TextStyle(color: Colors.white)),
                      backgroundColor: Colors.black26,
                    ),
                  ),
                ),
            ],
          ),
          body: AbsorbPointer(
            absorbing: _isReadOnly,
            child: Opacity(
              opacity: _isReadOnly ? 0.75 : 1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!_isReadOnly)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          'میانبرها:  F1 = ذخیره موقت   •   F2 = ذخیره دائم   •   F4 = افزودن ردیف   •   Esc = بازگشت',
                          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _dateCtrl,
                            textDirection: TextDirection.rtl,
                            decoration: const InputDecoration(
                              labelText: 'تاریخ سند (مثال: 1403/07/01)',
                              prefixIcon: Icon(Icons.calendar_today_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 4,
                          child: TextField(
                            controller: _descCtrl,
                            textDirection: TextDirection.rtl,
                            decoration: const InputDecoration(labelText: 'شرح سند'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.separated(
                        itemCount: _rows.length,
                        separatorBuilder: (context, i) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => _buildRowCard(i, _rows[i]),
                      ),
                    ),
                    if (!_isReadOnly)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _addRow,
                          icon: const Icon(Icons.add),
                          label: const Text('افزودن ردیف (F4)'),
                        ),
                      ),
                    const Divider(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'جمع بدهکار: ${toPersianDigits(_totalDebit.toString())} ریال',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'جمع بستانکار: ${toPersianDigits(_totalCredit.toString())} ریال',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            balanced ? '✅ تراز است' : '⚠️ مغایرت: ${toPersianDigits(_diff.abs().toString())} ریال',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: balanced ? Colors.green.shade700 : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (!_isReadOnly)
                      Wrap(
                        alignment: WrapAlignment.start,
                        spacing: 14,
                        runSpacing: 10,
                        children: [
                          OutlinedButton(
                            onPressed: _saving ? null : () => _save(asPermanent: false),
                            child: const Text('ذخیره به‌عنوان موقت (F1)'),
                          ),
                          ElevatedButton(
                            onPressed: _saving ? null : () => _save(asPermanent: true),
                            child: const Text('ذخیره و تبدیل به سند دائم (F2)'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRowCard(int index, _LineRow row) {
    return Container(
      key: ValueKey(row.id),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 12, child: Text('${index + 1}', style: const TextStyle(fontSize: 12))),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: Colors.red),
                onPressed: () => _removeRow(row),
              ),
            ],
          ),
          // ---- ردیف انتخاب حساب: کل / معین / تفصیلی (دقیقاً مانند سپیدار) ----
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<AccountNode>(
                  key: ValueKey('${row.id}-kol'),
                  initialValue: row.kol,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'حساب کل', isDense: true),
                  items: _kolOptions
                      .map((a) => DropdownMenuItem(value: a, child: Text('${a.code} — ${a.name}', overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (v) => setState(() {
                    row.kol = v;
                    row.moin = null;
                    row.tafsili = null;
                  }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<AccountNode>(
                  key: ValueKey('${row.id}-moin-${row.kol?.id}'),
                  initialValue: row.moin,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'حساب معین', isDense: true),
                  items: _moinOptions(row.kol)
                      .map((a) => DropdownMenuItem(value: a, child: Text('${a.code} — ${a.name}', overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: row.kol == null
                      ? null
                      : (v) => setState(() {
                            row.moin = v;
                            row.tafsili = null;
                          }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<AccountNode>(
                  key: ValueKey('${row.id}-tafsili-${row.moin?.id}'),
                  initialValue: row.tafsili,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'حساب تفصیلی', isDense: true),
                  items: _tafsiliOptions(row.moin)
                      .map((a) => DropdownMenuItem(value: a, child: Text('${a.code} — ${a.name}', overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: row.moin == null ? null : (v) => setState(() => row.tafsili = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // ---- ردیف شرح و مبالغ؛ کادرها به‌اندازه کافی پهن‌اند ----
          Row(
            children: [
              Expanded(
                flex: 4,
                child: TextField(
                  controller: row.descCtrl,
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(labelText: 'شرح ردیف', isDense: true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: row.debitCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(labelText: 'بدهکار', isDense: true),
                  onChanged: (v) {
                    if (v.isNotEmpty) row.creditCtrl.clear();
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: row.creditCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(labelText: 'بستانکار', isDense: true),
                  onChanged: (v) {
                    if (v.isNotEmpty) row.debitCtrl.clear();
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
