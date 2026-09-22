/// تبدیل میلادی به شمسی — عیناً از اپ موبایل صندوق/مدیریت کپی شده تا
/// تاریخ‌ها بین دو اپ کاملاً هم‌خوان باشند.
List<int> gregorianToJalali(int gy, int gm, int gd) {
  const gDaysInMonth = <int>[
    0,
    31,
    59,
    90,
    120,
    151,
    181,
    212,
    243,
    273,
    304,
    334
  ];

  int jy;
  int gy2;
  if (gy > 1600) {
    jy = 979;
    gy2 = gy - 1600;
  } else {
    jy = 0;
    gy2 = gy - 621;
  }

  var days = 365 * gy2 +
      ((gy2 + 3) ~/ 4) -
      ((gy2 + 99) ~/ 100) +
      ((gy2 + 399) ~/ 400) -
      80 +
      gd +
      gDaysInMonth[gm - 1];

  final isLeapGregorian = (gy % 4 == 0 && gy % 100 != 0) || (gy % 400 == 0);
  if (gm > 2 && isLeapGregorian) days++;

  jy += 33 * (days ~/ 12053);
  days %= 12053;

  jy += 4 * (days ~/ 1461);
  days %= 1461;

  if (days > 365) {
    jy += (days - 1) ~/ 365;
    days = (days - 1) % 365;
  }

  final jm = days < 186 ? 1 + (days ~/ 31) : 7 + ((days - 186) ~/ 30);
  final jd = 1 + (days < 186 ? days % 31 : (days - 186) % 30);

  return [jy, jm, jd];
}

String toPersianDigits(String value) {
  const latin = '0123456789';
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  var result = value;
  for (var i = 0; i < latin.length; i++) {
    result = result.replaceAll(latin[i], persian[i]);
  }
  return result;
}

String todayJalali() {
  final now = DateTime.now();
  final j = gregorianToJalali(now.year, now.month, now.day);
  final jy = j[0], jm = j[1], jd = j[2];
  return '$jy/${jm.toString().padLeft(2, '0')}/${jd.toString().padLeft(2, '0')}';
}

/// مقایسه دو تاریخ شمسی به فرمت yyyy/mm/dd برای مرتب‌سازی (رشته‌ای قابل مقایسه است چون هر بخش پد شده).
int compareJalaliDates(String a, String b) {
  String norm(String s) {
    final parts = s.split('/');
    if (parts.length != 3) return s;
    return '${parts[0].padLeft(4, '0')}/${parts[1].padLeft(2, '0')}/${parts[2].padLeft(2, '0')}';
  }

  return norm(a).compareTo(norm(b));
}
