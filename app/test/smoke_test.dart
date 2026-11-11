import 'package:flutter_test/flutter_test.dart';
import 'package:halfsizex/core/settings/app_settings.dart';
import 'package:halfsizex/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('boots to the empty compress state', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = await AppSettings.load();
    await tester.pumpWidget(HalfsizeXApp(settings: settings));
    await tester.pumpAndSettle();
    expect(find.text('halfsizeX'), findsWidgets);
    expect(find.text('Choose video'), findsOneWidget);
  });
}
