import 'package:flutter/material.dart';
import '../theme.dart';
import '../storage.dart';
import '../models.dart';
import '../date_utils.dart';
import 'voucher_list_screen.dart';
import 'voucher_entry_screen.dart';
import 'chart_of_accounts_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'server_reports_screen.dart';

/// پوسته اصلی اپ: یک نوار کناری ثابت (شبیه منوی سپیدار) + لوگوی فروشگاه در
/// بالای نوار کناری + محتوای صفحه انتخاب‌شده در کنار آن.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.userRole});

  final String userRole;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selected = 0;
  String _storeName = 'فروشگاه';

  @override
  void initState() {
    super.initState();
    AppStorage().loadStoreName().then((n) {
      if (mounted) setState(() => _storeName = n);
    });
  }

  final _pages = const [
    _DashboardBody(),
    VoucherListScreen(),
    ChartOfAccountsScreen(),
    ReportsScreen(),
    ServerReportsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 1050;
    final sidebarWidth = wide ? 248.0 : 84.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      body: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                _TopBar(storeName: _storeName, role: widget.userRole),
                Expanded(
                  child: IndexedStack(index: _selected, children: _pages),
                ),
              ],
            ),
          ),
          Container(
            width: sidebarWidth,
            color: AppColors.primaryGreen,
            child: SafeArea(
              left: false,
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    width: 66,
                    height: 66,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(image: AssetImage('assets/images/logo.png'), fit: BoxFit.cover),
                    ),
                  ),
                  if (wide) ...[
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        _storeName,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(widget.userRole, style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                  const SizedBox(height: 18),
                  const Divider(color: Colors.white24, indent: 16, endIndent: 16),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      children: [
                        _SideItem(index: 0, icon: Icons.dashboard_rounded, label: 'داشبورد', selected: _selected == 0, wide: wide, onTap: _select),
                        _SideItem(index: 1, icon: Icons.receipt_long_rounded, label: 'اسناد حسابداری', selected: _selected == 1, wide: wide, onTap: _select),
                        _SideItem(index: 2, icon: Icons.account_tree_rounded, label: 'حساب‌ها', selected: _selected == 2, wide: wide, onTap: _select),
                        _SideItem(index: 3, icon: Icons.bar_chart_rounded, label: 'گزارش‌ها', selected: _selected == 3, wide: wide, onTap: _select),
                        _SideItem(index: 4, icon: Icons.cloud_sync_rounded, label: 'ارتباط با سرور', selected: _selected == 4, wide: wide, onTap: _select),
                        _SideItem(index: 5, icon: Icons.settings_rounded, label: 'تنظیمات', selected: _selected == 5, wide: wide, onTap: _select),
                      ],
                    ),
                  ),
                  if (wide)
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text('نسخه ویندوز', style: TextStyle(color: Colors.white.withOpacity(.45), fontSize: 10)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _select(int index) => setState(() => _selected = index);

}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.storeName, required this.role});
  final String storeName;
  final String role;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5EAE8))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(color: const Color(0xFFF2F5F4), borderRadius: BorderRadius.circular(13)),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'جستجو در حساب‌ها، اسناد و گزارش‌ها ...',
                  prefixIcon: Icon(Icons.search_rounded),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 11),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded)),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primaryGreen.withOpacity(.1),
            child: const Icon(Icons.person_outline_rounded, color: AppColors.primaryGreen),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(role, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
              Text(storeName, style: const TextStyle(color: Colors.black45, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SideItem extends StatelessWidget {
  const _SideItem({required this.index, required this.icon, required this.label, required this.selected, required this.wide, required this.onTap});
  final int index;
  final IconData icon;
  final String label;
  final bool selected;
  final bool wide;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Material(
        color: selected ? Colors.white.withOpacity(.13) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onTap(index),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: wide ? 14 : 10, vertical: 13),
            child: Row(
              mainAxisAlignment: wide ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Icon(icon, color: selected ? AppColors.gold : Colors.white70, size: 22),
                if (wide) ...[
                  const SizedBox(width: 12),
                  Expanded(child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.white70, fontSize: 12.5, fontWeight: selected ? FontWeight.w800 : FontWeight.w500))),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardBody extends StatefulWidget {
  const _DashboardBody();
  @override
  State<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<_DashboardBody> {
  final _storage = AppStorage();
  int _temporaryCount = 0;
  int _permanentCount = 0;
  int _accountsCount = 0;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final vouchers = await _storage.loadVouchers();
    final accounts = await _storage.loadAccounts();
    if (!mounted) return;
    setState(() {
      _temporaryCount = vouchers.where((v) => v.status == VoucherStatus.temporary).length;
      _permanentCount = vouchers.where((v) => v.status == VoucherStatus.permanent).length;
      _accountsCount = accounts.where((a) => a.level == AccountLevel.tafsili).length;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(26, 24, 26, 30),
              children: [
                const Text('داشبورد', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('خلاصه وضعیت سیستم حسابداری', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                const SizedBox(height: 22),
                LayoutBuilder(builder: (context, c) {
                  final columns = c.maxWidth >= 1150 ? 3 : (c.maxWidth >= 700 ? 2 : 1);
                  final width = (c.maxWidth - (columns - 1) * 14) / columns;
                  final cards = [
                    _QuickCard(title: 'فاکتور فروش', icon: Icons.receipt_long_rounded, color: const Color(0xFF19A974), subtitle: 'ثبت و مشاهده اسناد فروش', onTap: () => _open(context, const VoucherListScreen())),
                    _QuickCard(title: 'دریافت', icon: Icons.file_download_outlined, color: const Color(0xFF3478D5), subtitle: 'ثبت عملیات دریافت', onTap: () => _open(context, const VoucherEntryScreen())),
                    _QuickCard(title: 'پرداخت', icon: Icons.file_upload_outlined, color: const Color(0xFFE9545D), subtitle: 'ثبت عملیات پرداخت', onTap: () => _open(context, const VoucherEntryScreen())),
                    _QuickCard(title: 'کالا و انبار', icon: Icons.inventory_2_outlined, color: const Color(0xFF7A55D5), subtitle: 'مدیریت اطلاعات کالا', onTap: () => _comingSoon(context, 'کالا و انبار')),
                    _QuickCard(title: 'اشخاص', icon: Icons.groups_outlined, color: const Color(0xFFF0AA21), subtitle: 'مدیریت طرف حساب‌ها', onTap: () => _comingSoon(context, 'اشخاص')),
                    _QuickCard(title: 'گزارش‌ها', icon: Icons.bar_chart_rounded, color: const Color(0xFF20AEB2), subtitle: 'گزارش‌های مالی و مدیریتی', onTap: () => _comingSoon(context, 'گزارش‌ها')),
                    _QuickCard(title: 'حساب‌ها', icon: Icons.menu_book_rounded, color: const Color(0xFF5270D4), subtitle: 'درخت حساب‌های حسابداری', onTap: () => _open(context, const ChartOfAccountsScreen())),
                    _QuickCard(title: 'ارتباط با سرور', icon: Icons.account_balance_outlined, color: const Color(0xFF2CA9A9), subtitle: 'همگام‌سازی و ارتباط شبکه', onTap: () => _open(context, const ServerReportsScreen())),
                    _QuickCard(title: 'تنظیمات', icon: Icons.settings_rounded, color: const Color(0xFF8293A0), subtitle: 'تنظیمات نرم‌افزار', onTap: () => _open(context, const SettingsScreen())),
                  ];
                  return Wrap(spacing: 14, runSpacing: 14, children: cards.map((e) => SizedBox(width: width, child: e)).toList());
                }),
                const SizedBox(height: 22),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _SummaryCard(title: 'اسناد موقت', value: _temporaryCount, icon: Icons.pending_actions_rounded, color: const Color(0xFFF0A12B)),
                    _SummaryCard(title: 'اسناد دائم', value: _permanentCount, icon: Icons.verified_rounded, color: const Color(0xFF19A974)),
                    _SummaryCard(title: 'حساب‌های تفصیلی', value: _accountsCount, icon: Icons.account_tree_rounded, color: const Color(0xFF3478D5)),
                    _SummaryCard(title: 'وضعیت سیستم', valueText: 'فعال', icon: Icons.check_circle_rounded, color: const Color(0xFF20AEB2)),
                  ],
                ),
              ],
            ),
          );
  }

  void _open(BuildContext context, Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page)).then((_) => _load());
  void _comingSoon(BuildContext context, String name) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('بخش «$name» در نسخه فعلی در حال توسعه است.')));
}

class _QuickCard extends StatefulWidget {
  const _QuickCard({required this.title, required this.subtitle, required this.icon, required this.color, required this.onTap});
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  @override
  State<_QuickCard> createState() => _QuickCardState();
}

class _QuickCardState extends State<_QuickCard> {
  bool hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        transform: Matrix4.translationValues(0, hover ? -3 : 0, 0),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          elevation: hover ? 5 : 1,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Container(width: 55, height: 55, decoration: BoxDecoration(color: widget.color, borderRadius: BorderRadius.circular(14)), child: Icon(widget.icon, color: Colors.white, size: 29)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)), const SizedBox(height: 5), Text(widget.subtitle, style: const TextStyle(fontSize: 10.5, color: Colors.black45))])),
                Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: widget.color),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, this.value, this.valueText, required this.icon, required this.color});
  final String title;
  final int? value;
  final String? valueText;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.black.withOpacity(.04))),
      child: Row(children: [
        Icon(icon, color: color, size: 30), const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 11, color: Colors.black54)), const SizedBox(height: 4), Text(valueText ?? toPersianDigits((value ?? 0).toString()), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color))]),
      ]),
    );
  }
}
