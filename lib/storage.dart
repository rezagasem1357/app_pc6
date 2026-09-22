import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'date_utils.dart';

/// لایه ذخیره‌سازی محلی (مشابه اپ موبایل، با SharedPreferences و JSON).
/// اگر بعداً نیاز به اتصال چند دستگاه/سرور شد، همین لایه محل مناسبی برای
/// اضافه‌کردن sync است.
class AppStorage {
  static const _kAccounts = 'coa_accounts_v1';
  static const _kVouchers = 'vouchers_v1';
  static const _kStoreName = 'store_name_v1';
  static const _kAutoRenumberByDate = 'voucher_auto_renumber_by_date_v1';

  Future<List<AccountNode>> loadAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kAccounts);
    if (raw == null || raw.isEmpty) {
      final defaults = buildDefaultChartOfAccounts();
      await saveAccounts(defaults);
      return defaults;
    }
    final list = (jsonDecode(raw) as List)
        .map((e) => AccountNode.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return list;
  }

  Future<void> saveAccounts(List<AccountNode> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccounts, jsonEncode(accounts.map((a) => a.toJson()).toList()));
  }

  Future<List<Voucher>> loadVouchers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kVouchers);
    if (raw == null || raw.isEmpty) return [];
    return (jsonDecode(raw) as List)
        .map((e) => Voucher.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> saveVouchers(List<Voucher> vouchers) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kVouchers, jsonEncode(vouchers.map((v) => v.toJson()).toList()));
  }

  Future<String> loadStoreName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kStoreName) ?? 'کریم اهل بیت';
  }

  Future<void> saveStoreName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kStoreName, name);
  }

  /// طبق درخواست: شماره‌گذاری سند از ۱ شروع و همیشه به ترتیب تاریخ صدور است.
  /// این تنظیم فقط برای این‌که در آینده در صورت نیاز غیرفعال شود نگه داشته
  /// می‌شود؛ فعلاً همیشه true است.
  Future<bool> loadAutoRenumberByDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kAutoRenumberByDate) ?? true;
  }

  Future<void> saveAutoRenumberByDate(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAutoRenumberByDate, value);
  }
}

/// برای هر سند، «چندمین سند همان روز» بودنش را محاسبه می‌کند (کلید: id سند).
/// طبق درخواست: علاوه بر شماره کلی سند (۱،۲،۳...)، شماره روزانه هم لازم است
/// (مثلاً «سومین سند تاریخ ۱۴۰۳/۰۷/۰۱»).
Map<String, int> computeDailyNumbers(List<Voucher> vouchers) {
  final byDate = <String, List<Voucher>>{};
  for (final v in vouchers) {
    byDate.putIfAbsent(v.date, () => []).add(v);
  }
  final result = <String, int>{};
  for (final entry in byDate.entries) {
    final sorted = List<Voucher>.from(entry.value)
      ..sort((a, b) {
        final byNumber = a.number.compareTo(b.number);
        if (byNumber != 0) return byNumber;
        return a.createdAtMs.compareTo(b.createdAtMs);
      });
    for (var i = 0; i < sorted.length; i++) {
      result[sorted[i].id] = i + 1;
    }
  }
  return result;
}

/// همه‌ی اسناد را بر اساس تاریخ صدور (و در تاریخ یکسان، بر اساس ترتیب ثبت)
/// مرتب کرده و شماره ۱ به بعد را به‌ترتیب اختصاص می‌دهد. طبق خواسته کاربر:
/// «شماره‌گذاری خودکار سند حسابداری از یک به بعد اتوماتیک به ترتیب تاریخ».
///
/// نکته: در نرم‌افزارهای حسابداری رایج معمولاً شماره سند دائم دیگر تغییر
/// نمی‌کند (برای حفظ ردیابی)، اما چون در این‌جا صراحتاً «ترتیب تاریخ خودکار»
/// خواسته شده، این تابع شماره همه اسناد (موقت و دائم) را بازچینی می‌کند.
List<Voucher> renumberVouchersByDate(List<Voucher> vouchers) {
  final sorted = List<Voucher>.from(vouchers)
    ..sort((a, b) {
      final byDate = compareJalaliDates(a.date, b.date);
      if (byDate != 0) return byDate;
      return a.createdAtMs.compareTo(b.createdAtMs);
    });
  for (var i = 0; i < sorted.length; i++) {
    sorted[i].number = i + 1;
  }
  return sorted;
}

