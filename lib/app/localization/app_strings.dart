import 'package:flutter/widgets.dart';

class AppStrings {
  const AppStrings._(this.isChinese);

  final bool isChinese;

  static AppStrings of(BuildContext context) {
    return AppStrings._(
      Localizations.localeOf(context).languageCode.toLowerCase() == 'zh',
    );
  }

  String text(String zh, String en) => isChinese ? zh : en;

  String get appName => 'Tutuner';
  String get tuner => text('调音器', 'Tuner');
  String get metronome => text('节拍器', 'Metronome');
  String get settings => text('设置', 'Settings');
  String get waiting => text('等待输入', 'Waiting for input');
  String get low => text('偏低', 'Flat');
  String get closeLow => text('接近 · 偏低', 'Close · Flat');
  String get inTune => text('准确', 'In tune');
  String get closeHigh => text('接近 · 偏高', 'Close · Sharp');
  String get high => text('偏高', 'Sharp');
}
