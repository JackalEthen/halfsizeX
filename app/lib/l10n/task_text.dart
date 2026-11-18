import 'package:flutter/widgets.dart';

class TaskText {
  const TaskText._();

  static bool isZh(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'zh';

  static String t(BuildContext context, String zh, String en) =>
      isZh(context) ? zh : en;
}
