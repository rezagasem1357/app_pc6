import 'package:flutter/material.dart';
import '../theme.dart';
import 'home_shell.dart';

/// صفحه انتخاب نوع ورود قبل از ورود کامل به برنامه.
/// صندوق‌دار بدون رمز وارد می‌شود؛ مدیر برای ورود به رمز نیاز دارد.
class LoginRoleScreen extends StatelessWidget {
  const LoginRoleScreen({super.key});

  static const String _managerPassword = '6002380';

  Future<void> _openManager(BuildContext context) async {
    final controller = TextEditingController();
    bool obscure = true;

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('ورود مدیر'),
              content: SizedBox(
                width: 360,
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  obscureText: obscure,
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: 'رمز مدیر',
                    hintText: 'رمز را وارد کنید',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: 'نمایش/مخفی کردن رمز',
                      onPressed: () => setState(() => obscure = !obscure),
                      icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    ),
                  ),
                  onSubmitted: (_) {
                    if (controller.text == _managerPassword) {
                      Navigator.pop(dialogContext, true);
                    }
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('انصراف'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    if (controller.text == _managerPassword) {
                      Navigator.pop(dialogContext, true);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('رمز مدیر صحیح نیست.')),
                      );
                    }
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('ورود'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
    if (ok == true && context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeShell(userRole: 'مدیر')),
      );
    }
  }

  void _openCashier(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeShell(userRole: 'صندوق‌دار')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [AppColors.splashGreen, AppColors.primaryGreen],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Card(
                elevation: 18,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                child: Padding(
                  padding: const EdgeInsets.all(34),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: AppColors.primaryGreen.withOpacity(.18), blurRadius: 24)],
                          image: const DecorationImage(
                            image: AssetImage('assets/images/logo.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'ورود به حسابداری',
                        style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: AppColors.primaryGreen),
                      ),
                      const SizedBox(height: 7),
                      const Text('نوع کاربری خود را انتخاب کنید', style: TextStyle(color: Colors.black54)),
                      const SizedBox(height: 30),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final horizontal = constraints.maxWidth >= 650;
                          final children = [
                            Expanded(
                              child: _RoleCard(
                                icon: Icons.point_of_sale_rounded,
                                title: 'صندوق‌دار',
                                subtitle: 'ورود مستقیم به محیط فروش و ثبت عملیات',
                                color: const Color(0xFF1976D2),
                                onTap: () => _openCashier(context),
                              ),
                            ),
                            const SizedBox(width: 18, height: 18),
                            Expanded(
                              child: _RoleCard(
                                icon: Icons.admin_panel_settings_rounded,
                                title: 'مدیر',
                                subtitle: 'ورود به امکانات مدیریتی با رمز عبور',
                                color: const Color(0xFF00897B),
                                onTap: () => _openManager(context),
                              ),
                            ),
                          ];
                          if (horizontal) return Row(children: children);
                          return Column(children: [children[0], children[1], children[2]]);
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'بوستان فرهنگی مذهبی کریم اهل بیت (ع)',
                        style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatefulWidget {
  const _RoleCard({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: widget.onTap,
          child: Ink(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: widget.color.withOpacity(.07),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: widget.color.withOpacity(.18)),
            ),
            child: Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(color: widget.color, borderRadius: BorderRadius.circular(17)),
                  child: Icon(widget.icon, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 17),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 5),
                      Text(widget.subtitle, style: const TextStyle(fontSize: 12.5, color: Colors.black54, height: 1.5)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: widget.color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
