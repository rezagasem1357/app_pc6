/// سطح حساب در درخت حساب‌ها: کل > معین > تفصیلی.
/// فقط حساب‌های «تفصیلی» (برگ درخت) در سند حسابداری قابل استفاده‌اند؛
/// کل و معین صرفاً برای طبقه‌بندی و گزارش‌گیری هستند (مثل اکثر نرم‌افزارهای
/// حسابداری ایرانی از جمله سپیدار).
enum AccountLevel { kol, moin, tafsili }

AccountLevel accountLevelFromString(String s) {
  switch (s) {
    case 'moin':
      return AccountLevel.moin;
    case 'tafsili':
      return AccountLevel.tafsili;
    default:
      return AccountLevel.kol;
  }
}

/// ماهیت حساب: بدهکار (دارایی/هزینه) یا بستانکار (بدهی/سرمایه/درآمد).
/// برای تعیین اینکه در گزارش ترازنامه/سود‌وزیان، مانده حساب در کدام ستون
/// نمایش داده شود.
enum AccountNature { debit, credit }

/// گروه اصلی حساب کل، برای این‌که بشود گزارش ترازنامه/سود‌وزیان به‌صورت
/// خودکار بر اساس نوع حساب تولید شود.
enum AccountGroup { asset, liability, equity, revenue, expense }

AccountGroup accountGroupFromString(String s) {
  switch (s) {
    case 'liability':
      return AccountGroup.liability;
    case 'equity':
      return AccountGroup.equity;
    case 'revenue':
      return AccountGroup.revenue;
    case 'expense':
      return AccountGroup.expense;
    default:
      return AccountGroup.asset;
  }
}

class AccountNode {
  final String id;
  String code;
  String name;
  final AccountLevel level;
  final String? parentId;
  final AccountNature nature;
  final AccountGroup group;
  final bool isDefault; // حساب‌های پیش‌فرض سیستم (قابل ویرایش نام، ولی حذف‌شان هشدار دارد)

  AccountNode({
    required this.id,
    required this.code,
    required this.name,
    required this.level,
    required this.parentId,
    required this.nature,
    required this.group,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'level': level.name,
        'parentId': parentId,
        'nature': nature.name,
        'group': group.name,
        'isDefault': isDefault,
      };

  factory AccountNode.fromJson(Map<String, dynamic> json) => AccountNode(
        id: json['id']?.toString() ?? '',
        code: json['code']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        level: accountLevelFromString(json['level']?.toString() ?? 'kol'),
        parentId: json['parentId']?.toString(),
        nature: (json['nature']?.toString() ?? 'debit') == 'credit'
            ? AccountNature.credit
            : AccountNature.debit,
        group: accountGroupFromString(json['group']?.toString() ?? 'asset'),
        isDefault: json['isDefault'] == true,
      );
}

enum VoucherStatus { temporary, permanent }

class VoucherLine {
  final String id;
  final String accountId; // شناسه حساب تفصیلی
  String description;
  int debit;
  int credit;

  VoucherLine({
    required this.id,
    required this.accountId,
    this.description = '',
    this.debit = 0,
    this.credit = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'accountId': accountId,
        'description': description,
        'debit': debit,
        'credit': credit,
      };

  factory VoucherLine.fromJson(Map<String, dynamic> json) => VoucherLine(
        id: json['id']?.toString() ?? '',
        accountId: json['accountId']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        debit: (json['debit'] as num?)?.toInt() ?? 0,
        credit: (json['credit'] as num?)?.toInt() ?? 0,
      );
}

class Voucher {
  final String id;
  int number; // شماره سند؛ خودکار و به ترتیب تاریخ (از تنظیمات)
  String date; // شمسی yyyy/mm/dd
  String description;
  VoucherStatus status;
  List<VoucherLine> lines;
  final int createdAtMs;

  Voucher({
    required this.id,
    required this.number,
    required this.date,
    this.description = '',
    this.status = VoucherStatus.temporary,
    List<VoucherLine>? lines,
    int? createdAtMs,
  })  : lines = lines ?? [],
        createdAtMs = createdAtMs ?? DateTime.now().millisecondsSinceEpoch;

  int get totalDebit => lines.fold(0, (s, l) => s + l.debit);
  int get totalCredit => lines.fold(0, (s, l) => s + l.credit);
  bool get isBalanced => totalDebit == totalCredit && totalDebit > 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'date': date,
        'description': description,
        'status': status.name,
        'lines': lines.map((l) => l.toJson()).toList(),
        'createdAtMs': createdAtMs,
      };

  factory Voucher.fromJson(Map<String, dynamic> json) => Voucher(
        id: json['id']?.toString() ?? '',
        number: (json['number'] as num?)?.toInt() ?? 0,
        date: json['date']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        status: (json['status']?.toString() ?? 'temporary') == 'permanent'
            ? VoucherStatus.permanent
            : VoucherStatus.temporary,
        lines: ((json['lines'] as List?) ?? [])
            .map((e) => VoucherLine.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        createdAtMs: (json['createdAtMs'] as num?)?.toInt(),
      );
}