/// درخت پیش‌فرض حساب‌ها (کل > معین > تفصیلی) برای یک فروشگاه — نقطه شروع
/// حداقلی و قابل ویرایش/گسترش توسط کاربر.
List<AccountNode> buildDefaultChartOfAccounts() {
  final list = <AccountNode>[];

  void kol(String id, String code, String name, AccountNature nature, AccountGroup group) {
    list.add(AccountNode(
      id: id,
      code: code,
      name: name,
      level: AccountLevel.kol,
      parentId: null,
      nature: nature,
      group: group,
      isDefault: true,
    ));
  }

  void moin(String id, String parentId, String code, String name) {
    final parent = list.firstWhere((a) => a.id == parentId);
    list.add(AccountNode(
      id: id,
      code: code,
      name: name,
      level: AccountLevel.moin,
      parentId: parentId,
      nature: parent.nature,
      group: parent.group,
      isDefault: true,
    ));
  }

  void tafsili(String id, String parentId, String code, String name) {
    final parent = list.firstWhere((a) => a.id == parentId);
    list.add(AccountNode(
      id: id,
      code: code,
      name: name,
      level: AccountLevel.tafsili,
      parentId: parentId,
      nature: parent.nature,
      group: parent.group,
      isDefault: true,
    ));
  }

  // ---- دارایی‌ها ----
  kol('k_asset', '1', 'دارایی‌ها', AccountNature.debit, AccountGroup.asset);
  moin('m_cash_bank', 'k_asset', '11', 'موجودی نقد و بانک');
  tafsili('t_cash', 'm_cash_bank', '1101', 'صندوق');
  tafsili('t_bank', 'm_cash_bank', '1102', 'بانک');
  moin('m_receivable', 'k_asset', '12', 'حساب‌های دریافتنی (مشتریان)');
  tafsili('t_customers', 'm_receivable', '1201', 'مشتریان متفرقه');
  moin('m_inventory', 'k_asset', '13', 'موجودی کالا');
  tafsili('t_inventory_goods', 'm_inventory', '1301', 'موجودی کالای فروشگاه');

  // ---- بدهی‌ها ----
  kol('k_liability', '2', 'بدهی‌ها', AccountNature.credit, AccountGroup.liability);
  moin('m_payable', 'k_liability', '21', 'حساب‌های پرداختنی (تامین‌کنندگان)');
  tafsili('t_suppliers', 'm_payable', '2101', 'تامین‌کنندگان متفرقه');
  moin('m_notes_payable', 'k_liability', '22', 'اسناد پرداختنی');
  tafsili('t_checks_payable', 'm_notes_payable', '2201', 'چک‌های پرداختنی');

  // ---- حقوق صاحبان سرمایه ----
  kol('k_equity', '3', 'حقوق صاحبان سرمایه', AccountNature.credit, AccountGroup.equity);
  moin('m_capital', 'k_equity', '31', 'سرمایه');
  tafsili('t_capital', 'm_capital', '3101', 'سرمایه مالک');
  moin('m_retained', 'k_equity', '32', 'سود (زیان) انباشته');
  tafsili('t_retained', 'm_retained', '3201', 'سود و زیان انباشته');

  // ---- درآمدها ----
  kol('k_revenue', '4', 'درآمدها', AccountNature.credit, AccountGroup.revenue);
  moin('m_sales', 'k_revenue', '41', 'فروش کالا');
  tafsili('t_sales_goods', 'm_sales', '4101', 'فروش کالای فروشگاه');
  moin('m_other_revenue', 'k_revenue', '42', 'سایر درآمدها');
  tafsili('t_other_revenue', 'm_other_revenue', '4201', 'درآمدهای متفرقه');

  // ---- هزینه‌ها ----
  kol('k_expense', '5', 'هزینه‌ها', AccountNature.debit, AccountGroup.expense);
  moin('m_cogs', 'k_expense', '51', 'بهای تمام‌شده کالای فروش‌رفته');
  tafsili('t_cogs', 'm_cogs', '5101', 'بهای تمام‌شده کالای فروش‌رفته');
  moin('m_opex', 'k_expense', '52', 'هزینه‌های عملیاتی');
  tafsili('t_rent', 'm_opex', '5201', 'اجاره');
  tafsili('t_salary', 'm_opex', '5202', 'حقوق و دستمزد');
  tafsili('t_utilities', 'm_opex', '5203', 'آب، برق و گاز');
  tafsili('t_misc_expense', 'm_opex', '5204', 'هزینه‌های متفرقه');

  return list;
}
